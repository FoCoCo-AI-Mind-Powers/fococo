import SwiftUI

/// FoCoCo brand palette mirrored from lib/flutter_flow/flutter_flow_theme.dart
/// Hex constants are duplicated intentionally — widgets run in their own
/// process and need compile-time colors.
enum FoTheme {
    static let primary = Color(red: 254/255, green: 164/255, blue: 0/255)     // #FEA400 orange
    static let secondary = Color(red: 10/255, green: 54/255, blue: 105/255)   // #0A3669 navy
    static let tertiary = Color(red: 1/255, green: 123/255, blue: 61/255)     // #017B3D forest
    static let bgPrimary = Color(red: 17/255, green: 24/255, blue: 39/255)    // #111827
    static let bgSecondary = Color(red: 31/255, green: 41/255, blue: 55/255)  // #1F2937
    static let glassBorder = Color(red: 55/255, green: 65/255, blue: 81/255)  // #374151
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 148/255, green: 163/255, blue: 184/255) // #94A3B8

    /// Mindfulness accent for MindSession widget.
    static let mindfulness = Color(red: 14/255, green: 165/255, blue: 233/255)   // #0EA5E9
    /// Confidence accent for MindSession widget.
    static let confidence = Color(red: 168/255, green: 85/255, blue: 247/255)    // #A855F7

    static let golfPrimary = Color(red: 34/255, green: 197/255, blue: 94/255)    // #22C55E
}

/// A subtly animated brand gradient. Uses TimelineView so the angle drifts
/// across the widget's refresh budget — true continuous animation isn't
/// possible in WidgetKit, but this gives the surface a sense of life.
struct AnimatedBrandGradient: View {
    let stops: [Color]
    var period: TimeInterval = 60 * 8 // one full sweep over 8 minutes

    init(_ stops: [Color], period: TimeInterval = 60 * 8) {
        self.stops = stops
        self.period = period
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0)) { context in
            let phase = context.date.timeIntervalSinceReferenceDate
                .truncatingRemainder(dividingBy: period) / period
            let angle = phase * 360
            AngularGradient(
                gradient: Gradient(colors: stops + [stops.first ?? .clear]),
                center: .center,
                angle: .degrees(angle)
            )
            .blur(radius: 60)
            .overlay(FoTheme.bgPrimary.opacity(0.55))
        }
    }
}

/// Glassmorphic card styling matching the app surfaces.
struct GlassCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(FoTheme.bgSecondary.opacity(0.55))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(FoTheme.glassBorder.opacity(0.55), lineWidth: 0.6)
            )
    }
}

extension View {
    func foGlassCard() -> some View { modifier(GlassCardStyle()) }
}
