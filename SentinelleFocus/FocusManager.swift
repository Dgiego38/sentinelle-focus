import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity
import Combine
import SwiftUI

// --- MODULE DE DONNÉES (Visible par tout le projet) ---

public enum FocusMode: String, Codable {
    case zen         // Blocage souple
    case ultraFocus  // Verrouillage strict
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
    
    // État de l'interface
    @Published public var authorizationStatus: AuthorizationStatus = .notDetermined
    @Published public var activitySelection: FamilyActivitySelection = .init()
    @Published public var currentSession: FocusSession?
    
    // Configuration
    private let store = ManagedSettingsStore()
    private let center = AuthorizationCenter.shared
    private let deviceActivityCenter = DeviceActivityCenter()
    
    // Identifiants uniques (Doivent correspondre à ton project.yml)
    static let appGroupID = "group.com.dgiego38.sentinellefocus"
    static let activityName = DeviceActivityName("sentinelle.focus.session")
    static let selectionKey = "familyActivitySelection"
    static let sessionKey   = "currentFocusSession"

    public init() {
        loadData()
        refreshAuthorizationStatus()
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

    // MARK: - Gestion des Shields (Boucliers)
    public func activateShields() {
        let applications = activitySelection.applicationTokens
        let categories = activitySelection.categoryTokens
        
        if applications.isEmpty && categories.isEmpty {
            store.shield.applications = nil
            store.shield.applicationCategories = nil
        } else {
            store.shield.applications = applications
            store.shield.applicationCategories = .specific(categories)
        }
    }

    public func deactivateShields() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
    }

    // MARK: - Sessions de Focus
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
        // Sécurité : Impossible d'arrêter l'Ultra Focus avant la fin
        if let session = currentSession, session.mode == .ultraFocus && session.secondsRemaining > 0 {
            print("Ultra Focus actif : Arrêt impossible.")
            return
        }
        
        deactivateShields()
        deviceActivityCenter.stopMonitoring([Self.activityName])
        currentSession = nil
        UserDefaults(suiteName: Self.appGroupID)?.removeObject(forKey: Self.sessionKey)
    }

    // MARK: - Device Activity (La partie qui posait erreur)
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
            threshold: DateComponents(minute: 1) // Seuil minimal pour activer le monitoring
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
    private func saveData(session: FocusSession) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(session) {
            UserDefaults(suiteName: Self.appGroupID)?.set(data, forKey: Self.sessionKey)
        }
        if let selectionData = try? encoder.encode(activitySelection) {
            UserDefaults(suiteName: Self.appGroupID)?.set(selectionData, forKey: Self.selectionKey)
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