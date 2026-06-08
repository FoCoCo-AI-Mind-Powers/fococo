import WidgetKit
import SwiftUI

struct GolfChatEntry: TimelineEntry {
    let date: Date
}

struct GolfChatProvider: TimelineProvider {
    func placeholder(in context: Context) -> GolfChatEntry {
        GolfChatEntry(date: Date())
    }
    func getSnapshot(in context: Context, completion: @escaping (GolfChatEntry) -> Void) {
        completion(GolfChatEntry(date: Date()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<GolfChatEntry>) -> Void) {
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        completion(Timeline(entries: [GolfChatEntry(date: Date())], policy: .after(next)))
    }
}

struct GolfChatWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: GolfChatEntry

    var body: some View {
        ZStack {
            AnimatedBrandGradient(
                [FoTheme.golfPrimary, FoTheme.tertiary, FoTheme.secondary],
                period: 60 * 10
            )
            content.padding(family == .systemSmall ? 12 : 16)
        }
        .containerBackground(for: .widget) { FoTheme.bgPrimary }
        .widgetURL(FoWidgetLink.golfChat)
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
            Image(systemName: "message.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(FoTheme.golfPrimary)
            Text("GOLFCHAT")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.4)
                .foregroundColor(FoTheme.textSecondary)
            Spacer()
        }
    }

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            Text("Ask your\ncoach.")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(FoTheme.textPrimary)
                .lineLimit(2)
            Spacer(minLength: 0)
            CTAButton(title: "Open Chat", systemImage: "bubble.left.and.bubble.right.fill",
                      tint: FoTheme.golfPrimary, compact: true)
        }
    }

    private var mediumLayout: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                header
                Text("Talk it out.")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(FoTheme.textPrimary)
                Text("Course strategy, mental cues, swing thoughts — your AI coach is one tap away.")
                    .font(.system(size: 11))
                    .foregroundColor(FoTheme.textSecondary)
                    .lineLimit(3)
                Spacer(minLength: 0)
                CTAButton(title: "Start GolfChat",
                          systemImage: "sparkle",
                          tint: FoTheme.golfPrimary)
            }
            ZStack {
                Circle()
                    .fill(FoTheme.golfPrimary.opacity(0.18))
                    .frame(width: 70, height: 70)
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(FoTheme.golfPrimary)
            }
        }
    }
}

struct GolfChatWidget: Widget {
    let kind: String = "GolfChatWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GolfChatProvider()) { entry in
            GolfChatWidgetView(entry: entry)
        }
        .configurationDisplayName("GolfChat")
        .description("One-tap access to your AI golf coach.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
