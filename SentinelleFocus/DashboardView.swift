// DashboardView.swift
// SENTINELLE FOCUS — Interface principale (fond noir absolu OLED)

import SwiftUI
import FamilyControls
import DeviceActivity

struct DashboardView: View {

    @EnvironmentObject var focusManager: FocusManager
    @State private var showUltraAlert = false
    @State private var showConfigSheet = false
    @State private var zenDuration: Int = 25
    @State private var ultraDuration: Int = 90

    // MARK: Body
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // Header
                    headerSection
                        .padding(.top, 20)
                        .padding(.bottom, 32)

                    // Screen time stat
                    screenTimeCard
                        .padding(.bottom, 12)

                    // Blocked apps stat
                    blockedAppsCard
                        .padding(.bottom, 28)

                    // Divider
                    Rectangle()
                        .fill(Color(white: 0.1))
                        .frame(height: 0.5)
                        .padding(.bottom, 20)

                    // Mode Zen Button
                    OutlineButton(
                        label: "Mode ZEN",
                        sublabel: "Blocage partiel · \(zenDuration) min · Arrêtable",
                        style: .gray
                    ) {
                        focusManager.startZenSession(durationMinutes: zenDuration)
                    }
                    .padding(.bottom, 12)

                    // Ultra Focus Button
                    OutlineButton(
                        label: "ULTRA FOCUS",
                        sublabel: "Verrouillage strict · \(ultraDuration) min",
                        style: .white
                    ) {
                        showUltraAlert = true
                    }
                    .padding(.bottom, 32)

                    // Authorization warning
                    if !focusManager.isAuthorized {
                        authWarningBanner
                            .padding(.bottom, 20)
                    }

                    // Config link
                    Button {
                        showConfigSheet = true
                    } label: {
                        HStack {
                            Text("Configuration")
                                .font(.system(size: 12, weight: .light))
                                .tracking(2)
                                .textCase(.uppercase)
                            Spacer()
                            Text("›")
                                .font(.system(size: 12, weight: .light))
                        }
                        .foregroundColor(Color(white: 0.25))
                        .padding(.vertical, 14)
                        .overlay(
                            Rectangle()
                                .fill(Color(white: 0.12))
                                .frame(height: 0.5),
                            alignment: .top
                        )
                        .overlay(
                            Rectangle()
                                .fill(Color(white: 0.12))
                                .frame(height: 0.5),
                            alignment: .bottom
                        )
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        // ULTRA FOCUS Alert
        .alert("Verrouillage Strict", isPresented: $showUltraAlert) {
            Button("Confirmer — Lancer", role: .destructive) {
                focusManager.startUltraFocusSession(durationMinutes: ultraDuration)
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Attention : Impossible d'arrêter avant la fin. Les applications sélectionnées seront bloquées pendant \(ultraDuration) minutes. Es-tu prêt ?")
        }
        // Config Sheet
        .sheet(isPresented: $showConfigSheet) {
            ConfigurationView()
                .environmentObject(focusManager)
        }
    }

    // MARK: Subviews

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

    private var screenTimeCard: some View {
        StatCard(
            label: "Temps écran — aujourd'hui",
            value: formattedScreenTime,
            sub: screenTimeSub
        )
    }

    private var blockedAppsCard: some View {
        StatCard(
            label: "Apps sélectionnées",
            value: "\(focusManager.activitySelection.applicationTokens.count) app(s)",
            sub: focusManager.isAutoShieldActive ? "AUTO-SHIELD ACTIF" : "Inactif"
        )
    }

    private var authWarningBanner: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(Color(white: 0.3))
                .frame(width: 1)
            VStack(alignment: .leading, spacing: 3) {
                Text("Autorisation requise")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Color(white: 0.6))
                Button("Autoriser FamilyControls") {
                    Task { await focusManager.requestAuthorization() }
                }
                .font(.system(size: 11, weight: .light))
                .tracking(1)
                .foregroundColor(Color(white: 0.55))
            }
        }
        .padding(.vertical, 10)
    }

    // MARK: Helpers
    private var formattedScreenTime: String {
        let total = focusManager.totalScreenTimeToday
        let h = Int(total) / 3600
        let m = (Int(total) % 3600) / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }

    private var screenTimeSub: String {
        guard let goalSec = UserDefaults(suiteName: FocusManager.appGroupID)?
            .value(forKey: FocusManager.goalKey) as? Int else {
            return "Aucun objectif défini"
        }
        let remaining = max(0, goalSec - Int(focusManager.totalScreenTimeToday))
        let rm = remaining / 60
        let goalH = goalSec / 3600
        let goalM = (goalSec % 3600) / 60
        return "Objectif : \(goalH)h \(goalM)m · Reste : \(rm) min"
    }
}

// MARK: - Reusable Components

struct StatCard: View {
    let label: String
    let value: String
    let sub: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .light))
                .tracking(2)
                .textCase(.uppercase)
                .foregroundColor(Color(white: 0.27))
            Text(value)
                .font(.system(size: 34, weight: .ultraLight))
                .foregroundColor(Color(white: 0.78))
                .monospacedDigit()
            Text(sub)
                .font(.system(size: 10, weight: .light))
                .foregroundColor(Color(white: 0.22))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(white: 0.13), lineWidth: 0.5)
        )
    }
}

enum OutlineStyle { case gray, white }

struct OutlineButton: View {
    let label: String
    let sublabel: String
    let style: OutlineStyle
    let action: () -> Void

    private var borderColor: Color {
        style == .white ? Color(white: 0.91) : Color(white: 0.27)
    }
    private var textColor: Color {
        style == .white ? Color(white: 0.91) : Color(white: 0.55)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(label)
                    .font(.system(size: 13, weight: .light))
                    .tracking(2.5)
                    .textCase(.uppercase)
                    .foregroundColor(textColor)
                Text(sublabel)
                    .font(.system(size: 10, weight: .light))
                    .foregroundColor(Color(white: 0.28))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(borderColor, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}
