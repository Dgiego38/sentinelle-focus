// SessionView.swift
// SENTINELLE FOCUS — Écran session active (Chrono MM:SS centré, fond noir)

import SwiftUI

struct SessionView: View {
    @EnvironmentObject var focusManager: FocusManager
    @State private var showStopConfirm = false

    // Refresh every second via TimelineView
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { _ in
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {

                    // Top label
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sentinelle Focus")
                            .font(.system(size: 11, weight: .light))
                            .tracking(3)
                            .textCase(.uppercase)
                            .foregroundColor(Color(white: 0.2))

                        Text(modeTitle)
                            .font(.system(size: 28, weight: .ultraLight))
                            .foregroundColor(Color(white: 0.88))
                            .tracking(-0.5)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    Spacer()

                    // Chrono centré
                    VStack(spacing: 12) {
                        Text("TEMPS RESTANT")
                            .font(.system(size: 10, weight: .light))
                            .tracking(3)
                            .foregroundColor(Color(white: 0.22))

                        Text(chronoString)
                            .font(.system(size: 80, weight: .ultraLight))
                            .monospacedDigit()
                            .foregroundColor(Color(white: 0.54))
                            .tracking(-4)

                        Text(modeSubtitle)
                            .font(.system(size: 10, weight: .light))
                            .tracking(2)
                            .textCase(.uppercase)
                            .foregroundColor(Color(white: 0.18))
                    }

                    Spacer()

                    // Stop button — CACHÉ en mode Ultra Focus
                    if isZenMode {
                        Button {
                            showStopConfirm = true
                        } label: {
                            Text("TERMINER LA SESSION")
                                .font(.system(size: 12, weight: .light))
                                .tracking(2)
                                .foregroundColor(Color(white: 0.35))
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(white: 0.2), lineWidth: 0.5)
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 48)
                    } else {
                        // Ultra Focus — message de verrouillage
                        Text("Verrouillage actif — Impossible d'arrêter")
                            .font(.system(size: 10, weight: .light))
                            .tracking(1.5)
                            .foregroundColor(Color(white: 0.15))
                            .padding(.bottom, 56)
                    }
                }
            }
        }
        .confirmationDialog("Terminer la session ?", isPresented: $showStopConfirm) {
            Button("Terminer", role: .destructive) {
                focusManager.stopSession()
            }
            Button("Continuer", role: .cancel) {}
        } message: {
            Text("Les boucliers seront désactivés.")
        }
    }

    // MARK: - Computed Properties

    private var isZenMode: Bool {
        focusManager.currentSession?.mode == .zen
    }

    private var modeTitle: String {
        switch focusManager.currentSession?.mode {
        case .zen: return "Mode ZEN"
        case .ultraFocus: return "ULTRA FOCUS"
        case nil: return "Session"
        }
    }

    private var modeSubtitle: String {
        switch focusManager.currentSession?.mode {
        case .zen: return "Blocage partiel actif"
        case .ultraFocus: return "Verrouillage strict · Apps bloquées"
        case nil: return ""
        }
    }

    private var chronoString: String {
        guard let session = focusManager.currentSession else { return "00:00" }
        let remaining = session.secondsRemaining
        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
