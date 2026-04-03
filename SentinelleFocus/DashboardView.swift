import SwiftUI
import FamilyControls

struct DashboardView: View {
    @EnvironmentObject var focusManager: FocusManager
    @State private var showConfig = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 8) {
                    Text("SENTINELLE")
                        .font(.system(size: 12, weight: .light))
                        .tracking(8)
                        .foregroundColor(Color(white: 0.4))
                    
                    Text(focusManager.currentSession != nil ? "FOCUS ACTIF" : "SYSTÈME PRÊT")
                        .font(.system(size: 32, weight: .ultraLight))
                        .foregroundColor(.white)
                }
                .padding(.top, 40)
                
                // Stats Row
                HStack(spacing: 20) {
                    StatCard(
                        label: "AUJOURD'HUI",
                        value: formatTime(focusManager.totalScreenTimeToday)
                    )
                    StatCard(
                        label: "OBJECTIF",
                        value: "4h00"
                    )
                }
                .padding(.horizontal, 25)
                
                Spacer()
                
                // Actions
                VStack(spacing: 16) {
                    if focusManager.currentSession == nil {
                        OutlineButton(title: "DÉMARRER ZEN", icon: "leaf") {
                            focusManager.startSession(mode: .zen, minutes: 25)
                        }
                        
                        OutlineButton(title: "ULTRA FOCUS", icon: "lock.shield", color: .white) {
                            focusManager.startSession(mode: .ultraFocus, minutes: 90)
                        }
                    } else {
                        OutlineButton(title: "ARRÊTER", icon: "xmark.circle") {
                            focusManager.stopSession()
                        }
                    }
                    
                    Button("Configuration") {
                        showConfig = true
                    }
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(Color(white: 0.3))
                    .padding(.top, 10)
                }
                .padding(.bottom, 50)
            }
        }
        .sheet(isPresented: $showConfig) {
            ConfigurationView()
                .environmentObject(focusManager)
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        return String(format: "%dh%02d", h, m)
    }
}

// MARK: - Composants Manquants (Les briques qui manquaient au build)

struct StatCard: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .light))
                .tracking(2)
                .foregroundColor(Color(white: 0.3))
            
            Text(value)
                .font(.system(size: 22, weight: .ultraLight))
                .foregroundColor(Color(white: 0.9))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(white: 0.1), lineWidth: 1)
        )
    }
}

struct OutlineButton: View {
    let title: String
    let icon: String
    var color: Color = Color(white: 0.6)
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 12, weight: .light))
                    .tracking(2)
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 0.5)
            )
        }
        .padding(.horizontal, 25)
    }
}