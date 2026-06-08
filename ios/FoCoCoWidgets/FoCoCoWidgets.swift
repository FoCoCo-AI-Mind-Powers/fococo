import WidgetKit
import SwiftUI

@main
struct FoCoCoWidgetBundle: WidgetBundle {
    var body: some Widget {
        CaddyPlayWidget()
        MindSessionWidget()
        GolfChatWidget()
        FoCoCoWidgetsControl()
        FoCoCoWidgetsLiveActivity()
    }
}
