//
//  ShieldActionExtension.swift
//  ShieldConfigurationExtension
//
//  Created by Paul Ahlstrom on 9/22/25.
//

import ManagedSettings
import ManagedSettingsUI
import UIKit

class ShieldActionExtension: ShieldActionDelegate {

    func handle(action: ShieldAction, for application: Application, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        print("🎯 ShieldActionExtension handle called for application - action: \(action)")

        switch action {
        case .primaryButtonPressed:
            print("🔵 Primary button pressed (Go to Home Screen)")
            completionHandler(.close)

        case .secondaryButtonPressed:
            print("🟡 Secondary button pressed")
            completionHandler(.close)

        @unknown default:
            print("❓ Unknown action: \(action)")
            completionHandler(.close)
        }
    }

    func handle(action: ShieldAction, for webDomain: WebDomain, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        print("🎯 ShieldActionExtension handle called for webDomain - action: \(action)")

        switch action {
        case .primaryButtonPressed:
            print("🔵 Primary button pressed (Go to Home Screen) - webDomain")
            completionHandler(.close)

        case .secondaryButtonPressed:
            print("🟡 Secondary button pressed - webDomain")
            completionHandler(.close)

        @unknown default:
            print("❓ Unknown action: \(action) - webDomain")
            completionHandler(.close)
        }
    }

    func handle(action: ShieldAction, for category: ActivityCategory, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        print("🎯 ShieldActionExtension handle called for category - action: \(action)")

        switch action {
        case .primaryButtonPressed:
            print("🔵 Primary button pressed (Go to Home Screen) - category")
            completionHandler(.close)

        case .secondaryButtonPressed:
            print("🟡 Secondary button pressed - category")
            completionHandler(.close)

        @unknown default:
            print("❓ Unknown action: \(action) - category")
            completionHandler(.close)
        }
    }
}