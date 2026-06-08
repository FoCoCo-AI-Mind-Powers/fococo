import WidgetKit
import SwiftUI

struct MindSessionEntry: TimelineEntry {
    let date: Date
}

struct MindSessionProvider: TimelineProvider {
    func placeholder(in context: Context) -> MindSessionEntry {
        MindSessionEntry(date: Date())
    }
    func getSnapshot(in context: Context, completion: @escaping (MindSessionEntry) -> Void) {
        completion(MindSessionEntry(date: Date()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<MindSessionEntry>) -> Void) {
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        completion(Timeline(entries: [MindSessionEntry(date: Date())], policy: .after(next)))
    }
}

struct MindSessionWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: MindSessionEntry

    var body: some View {
        ZStack {
            AnimatedBrandGradient(
                [FoTheme.secondary, FoTheme.mindfulness, FoTheme.confidence],
                period: 60 * 12
            )
            content.padding(family == .systemSmall ? 12 : 16)
        }
        .containerBackground(for: .widget) { FoTheme.bgPrimary }
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .systemSmall:
            smallLayout
        default:
            mediumLayout
        }
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(FoTheme.mindfulness)
            Text("MINDSESSION")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.4)
                .foregroundColor(FoTheme.textSecondary)
            Spacer()
        }
    }

    /// Small family — single CTA opening the MindCoach hub.
    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            Text("Reset.\nRefocus.")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(FoTheme.textPrimary)
                .lineLimit(2)
            Spacer(minLength: 0)
            CTAButton(title: "Start Session", systemImage: "sparkles",
                      tint: FoTheme.mindfulness, compact: true)
        }
        .widgetURL(FoWidgetLink.mindFocus)
    }

    /// Medium family — two side-by-side mode buttons.
    private var mediumLayout: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            Text("Pick a session")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(FoTheme.textPrimary)
            Spacer(minLength: 0)
            HStack(spacing: 10) {
                Link(destination: FoWidgetLink.mindFocus) {
                    GhostCTAButton(title: "Focus",
                                   systemImage: "scope",
                                   tint: FoTheme.mindfulness)
                }
                Link(destination: FoWidgetLink.mindConfidence) {
                    GhostCTAButton(title: "Confidence & Control",
                                   systemImage: "shield.lefthalf.filled",
                                   tint: FoTheme.confidence)
                }
            }
        }
    }
}

struct MindSessionWidget: Widget {
    let kind: String = "MindSessionWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MindSessionProvider()) { entry in
            MindSessionWidgetView(entry: entry)
        }
        .configurationDisplayName("MindSession")
        .description("Jump into Focus or Confidence & Control coaching.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
