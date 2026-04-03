// SentinelleApp.swift
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
                    // Correction : On appelle la fonction de demande d'autorisation
                    if focusManager.authorizationStatus == .notDetermined {
                        await focusManager.requestAuthorization()
                    }
                }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var focusManager: FocusManager

    var body: some View {
        Group {
            // Si une session est active, on affiche l'écran noir de focus
            if focusManager.currentSession != nil {
                SessionView()
            } else {
                DashboardView()
            }
        }
        .background(Color.black)
    }
}