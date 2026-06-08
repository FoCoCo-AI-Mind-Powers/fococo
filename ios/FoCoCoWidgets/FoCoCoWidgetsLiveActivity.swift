import ActivityKit
import WidgetKit
import SwiftUI

/// Attributes struct exposed to ActivityKit. The `live_activities` Flutter
/// plugin requires this exact name and shape — renaming or moving it will
/// silently disable Live Activity delivery.
struct LiveActivitiesAppAttributes: ActivityAttributes, Identifiable {
    /// Required by the plugin: aliases `ContentState` so updates don't
    /// silently fail.
    public typealias LiveDeliveryData = ContentState

    public struct ContentState: Codable, Hashable {
        var appGroupId: String
    }

    var id = UUID()
}

extension LiveActivitiesAppAttributes {
    /// Mirrors the key namespace used by the plugin when writing
    /// activity-scoped values into the App Group `UserDefaults`.
    func prefixedKey(_ key: String) -> String {
        return "\(id)_\(key)"
    }
}

/// Snapshot of the FoCoCo coaching-session state, hydrated from the App Group
/// `UserDefaults` namespace owned by this activity.
fileprivate struct LiveActivityState {
    let status: String       // "connecting" | "listening" | "speaking" | "ended"
    let topic: String        // e.g. "Mental coaching"
    let transcript: String   // most recent line of the AI / user
    let elapsed: String      // "00:42"

    static func load(attributes: LiveActivitiesAppAttributes) -> LiveActivityState {
        let suite = UserDefaults(suiteName: FoWidgetAppGroup.identifier)
        return LiveActivityState(
            status: suite?.string(forKey: attributes.prefixedKey("status")) ?? "listening",
            topic: suite?.string(forKey: attributes.prefixedKey("topic")) ?? "FoCoCo Coach",
            transcript: suite?.string(forKey: attributes.prefixedKey("transcript")) ?? "",
            elapsed: suite?.string(forKey: attributes.prefixedKey("elapsed")) ?? "00:00"
        )
    }

    var statusColor: Color {
        switch status {
        case "connecting": return FoTheme.textSecondary
        case "listening":  return FoTheme.golfPrimary
        case "speaking":   return FoTheme.primary
        case "ended":      return FoTheme.textSecondary
        default:            return FoTheme.golfPrimary
        }
    }

    var statusLabel: String {
        switch status {
        case "connecting": return "Connecting…"
        case "listening":  return "Listening"
        case "speaking":   return "Coach speaking"
        case "ended":      return "Session ended"
        default:            return status.capitalized
        }
    }

    var statusIcon: String {
        switch status {
        case "connecting": return "ellipsis"
        case "listening":  return "waveform"
        case "speaking":   return "speaker.wave.2.fill"
        default:            return "mic.fill"
        }
    }
}

struct FoCoCoWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
            LockScreenView(state: LiveActivityState.load(attributes: context.attributes))
                .activityBackgroundTint(Color.black.opacity(0.9))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            let state = LiveActivityState.load(attributes: context.attributes)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: state.statusIcon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(state.statusColor)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(state.elapsed)
                        .font(.system(size: 14, weight: .semibold,
                                      design: .rounded))
                        .foregroundColor(FoTheme.textSecondary)
                        .monospacedDigit()
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(state.statusLabel)
                        .font(.system(size: 14, weight: .heavy,
                                      design: .rounded))
                        .foregroundColor(.white)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if !state.transcript.isEmpty {
                        Text(state.transcript)
                            .font(.system(size: 12))
                            .foregroundColor(FoTheme.textSecondary)
                            .lineLimit(2)
                    }
                }
            } compactLeading: {
                Image(systemName: state.statusIcon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(state.statusColor)
            } compactTrailing: {
                Text(state.elapsed)
                    .font(.system(size: 12, weight: .semibold,
                                  design: .rounded))
                    .foregroundColor(state.statusColor)
                    .monospacedDigit()
            } minimal: {
                Image(systemName: state.statusIcon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(state.statusColor)
            }
            .widgetURL(URL(string: "fococo:///golf_chat"))
            .keylineTint(state.statusColor)
        }
    }
}

private struct LockScreenView: View {
    let state: LiveActivityState

    var body: some View {
        ZStack {
            AnimatedBrandGradient(
                [FoTheme.secondary, FoTheme.primary, FoTheme.tertiary],
                period: 60 * 6
            )
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    ZStack {
                        Circle().fill(state.statusColor.opacity(0.22))
                            .frame(width: 30, height: 30)
                        Image(systemName: state.statusIcon)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(state.statusColor)
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        Text("FOCOCO COACH")
                            .font(.system(size: 10, weight: .heavy,
                                          design: .rounded))
                            .tracking(1.4)
                            .foregroundColor(FoTheme.textSecondary)
                        Text(state.topic)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    Spacer()
                    Text(state.elapsed)
                        .font(.system(size: 16, weight: .bold,
                                      design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()
                }

                Text(state.statusLabel)
                    .font(.system(size: 13, weight: .semibold,
                                  design: .rounded))
                    .foregroundColor(state.statusColor)

                if !state.transcript.isEmpty {
                    Text(state.transcript)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(2)
                }
            }
            .padding(14)
        }
    }
}
