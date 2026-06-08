import WidgetKit
import SwiftUI

struct CaddyPlayEntry: TimelineEntry {
    let date: Date
    let snapshot: CaddyPlaySnapshot
}

struct CaddyPlayProvider: TimelineProvider {
    func placeholder(in context: Context) -> CaddyPlayEntry {
        CaddyPlayEntry(date: Date(), snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (CaddyPlayEntry) -> Void) {
        completion(CaddyPlayEntry(date: Date(), snapshot: CaddyPlaySnapshot.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CaddyPlayEntry>) -> Void) {
        let entry = CaddyPlayEntry(date: Date(), snapshot: CaddyPlaySnapshot.load())
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct CaddyPlayWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: CaddyPlayEntry

    var body: some View {
        ZStack {
            AnimatedBrandGradient([FoTheme.tertiary, FoTheme.primary, FoTheme.secondary])
            content
                .padding(family == .systemSmall ? 12 : 16)
        }
        .containerBackground(for: .widget) { FoTheme.bgPrimary }
    }

    @ViewBuilder
    private var content: some View {
        if entry.snapshot.hasActiveRound {
            ResumeRoundCard(snapshot: entry.snapshot, family: family)
        } else {
            NewRoundCard(family: family)
        }
    }
}

private struct ResumeRoundCard: View {
    let snapshot: CaddyPlaySnapshot
    let family: WidgetFamily

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "flag.checkered")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(FoTheme.primary)
                Text("CADDYPLAY")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1.4)
                    .foregroundColor(FoTheme.textSecondary)
                Spacer()
                Text("LIVE")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(FoTheme.golfPrimary))
            }

            Text(snapshot.courseName.isEmpty ? "Round in progress" : snapshot.courseName)
                .font(.system(size: family == .systemSmall ? 14 : 17, weight: .semibold))
                .foregroundColor(FoTheme.textPrimary)
                .lineLimit(1)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("Hole")
                    .font(.system(size: 12))
                    .foregroundColor(FoTheme.textSecondary)
                Text("\(snapshot.currentHole)")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundColor(FoTheme.primary)
                Text("/ \(snapshot.holesTotal)")
                    .font(.system(size: 12))
                    .foregroundColor(FoTheme.textSecondary)
            }

            ProgressBar(progress: snapshot.holeProgress)
                .frame(height: 4)

            Spacer(minLength: 0)

            CTAButton(title: "Resume Round", systemImage: "play.fill",
                      tint: FoTheme.primary)
        }
        .widgetURL(FoWidgetLink.caddyPlayResume)
    }
}

private struct NewRoundCard: View {
    let family: WidgetFamily

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "figure.golf")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(FoTheme.primary)
                Text("CADDYPLAY")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1.4)
                    .foregroundColor(FoTheme.textSecondary)
                Spacer()
            }

            Text("Tee it up.")
                .font(.system(size: family == .systemSmall ? 16 : 22,
                              weight: .bold, design: .rounded))
                .foregroundColor(FoTheme.textPrimary)

            Text("Track score, mood and mental cues hole by hole.")
                .font(.system(size: 11))
                .foregroundColor(FoTheme.textSecondary)
                .lineLimit(family == .systemSmall ? 2 : 3)

            Spacer(minLength: 0)

            CTAButton(title: "Start New Round", systemImage: "plus.circle.fill",
                      tint: FoTheme.primary)
        }
        .widgetURL(FoWidgetLink.caddyPlayNew)
    }
}

struct CaddyPlayWidget: Widget {
    let kind: String = "CaddyPlayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CaddyPlayProvider()) { entry in
            CaddyPlayWidgetView(entry: entry)
        }
        .configurationDisplayName("CaddyPlay")
        .description("Start a round or pick up where you left off.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
