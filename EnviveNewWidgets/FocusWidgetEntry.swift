//
//  FocusWidgetEntry.swift
//  EnviveNewWidgets
//
//  Created by Claude on 9/29/25.
//

import WidgetKit
import Foundation

struct FocusWidgetEntry: TimelineEntry {
    let date: Date
    let minutes: Int
    let streak: Int

    // Sample data for previews
    static let sample = FocusWidgetEntry(
        date: Date(),
        minutes: 45,
        streak: 2
    )

    // Empty state
    static let empty = FocusWidgetEntry(
        date: Date(),
        minutes: 0,
        streak: 0
    )

    // Additional sample data for previews
    static let highValues = FocusWidgetEntry(
        date: Date(),
        minutes: 120,
        streak: 7
    )

    static let lowMinutes = FocusWidgetEntry(
        date: Date(),
        minutes: 5,
        streak: 15
    )
}