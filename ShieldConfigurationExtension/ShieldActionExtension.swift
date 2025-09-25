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

    override init() {
        super.init()
        print("🔧 ShieldActionExtension initialized")
    }

    override func handle(action: ShieldAction, for application: Application, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        print("🎯 ShieldActionExtension handle called for application - action: \(action)")

        switch action {
        case .primaryButtonPressed:
            print("🔵 Primary button pressed (Open Envive)")
            // Handle "Open Envive" button - open the main app then close shield
            if let url = URL(string: "envivenew://") {
                print("🔗 Attempting to open URL: \(url)")
                UIApplication.shared.open(url, options: [:]) { success in
                    print("📱 Envive app open result: \(success)")
                    if !success {
                        print("❌ Failed to open Envive app via URL scheme")
                    }
                }
            } else {
                print("❌ Failed to create URL for envivenew://")
            }
            print("🔵 Calling completionHandler(.close)")
            completionHandler(.close)

        case .secondaryButtonPressed:
            print("🟡 Secondary button pressed (Go to Home Screen)")
            // Handle "Go to Home Screen" button - close shield to go to home
            completionHandler(.close)

        @unknown default:
            print("❓ Unknown action: \(action)")
            completionHandler(.close)
        }
    }

    override func handle(action: ShieldAction, for webDomain: WebDomain, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        print("🎯 ShieldActionExtension handle called for webDomain - action: \(action)")

        switch action {
        case .primaryButtonPressed:
            print("🔵 Primary button pressed (Open Envive) - webDomain")
            if let url = URL(string: "envivenew://") {
                UIApplication.shared.open(url, options: [:]) { success in
                    print("📱 Envive app open result: \(success)")
                    if !success {
                        print("❌ Failed to open Envive app via URL scheme")
                    }
                }
            }
            completionHandler(.close)

        case .secondaryButtonPressed:
            print("🟡 Secondary button pressed (Go to Home Screen) - webDomain")
            completionHandler(.close)

        @unknown default:
            print("❓ Unknown action: \(action) - webDomain")
            completionHandler(.close)
        }
    }

    override func handle(action: ShieldAction, for category: ActivityCategory, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        print("🎯 ShieldActionExtension handle called for category - action: \(action)")

        switch action {
        case .primaryButtonPressed:
            print("🔵 Primary button pressed (Open Envive) - category")
            if let url = URL(string: "envivenew://") {
                UIApplication.shared.open(url, options: [:]) { success in
                    print("📱 Envive app open result: \(success)")
                    if !success {
                        print("❌ Failed to open Envive app via URL scheme")
                    }
                }
            }
            completionHandler(.close)

        case .secondaryButtonPressed:
            print("🟡 Secondary button pressed (Go to Home Screen) - category")
            completionHandler(.close)

        @unknown default:
            print("❓ Unknown action: \(action) - category")
            completionHandler(.close)
        }
    }
}