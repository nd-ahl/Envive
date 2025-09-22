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

    override func handle(action: ShieldAction, for application: Application, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            // Handle "Open Envive" button - open the main app
            if let url = URL(string: "envivenew://") {
                extensionContext?.open(url) { success in
                    print("App open result: \(success)")
                }
            }
            // Always close regardless of URL open result
            completionHandler(.close)

        case .secondaryButtonPressed:
            // Handle "Go to Home Screen" button - defer to home screen
            completionHandler(.defer)

        @unknown default:
            completionHandler(.defer)
        }
    }

    override func handle(action: ShieldAction, for webDomain: WebDomain, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            // Handle "Open Envive" button - open the main app
            if let url = URL(string: "envivenew://") {
                extensionContext?.open(url) { success in
                    print("App open result: \(success)")
                }
            }
            completionHandler(.close)

        case .secondaryButtonPressed:
            // Handle "Go to Home Screen" button - defer to home screen
            completionHandler(.defer)

        @unknown default:
            completionHandler(.defer)
        }
    }

    override func handle(action: ShieldAction, for category: ActivityCategory, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            // Handle "Open Envive" button - open the main app
            if let url = URL(string: "envivenew://") {
                extensionContext?.open(url) { success in
                    print("App open result: \(success)")
                }
            }
            completionHandler(.close)

        case .secondaryButtonPressed:
            // Handle "Go to Home Screen" button - defer to home screen
            completionHandler(.defer)

        @unknown default:
            completionHandler(.defer)
        }
    }
}