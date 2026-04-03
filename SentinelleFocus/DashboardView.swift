import SwiftUI
import FamilyControls
import DeviceActivity

struct DashboardView: View {
    @EnvironmentObject var focusManager: FocusManager
    @State private var showUltraAlert = false
    @State private var showConfigSheet = false
    @State private var zenDuration: Int = 25
    @State private var ultraDuration: Int = 90

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    headerSection
                        .padding(.top, 20)
                        .padding(.bottom, 32)

                    // Card Stats (Simplifiées pour le build)
                    StatCard(
                        label: "Apps sélectionnées",
                        value: "\(focusManager.activitySelection.applicationTokens.count) app(s)",
                        sub: "Configuration active"
                    )
                    .padding(.bottom, 28)

                    Rectangle()
                        .fill(Color(white: 0.1))
                        .frame(height: 0.5)
                        .padding(.bottom, 20)

                    // Mode Zen
                    OutlineButton(
                        label: "Mode ZEN",
                        sublabel: "Blocage partiel · \(zenDuration) min · Arrêtable",
                        style: .gray
                    ) {
                        focusManager.startSession(mode: .zen, minutes: zenDuration)
                    }
                    .padding(.bottom, 12)

                    // Ultra Focus
                    OutlineButton(
                        label: "ULTRA FOCUS",
                        sublabel: "Verrouillage strict · \(ultraDuration) min",
                        style: .white
                    ) {
                        showUltraAlert = true
                    }
                    .padding(.bottom, 32)

                    // Auth Warning
                    if focusManager.authorizationStatus != .approved {
                        authWarningBanner
                            .padding(.bottom, 20)
                    }

                    // Config link
                    configLink
                }
                .padding(.horizontal, 24)
            }
        }
        .alert("Verrouillage Strict", isPresented: $showUltraAlert) {
            Button("Confirmer — Lancer", role: .destructive) {
                focusManager.startSession(mode: .ultraFocus, minutes: ultraDuration)
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Attention : Impossible d'arrêter avant la fin. Es-tu prêt ?")
        }
        .sheet(isPresented: $showConfigSheet) {
            ConfigurationView()
                .environmentObject(focusManager)
        }
    }

    // MARK: - Subviews
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Sentinelle Focus")
                .font(.system(size: 11, weight: .light))
                .tracking(3)
                .textCase(.uppercase)
                .foregroundColor(Color(white: 0.27))
            Text("Dashboard")
                .font(.system(size: 28, weight: .ultraLight))
                .foregroundColor(Color(white: 0.91))
                .tracking(-0.5)
        }
    }

    private var authWarningBanner: some View {
        HStack(spacing: 8) {
            Rectangle().fill(Color(white: 0.3)).frame(width: 1)
            VStack(alignment: .leading, spacing: 3) {
                Text("Autorisation requise")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Color(white: 0.6))
                Button("Autoriser FamilyControls") {
                    Task { await focusManager.requestAuthorization() }
                }
                .font(.system(size: 11, weight: .light))
                .foregroundColor(Color(white: 0.55))
            }
        }
        .padding(.vertical, 10)
    }

    private var configLink: some View {
        Button { showConfigSheet = true } label: {
            HStack {
                Text("Configuration")
                    .font(.system(size: 12, weight: .light))
                    .tracking(2)
                    .textCase(.uppercase)
                Spacer()
                Text("›")
            }
            .foregroundColor(Color(white: 0.25))
            .padding(.vertical, 14)
            .overlay(Rectangle().fill(Color(white: 0.12)).frame(height: 0.5), alignment: .top)
            .overlay(Rectangle().fill(Color(white: 0.12)).frame(height: 0.5), alignment: .bottom)
        }
    }
}

// MARK: - Reusable Components (StatCard & OutlineButton restent identiques)