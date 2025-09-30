//
//  EnviveNewWidgetsLiveActivity.swift
//  EnviveNewWidgets
//
//  Created by Paul Ahlstrom on 9/29/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct EnviveNewWidgetsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct EnviveNewWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: EnviveNewWidgetsAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension EnviveNewWidgetsAttributes {
    fileprivate static var preview: EnviveNewWidgetsAttributes {
        EnviveNewWidgetsAttributes(name: "World")
    }
}

extension EnviveNewWidgetsAttributes.ContentState {
    fileprivate static var smiley: EnviveNewWidgetsAttributes.ContentState {
        EnviveNewWidgetsAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: EnviveNewWidgetsAttributes.ContentState {
         EnviveNewWidgetsAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: EnviveNewWidgetsAttributes.preview) {
   EnviveNewWidgetsLiveActivity()
} contentStates: {
    EnviveNewWidgetsAttributes.ContentState.smiley
    EnviveNewWidgetsAttributes.ContentState.starEyes
}
