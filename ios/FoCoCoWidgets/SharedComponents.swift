import SwiftUI

/// Solid CTA pill used across all FoCoCo widgets.
struct CTAButton: View {
    let title: String
    let systemImage: String
    let tint: Color
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: compact ? 11 : 13, weight: .bold))
            Text(title)
                .font(.system(size: compact ? 12 : 13,
                              weight: .semibold, design: .rounded))
                .lineLimit(1)
        }
        .foregroundColor(.black)
        .frame(maxWidth: .infinity)
        .padding(.vertical, compact ? 7 : 9)
        .background(
            Capsule().fill(
                LinearGradient(colors: [tint, tint.opacity(0.85)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
        )
        .shadow(color: tint.opacity(0.35), radius: 8, x: 0, y: 4)
    }
}

/// Tinted ghost button — used when two side-by-side CTAs share one widget.
struct GhostCTAButton: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(tint)
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(FoTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(tint.opacity(0.18))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(tint.opacity(0.45), lineWidth: 0.7)
        )
    }
}

/// Thin progress bar with brand-tinted fill.
struct ProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.12))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [FoTheme.primary, FoTheme.golfPrimary],
                            startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(width: geo.size.width * progress)
            }
        }
    }
}
