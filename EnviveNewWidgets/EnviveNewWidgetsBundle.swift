//
//  EnviveNewWidgetsBundle.swift
//  EnviveNewWidgets
//
//  Created by Paul Ahlstrom on 9/29/25.
//

import WidgetKit
import SwiftUI

@main
struct EnviveNewWidgetsBundle: WidgetBundle {
    var body: some Widget {
        EnviveNewWidgets()
        EnviveNewWidgetsLiveActivity()
        FocusWidget()
        EnviveSpendingWidget()
    }
}
