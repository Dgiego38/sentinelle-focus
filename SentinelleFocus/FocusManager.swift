import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity
import Combine
import SwiftUI

// --- MODULE DE DONNÉES ---

public enum FocusMode: String, Codable {
    case zen
    case ultraFocus
}

public struct FocusSession: Codable {
    public var mode: FocusMode
    public var startDate: Date
    public var durationSeconds: Int
    public var isActive: Bool

    public var endDate: Date {
        startDate.addingTimeInterval(TimeInterval(durationSeconds))
    }

    public var secondsRemaining: Int {
        max(0, Int(endDate.timeIntervalSinceNow))
    }
}

// --- MOTEUR DE GESTION ---

@MainActor
public final class FocusManager: ObservableObject {
    
    @Published public var authorizationStatus: AuthorizationStatus = .notDetermined
    @Published public var activitySelection: FamilyActivitySelection = .init()
    @Published public var currentSession: FocusSession?
    
    // Variables pour le Dashboard (Stats fictives pour le build)
    @Published public var totalScreenTimeToday: TimeInterval = 0
    @Published public var isAutoShieldActive: Bool = false
    
    private let store = ManagedSettingsStore()
    private let center = AuthorizationCenter.shared
    private let deviceActivityCenter = DeviceActivityCenter()
    
    static let appGroupID = "group.com.dgiego38.sentinellefocus"
    static let goalKey = "sentinelle_goal_seconds"
    static let activityName = DeviceActivityName("sentinelle.focus.session")
    static let selectionKey = "familyActivitySelection"
    static let sessionKey   = "currentFocusSession"

    public init() {
        loadData()
        refreshAuthorizationStatus()
    }

    // Propriété utile pour les vues
    public var isAuthorized: Bool {
        authorizationStatus == .approved
    }

    // MARK: - Autorisations
    public func requestAuthorization() async {
        do {
            try await center.requestAuthorization(for: .individual)
            refreshAuthorizationStatus()
        } catch {
            print("Erreur d'autorisation : \(error.localizedDescription)")
        }
    }

    private func refreshAuthorizationStatus() {
        authorizationStatus = center.authorizationStatus
    }

    // MARK: - Sauvegarde de la sélection (Appelé par ConfigurationView)
    public func saveSelection(_ selection: FamilyActivitySelection) {
        self.activitySelection = selection
        saveData()
    }

    // MARK: - Gestion des Shields
    public func activateShields() {
        let applications = activitySelection.applicationTokens
        let categories = activitySelection.categoryTokens
        
        if applications.isEmpty && categories.isEmpty {
            deactivateShields()
        } else {
            store.shield.applications = applications
            store.shield.applicationCategories = .specific(categories)
        }
    }

    public func deactivateShields() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
    }

    // MARK: - Sessions
    public func startSession(mode: FocusMode, minutes: Int) {
        let session = FocusSession(
            mode: mode,
            startDate: Date(),
            durationSeconds: minutes * 60,
            isActive: true
        )
        
        self.currentSession = session
        saveData(session: session)
        activateShields()
        scheduleMonitoring(for: session)
    }

    public func stopSession() {
        if let session = currentSession, session.mode == .ultraFocus && session.secondsRemaining > 0 {
            return
        }
        
        deactivateShields()
        deviceActivityCenter.stopMonitoring([Self.activityName])
        currentSession = nil
        UserDefaults(suiteName: Self.appGroupID)?.removeObject(forKey: Self.sessionKey)
    }

    // MARK: - Device Activity
    private func scheduleMonitoring(for session: FocusSession) {
        let eventName = DeviceActivityEvent.Name("sentinelle.threshold.event")
        
        let schedule = DeviceActivitySchedule(
            intervalStart: Calendar.current.dateComponents([.hour, .minute], from: session.startDate),
            intervalEnd: Calendar.current.dateComponents([.hour, .minute], from: session.endDate),
            repeats: false
        )
        
        let event = DeviceActivityEvent(
            applications: activitySelection.applicationTokens,
            categories: activitySelection.categoryTokens,
            threshold: DateComponents(minute: 1)
        )
        
        do {
            try deviceActivityCenter.startMonitoring(
                Self.activityName,
                during: schedule,
                events: [eventName: event]
            )
        } catch {
            print("Erreur Monitoring : \(error)")
        }
    }

    // MARK: - Persistance
    private func saveData(session: FocusSession? = nil) {
        let encoder = JSONEncoder()
        let defaults = UserDefaults(suiteName: Self.appGroupID)
        
        if let session = session ?? currentSession,
           let data = try? encoder.encode(session) {
            defaults?.set(data, forKey: Self.sessionKey)
        }
        
        if let selectionData = try? encoder.encode(activitySelection) {
            defaults?.set(selectionData, forKey: Self.selectionKey)
        }
    }

    private func loadData() {
        let decoder = JSONDecoder()
        let defaults = UserDefaults(suiteName: Self.appGroupID)
        
        if let sessionData = defaults?.data(forKey: Self.sessionKey),
           let session = try? decoder.decode(FocusSession.self, from: sessionData) {
            if session.secondsRemaining > 0 {
                self.currentSession = session
            }
        }
        
        if let selectionData = defaults?.data(forKey: Self.selectionKey),
           let selection = try? decoder.decode(FamilyActivitySelection.self, from: selectionData) {
            self.activitySelection = selection
        }
    }
}