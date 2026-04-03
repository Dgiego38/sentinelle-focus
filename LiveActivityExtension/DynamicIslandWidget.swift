// DynamicIslandWidget.swift
// SENTINELLE FOCUS — Dynamic Island + Lock Screen (ActivityKit)
// Target séparée : "SentinelleLiveActivity"

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Attributes (shared between app and widget)
struct SentinelleActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var secondsRemaining: Int
        var mode: String        // "ZEN" | "ULTRA FOCUS"
        var isUltraFocus: Bool
    }
    var sessionStartDate: Date
}

// MARK: - Widget Definition
@available(iOS 16.2, *)
struct SentinelleWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SentinelleActivityAttributes.self) { context in
            // Lock Screen / Banner
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(context.state.mode)
                            .font(.system(size: 11, weight: .light))
                            .tracking(1.5)
                            .foregroundColor(Color(white: 0.6))
                    } icon: {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color(white: 0.4))
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(chronoText(seconds: context.state.secondsRemaining))
                        .font(.system(size: 22, weight: .ultraLight))
                        .monospacedDigit()
                        .foregroundColor(Color(white: 0.72))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: Double(context.state.secondsRemaining), total: 5400)
                        .progressViewStyle(.linear)
                        .tint(Color(white: 0.3))
                        .background(Color(white: 0.1))
                }
            } compactLeading: {
                Image(systemName: "lock.fill")
                    .font(.system(size: 11))
                    .foregroundColor(Color(white: 0.5))
            } compactTrailing: {
                Text(chronoText(seconds: context.state.secondsRemaining))
                    .font(.system(size: 11, weight: .light))
                    .monospacedDigit()
                    .foregroundColor(Color(white: 0.65))
                    .frame(minWidth: 44)
            } minimal: {
                Image(systemName: "lock.fill")
                    .font(.system(size: 10))
                    .foregroundColor(Color(white: 0.5))
            }
            .keylineTint(Color(white: 0.2))
        }
    }

    private func chronoText(seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - Lock Screen View
@available(iOS 16.2, *)
struct LockScreenView: View {
    let context: ActivityViewContext<SentinelleActivityAttributes>

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 20))
                .foregroundColor(Color(white: 0.4))

            VStack(alignment: .leading, spacing: 3) {
                Text(context.state.mode)
                    .font(.system(size: 11, weight: .light))
                    .tracking(2)
                    .textCase(.uppercase)
                    .foregroundColor(Color(white: 0.4))
                Text("Temps restant")
                    .font(.system(size: 10, weight: .light))
                    .foregroundColor(Color(white: 0.25))
            }

            Spacer()

            Text(chronoText(seconds: context.state.secondsRemaining))
                .font(.system(size: 32, weight: .ultraLight))
                .monospacedDigit()
                .foregroundColor(Color(white: 0.7))
                .tracking(-1)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.black)
    }

    private func chronoText(seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - Live Activity Manager (appelé depuis FocusManager)
// Ajouter ceci dans FocusManager.swift pour démarrer/arrêter la Live Activity
/*
import ActivityKit

extension FocusManager {

    func startLiveActivity(session: FocusSession) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attrs = SentinelleActivityAttributes(sessionStartDate: session.startDate)
        let state = SentinelleActivityAttributes.ContentState(
            secondsRemaining: session.durationSeconds,
            mode: session.mode == .ultraFocus ? "ULTRA FOCUS" : "ZEN",
            isUltraFocus: session.mode == .ultraFocus
        )
        do {
            let activity = try Activity<SentinelleActivityAttributes>.request(
                attributes: attrs,
                content: .init(state: state, staleDate: session.endDate)
            )
            print("[LiveActivity] Démarrée: \(activity.id)")
        } catch {
            print("[LiveActivity] Erreur: \(error)")
        }
    }

    func updateLiveActivity(secondsRemaining: Int) async {
        for activity in Activity<SentinelleActivityAttributes>.activities {
            let newState = SentinelleActivityAttributes.ContentState(
                secondsRemaining: secondsRemaining,
                mode: currentSession?.mode == .ultraFocus ? "ULTRA FOCUS" : "ZEN",
                isUltraFocus: currentSession?.mode == .ultraFocus ?? false
            )
            await activity.update(.init(state: newState, staleDate: nil))
        }
    }

    func endLiveActivity() async {
        for activity in Activity<SentinelleActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
*/
