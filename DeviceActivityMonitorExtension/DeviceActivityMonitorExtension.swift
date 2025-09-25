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

        print("🔄 Device Activity Monitor - intervalDidStart: \(activity)")
        print("📂 UserDefaults suite: \(userDefaults?.description ?? "nil")")

        // Apply restrictions based on activity type
        switch activity.rawValue {
        case "screenTimeSession":
            print("🔓 SCREEN TIME SESSION STARTING - REMOVING ALL RESTRICTIONS")

            // For screen time sessions, we completely remove all restrictions
            store.shield.applications = nil
            store.shield.applicationCategories = nil
            store.shield.webDomains = nil

            // Also clear all other settings
            store.clearAllSettings()

            print("✅ Screen time session started - all apps should now be unblocked")
            print("🔍 Current shield state after clearing:")
            print("   - Applications: \(store.shield.applications == nil ? "nil" : "has value")")
            print("   - Categories: \(store.shield.applicationCategories == nil ? "nil" : "has value")")
            print("   - Web domains: \(store.shield.webDomains == nil ? "nil" : "has value")")

        case "timerRestriction", "dailyRestriction", "usageThreshold":
            print("🔒 BLOCKING ACTIVITY STARTING - APPLYING RESTRICTIONS")

            // Load app selection from shared storage and apply restrictions
            guard let data = userDefaults?.data(forKey: "familyActivitySelection"),
                  let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
                print("❌ No app selection found for activity: \(activity)")
                return
            }

            print("📱 Found app selection - applying restrictions...")
            print("   - Apps to block: \(selection.applicationTokens.count)")
            print("   - Categories to block: \(selection.categoryTokens.count)")
            print("   - Web domains to block: \(selection.webDomainTokens.count)")

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

            print("✅ Restrictions applied for activity: \(activity)")

        default:
            print("❓ Unknown activity started: \(activity)")
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
