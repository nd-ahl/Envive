//
//  DeviceActivityMonitorExtension.swift
//  DeviceActivityMonitorExtension
//
//  Created by Paul Ahlstrom on 9/22/25.
//

import DeviceActivity
import ManagedSettings
import Foundation
import FamilyControls

class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    let store = ManagedSettingsStore()
    let userDefaults = UserDefaults(suiteName: "group.com.neal.envivenew.screentime")

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        print("Device Activity Monitor - intervalDidStart: \(activity)")

        // Load app selection from shared storage
        guard let data = userDefaults?.data(forKey: "familyActivitySelection"),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
            print("No app selection found for activity: \(activity)")
            return
        }

        // Apply restrictions based on activity type
        switch activity.rawValue {
        case "screenTimeSession":
            // For screen time sessions, we unblock apps temporarily
            store.clearAllSettings()
            print("Screen time session started - apps unblocked")

        case "timerRestriction", "dailyRestriction", "usageThreshold":
            // Apply restrictions for blocking activities
            if !selection.applicationTokens.isEmpty {
                store.shield.applications = selection.applicationTokens
            }

            if !selection.categoryTokens.isEmpty {
                store.shield.applicationCategories = .specific(selection.categoryTokens)
            }

            if !selection.webDomainTokens.isEmpty {
                store.shield.webDomains = selection.webDomainTokens
            }

            print("Restrictions applied for activity: \(activity)")

        default:
            print("Unknown activity started: \(activity)")
        }
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        print("Device Activity Monitor - intervalDidEnd: \(activity)")

        switch activity.rawValue {
        case "screenTimeSession":
            // Re-apply restrictions when screen time session ends
            guard let data = userDefaults?.data(forKey: "familyActivitySelection"),
                  let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
                print("No app selection found to re-apply restrictions")
                return
            }

            if !selection.applicationTokens.isEmpty {
                store.shield.applications = selection.applicationTokens
            }

            if !selection.categoryTokens.isEmpty {
                store.shield.applicationCategories = .specific(selection.categoryTokens)
            }

            if !selection.webDomainTokens.isEmpty {
                store.shield.webDomains = selection.webDomainTokens
            }

            print("Screen time session ended - restrictions re-applied")

        case "timerRestriction", "dailyRestriction":
            // Remove restrictions when timer ends
            store.clearAllSettings()
            print("Timer restrictions removed for activity: \(activity)")

        default:
            print("Activity ended: \(activity)")
        }
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)

        print("Device Activity Monitor - threshold reached: \(event) for activity: \(activity)")

        // Apply restrictions when threshold is reached
        guard let data = userDefaults?.data(forKey: "familyActivitySelection"),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
            print("No app selection found for threshold event")
            return
        }

        if !selection.applicationTokens.isEmpty {
            store.shield.applications = selection.applicationTokens
        }

        if !selection.categoryTokens.isEmpty {
            store.shield.applicationCategories = .specific(selection.categoryTokens)
        }

        print("Threshold restrictions applied")
    }
}
