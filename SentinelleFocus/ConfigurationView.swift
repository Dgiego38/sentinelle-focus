import SwiftUI
import FamilyControls

struct ConfigurationView: View {
    @EnvironmentObject var focusManager: FocusManager
    @Environment(\.dismiss) var dismiss

    @State private var showPicker = false
    @State private var dailyGoalHours: Double = 4.0
    @State private var zenDuration: Double = 25
    @State private var ultraDuration: Double = 90
    @State private var autoShieldEnabled: Bool = true
    @State private var selection: FamilyActivitySelection = .init()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sentinelle Focus")
                                .font(.system(size: 11, weight: .light))
                                .tracking(3)
                                .textCase(.uppercase)
                                .foregroundColor(Color(white: 0.25))
                            Text("Configuration")
                                .font(.system(size: 28, weight: .ultraLight))
                                .foregroundColor(Color(white: 0.91))
                        }
                        Spacer()
                        Button("Fermer") { dismiss() }
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(Color(white: 0.4))
                    }
                    .padding(.bottom, 32)

                    // SECTION 1: Application Picker
                    sectionLabel("Applications à bloquer")

                    Button {
                        showPicker = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Sélectionner les apps")
                                    .font(.system(size: 13, weight: .light))
                                    .foregroundColor(Color(white: 0.7))
                                Text("\(selection.applicationTokens.count) app(s) sélectionnée(s)")
                                    .font(.system(size: 10, weight: .light))
                                    .foregroundColor(Color(white: 0.3))
                            }
                            Spacer()
                            Text("›").foregroundColor(Color(white: 0.3))
                        }
                        .padding(14)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(white: 0.15), lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                    .familyActivityPicker(isPresented: $showPicker, selection: $selection)
                    .onChange(of: selection) { oldValue, newValue in
                        focusManager.saveSelection(newValue)
                    }
                    .padding(.bottom, 28)

                    // SECTION 2: Durées
                    sectionLabel("Durées des sessions")
                    SliderRow(label: "Mode ZEN", value: $zenDuration, range: 10...60, unit: "min")
                    SliderRow(label: "Ultra Focus", value: $ultraDuration, range: 30...180, unit: "min")
                    .padding(.bottom, 28)

                    // SECTION 3: Objectif
                    sectionLabel("Objectif journalier")
                    SliderRow(label: "Temps total", value: $dailyGoalHours, range: 1...12, unit: "h")
                    .padding(.bottom, 36)

                    // Save Button
                    Button {
                        saveSettings()
                        dismiss()
                    } label: {
                        Text("SAUVEGARDER")
                            .font(.system(size: 12, weight: .light))
                            .tracking(3)
                            .foregroundColor(Color(white: 0.88))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(white: 0.88), lineWidth: 0.5))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }
        }
        .onAppear {
            loadSettings()
            selection = focusManager.activitySelection
        }
    }

    // MARK: - Helper Views & Functions
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .light))
            .tracking(2.5)
            .textCase(.uppercase)
            .foregroundColor(Color(white: 0.25))
            .padding(.bottom, 12)
    }

    private func saveSettings() {
        let defaults = UserDefaults(suiteName: FocusManager.appGroupID)
        defaults?.set(Int(dailyGoalHours * 3600), forKey: FocusManager.goalKey)
        defaults?.set(Int(zenDuration), forKey: "zenDurationMinutes")
        defaults?.set(Int(ultraDuration), forKey: "ultraDurationMinutes")
    }

    private func loadSettings() {
        let defaults = UserDefaults(suiteName: FocusManager.appGroupID)
        if let goal = defaults?.value(forKey: FocusManager.goalKey) as? Int {
            dailyGoalHours = Double(goal) / 3600
        }
        if let zen = defaults?.value(forKey: "zenDurationMinutes") as? Int {
            zenDuration = Double(zen)
        }
        if let ultra = defaults?.value(forKey: "ultraDurationMinutes") as? Int {
            ultraDuration = Double(ultra)
        }
    }
}

struct SliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String

    var body: some View {
        HStack {
            Text(label).font(.system(size: 12, weight: .light)).foregroundColor(Color(white: 0.55)).frame(width: 90, alignment: .leading)
            Slider(value: $value, in: range, step: 1).tint(Color(white: 0.4))
            Text("\(Int(value))\(unit)").font(.system(size: 12, weight: .light)).monospacedDigit().foregroundColor(Color(white: 0.6)).frame(width: 45, alignment: .trailing)
        }
        .padding(.vertical, 8)
    }
}