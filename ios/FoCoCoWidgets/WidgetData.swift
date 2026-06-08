import Foundation

/// App Group identifier shared between the Runner app and FoCoCoWidgets target.
/// Add this group ID to BOTH targets' "App Groups" capability in Xcode.
enum FoWidgetAppGroup {
    static let identifier = "group.com.fococo.fococo"

    static var defaults: UserDefaults? {
        UserDefaults(suiteName: identifier)
    }
}

/// Keys written by Flutter (via home_widget) and read by the widget extension.
/// The home_widget plugin namespaces values; we read them via the suite UserDefaults.
enum FoWidgetKey {
    static let hasActiveRound = "fococo.caddyplay.hasActiveRound"
    static let courseName     = "fococo.caddyplay.courseName"
    static let currentHole    = "fococo.caddyplay.currentHole"
    static let holesTotal     = "fococo.caddyplay.holesTotal"
    static let scoreToPar     = "fococo.caddyplay.scoreToPar"
}

/// Snapshot of the active golf round for the CaddyPlay widget.
struct CaddyPlaySnapshot {
    let hasActiveRound: Bool
    let courseName: String
    let currentHole: Int
    let holesTotal: Int
    let scoreToPar: Int

    static let placeholder = CaddyPlaySnapshot(
        hasActiveRound: false,
        courseName: "Pebble Beach",
        currentHole: 7,
        holesTotal: 18,
        scoreToPar: 2
    )

    static func load() -> CaddyPlaySnapshot {
        guard let d = FoWidgetAppGroup.defaults else {
            return CaddyPlaySnapshot(
                hasActiveRound: false, courseName: "",
                currentHole: 0, holesTotal: 18, scoreToPar: 0
            )
        }
        return CaddyPlaySnapshot(
            hasActiveRound: d.bool(forKey: FoWidgetKey.hasActiveRound),
            courseName: d.string(forKey: FoWidgetKey.courseName) ?? "",
            currentHole: d.integer(forKey: FoWidgetKey.currentHole),
            holesTotal: max(d.integer(forKey: FoWidgetKey.holesTotal), 18),
            scoreToPar: d.integer(forKey: FoWidgetKey.scoreToPar)
        )
    }

    var holeProgress: Double {
        guard holesTotal > 0 else { return 0 }
        return min(max(Double(currentHole) / Double(holesTotal), 0), 1)
    }
}

/// Deep-link URLs handed back to the Flutter app on widget tap.
/// Flutter's go_router (with FlutterDeepLinkingEnabled in Info.plist) maps
/// these onto the routes declared in lib/flutter_flow/nav/nav.dart.
enum FoWidgetLink {
    // Triple-slash so the host is empty and the path component matches the
    // GoRouter routes declared in lib/flutter_flow/nav/nav.dart.
    static let caddyPlayNew    = URL(string: "fococo:///caddy_play?action=new")!
    static let caddyPlayResume = URL(string: "fococo:///caddy_play?action=resume")!
    static let mindFocus       = URL(string: "fococo:///mind_coach?session=focus")!
    static let mindConfidence  = URL(string: "fococo:///mind_coach?session=confidence")!
    static let golfChat        = URL(string: "fococo:///golf_chat")!
}
