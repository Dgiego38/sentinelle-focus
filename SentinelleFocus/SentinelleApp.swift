// SentinelleApp.swift
// SENTINELLE FOCUS — Point d'entrée + Setup des permissions

import SwiftUI
import FamilyControls

@main
struct SentinelleApp: App {

    @StateObject private var focusManager = FocusManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(focusManager)
                .preferredColorScheme(.dark)
                .task {
                    // Demande l'autorisation FamilyControls au premier lancement
                    if focusManager.authorizationStatus == .notDetermined {
                        await focusManager.requestAuthorization()
                    }
                }
        }
    }
}

// MARK: - ContentView (Router)
struct ContentView: View {
    @EnvironmentObject var focusManager: FocusManager

    var body: some View {
        Group {
            if focusManager.currentSession != nil {
                SessionView()
            } else {
                DashboardView()
            }
        }
        .background(Color.black)
    }
}
