//
//  FocusWidget_Previews.swift
//  EnviveNewWidgets
//
//  Created by Claude on 9/29/25.
//

import WidgetKit
import SwiftUI

// MARK: - Previews
struct FocusWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // MARK: - Small Widget Previews

            // Small - Normal State (Light)
            FocusWidgetEntryView(entry: FocusWidgetEntry.sample)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Small - Normal (Light)")

            // Small - Normal State (Dark)
            FocusWidgetEntryView(entry: FocusWidgetEntry.sample)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .environment(\.colorScheme, .dark)
                .previewDisplayName("Small - Normal (Dark)")

            // Small - High Values
            FocusWidgetEntryView(entry: FocusWidgetEntry.highValues)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Small - High Values")

            // MARK: - Medium Widget Previews

            // Medium - Normal State (Light)
            FocusWidgetEntryView(entry: FocusWidgetEntry.sample)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Medium - Normal (Light)")

            // Medium - Normal State (Dark)
            FocusWidgetEntryView(entry: FocusWidgetEntry.sample)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .environment(\.colorScheme, .dark)
                .previewDisplayName("Medium - Normal (Dark)")
        }
    }
}