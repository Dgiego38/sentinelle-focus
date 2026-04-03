// FocusManager.swift
// SENTINELLE FOCUS — Moteur principal
// Gestion des permissions FamilyControls + activation/désactivation des Shields

import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity
import Combine
import SwiftUI

// MARK: - Session Mode
enum FocusMode: String, Codable {
    case zen        // Blocage partiel, arrêt possible
    case ultraFocus // Verrouillage strict, impossible d'arrêter
}

// MARK: - Session State
struct FocusSession: Codable {
    var mode: FocusMode
    var startDate: Date
    var durationSeconds: Int
    var isActive: Bool

    var endDate: Date {
        startDate.addingTimeInterval(TimeInterval(durationSeconds))
    }

    var secondsRemaining: Int {
        max(0, Int(endDate.timeIntervalSinceNow))
    }
}

// MARK: - FocusManager
@MainActor
final class FocusManager: ObservableObject {

    // MARK: Published State
    @Published var authorizationStatus: AuthorizationStatus = .notDetermined
    @Published var activitySelection: FamilyActivitySelection = .init()
    @Published var currentSession: FocusSession?
    @Published var totalScreenTimeToday: TimeInterval = 0
    @Published var isAutoShieldActive: Bool = false

    // MARK: Constants
    static let appGroupID = "group.com.yourcompany.sentinellefocus"
    static let selectionKey = "familyActivitySelection"
    static let sessionKey   = "currentFocusSession"
    static let goalKey      = "dailyScreenTimeGoalSeconds"

    // MARK: Private
    private let store = ManagedSettingsStore()
    private let center = AuthorizationCenter.shared
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?

    // MARK: Init
    init() {
        loadSelectionFromDefaults()
        loadSessionFromDefaults()
        observeAuthorizationStatus()
        startSessionTickIfNeeded()
    }

    // MARK: - Authorization
    func requestAuthorization() async {
        do {
            try await center.requestAuthorization(for: .individual)
            authorizationStatus = center.authorizationStatus
        } catch {
            print("[FocusManager] Authorization error: \(error.localizedDescription)")
        }
    }

    private func observeAuthorizationStatus() {
        authorizationStatus = center.authorizationStatus
    }

    var isAuthorized: Bool {
        authorizationStatus == .approved
    }

    // MARK: - Shield Activation
    /// Active le blocage des apps sélectionnées
    func activateShields() {
        guard isAuthorized else { return }
        store.shield.applications = activitySelection.applicationTokens.isEmpty ? nil : activitySelection.applicationTokens
        store.shield.applicationCategories = activitySelection.categoryTokens.isEmpty ? nil
            : ShieldSettings.ActivityCategoryPolicy.specific(activitySelection.categoryTokens)
    }

    /// Désactive tous les boucliers
    func deactivateShields() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
    }

    // MARK: - Session Management

    /// Démarre une session ZEN (25 min par défaut, arrêtable)
    func startZenSession(durationMinutes: Int = 25) {
        let session = FocusSession(
            mode: .zen,
            startDate: Date(),
            durationSeconds: durationMinutes * 60,
            isActive: true
        )
        currentSession = session
        saveSessionToDefaults(session)
        activateShields()
        scheduleDeviceActivityMonitoring(session: session)
        startSessionTickIfNeeded()
    }

    /// Démarre une session Ultra Focus (90 min, VERROUILLÉE)
    func startUltraFocusSession(durationMinutes: Int = 90) {
        let session = FocusSession(
            mode: .ultraFocus,
            startDate: Date(),
            durationSeconds: durationMinutes * 60,
            isActive: true
        )
        currentSession = session
        saveSessionToDefaults(session)
        activateShields()
        scheduleDeviceActivityMonitoring(session: session)
        startSessionTickIfNeeded()
    }

    /// Arrête la session (uniquement disponible en mode ZEN)
    @discardableResult
    func stopSession() -> Bool {
        guard let session = currentSession else { return false }
        guard session.mode == .zen else {
            print("[FocusManager] Impossible d'arrêter une session Ultra Focus.")
            return false
        }
        endSession()
        return true
    }

    /// Termine la session (appelé automatiquement à la fin du timer)
    func endSession() {
        deactivateShields()
        stopDeviceActivityMonitoring()
        currentSession = nil
        clearSessionFromDefaults()
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Auto-Shield
    /// Active le bouclier automatiquement si l'objectif journalier est dépassé
    func checkAndApplyAutoShield() {
        guard let goalSeconds = UserDefaults(suiteName: Self.appGroupID)?
            .value(forKey: Self.goalKey) as? Int else { return }
        if totalScreenTimeToday >= TimeInterval(goalSeconds) && currentSession == nil {
            activateShields()
            isAutoShieldActive = true
        } else if isAutoShieldActive && totalScreenTimeToday < TimeInterval(goalSeconds) {
            deactivateShields()
            isAutoShieldActive = false
        }
    }

    // MARK: - DeviceActivity Monitoring
    private func scheduleDeviceActivityMonitoring(session: FocusSession) {
        let deviceActivityCenter = DeviceActivityCenter()
        let activityName = DeviceActivityName("sentinelle.focus.session")
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: Calendar.current.component(.hour, from: session.startDate),
                                         minute: Calendar.current.component(.minute, from: session.startDate)),
            intervalEnd: DateComponents(hour: Calendar.current.component(.hour, from: session.endDate),
                                        minute: Calendar.current.component(.minute, from: session.endDate)),
            repeats: false
        )
        do {
            try deviceActivityCenter.startMonitoring(activityName, during: schedule, events: [
                .activityInterval: DeviceActivityEvent(
                    applications: activitySelection.applicationTokens,
                    categories: activitySelection.categoryTokens,
                    threshold: DateComponents(minute: 1)
                )
            ])
        } catch {
            print("[FocusManager] DeviceActivity error: \(error)")
        }
    }

    private func stopDeviceActivityMonitoring() {
        DeviceActivityCenter().stopMonitoring([DeviceActivityName("sentinelle.focus.session")])
    }

    // MARK: - Session Tick
    private func startSessionTickIfNeeded() {
        guard timer == nil, currentSession != nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let session = self.currentSession, session.secondsRemaining <= 0 {
                    self.endSession()
                }
                self.objectWillChange.send()
            }
        }
    }

    // MARK: - Persistence
    func saveSelection(_ selection: FamilyActivitySelection) {
        activitySelection = selection
        let defaults = UserDefaults(suiteName: Self.appGroupID)
        if let data = try? JSONEncoder().encode(selection) {
            defaults?.set(data, forKey: Self.selectionKey)
        }
    }

    private func loadSelectionFromDefaults() {
        let defaults = UserDefaults(suiteName: Self.appGroupID)
        guard let data = defaults?.data(forKey: Self.selectionKey),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        else { return }
        activitySelection = selection
    }

    private func saveSessionToDefaults(_ session: FocusSession) {
        let defaults = UserDefaults(suiteName: Self.appGroupID)
        if let data = try? JSONEncoder().encode(session) {
            defaults?.set(data, forKey: Self.sessionKey)
        }
    }

    private func loadSessionFromDefaults() {
        let defaults = UserDefaults(suiteName: Self.appGroupID)
        guard let data = defaults?.data(forKey: Self.sessionKey),
              let session = try? JSONDecoder().decode(FocusSession.self, from: data),
              session.isActive, session.secondsRemaining > 0
        else { return }
        currentSession = session
    }

    private func clearSessionFromDefaults() {
        UserDefaults(suiteName: Self.appGroupID)?.removeObject(forKey: Self.sessionKey)
    }
}
