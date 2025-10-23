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
    // PERFORMANCE FIX: Use shared store to sync with main app
    let store = ManagedSettingsStore(named: ManagedSettingsStore.Name("envive-shared"))
    let userDefaults = UserDefaults(suiteName: "group.com.neal.envivenew.screentime")

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        print("🔄 Device Activity Monitor - intervalDidStart: \(activity)")
        print("📂 UserDefaults suite: \(userDefaults?.description ?? "nil")")

        // PERFORMANCE FIX: Add early guard to prevent unnecessary work
        guard let userDefaults = userDefaults else {
            print("❌ UserDefaults not available - cannot access shared app selection")
            return
        }

        // Apply restrictions based on activity type
        switch activity.rawValue {
        case "screenTimeSession":
            print("🔓 SCREEN TIME SESSION STARTING - REMOVING ALL RESTRICTIONS")

            // PERFORMANCE FIX: Use targeted clearing instead of clearAllSettings()
            // clearAllSettings() takes 9-10 seconds and causes delays/crashes
            store.shield.applications = nil
            store.shield.applicationCategories = nil
            store.shield.webDomains = nil

            print("✅ Screen time session started - all apps should now be unblocked")
            print("🔍 Current shield state after clearing:")
            print("   - Applications: \(store.shield.applications == nil ? "nil" : "has value")")
            print("   - Categories: \(store.shield.applicationCategories == nil ? "nil" : "has value")")
            print("   - Web domains: \(store.shield.webDomains == nil ? "nil" : "has value")")

        case "timerRestriction", "dailyRestriction", "usageThreshold":
            print("🔒 BLOCKING ACTIVITY STARTING - APPLYING RESTRICTIONS")

            // Load app selection from shared storage and apply restrictions
            guard let data = userDefaults.data(forKey: "familyActivitySelection") else {
                print("❌ No app selection data found for activity: \(activity)")
                return
            }

            guard let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
                print("❌ Failed to decode app selection for activity: \(activity)")
                return
            }

            print("📱 Found app selection - applying restrictions...")
            print("   - Apps to block: \(selection.applicationTokens.count)")
            print("   - Categories to block: \(selection.categoryTokens.count)")
            print("   - Web domains to block: \(selection.webDomainTokens.count)")

            // CRASH FIX: Only apply non-empty selections to prevent issues
            if !selection.applicationTokens.isEmpty {
                store.shield.applications = selection.applicationTokens
                print("   ✓ Applied app shields")
            }

            if !selection.categoryTokens.isEmpty {
                store.shield.applicationCategories = .specific(selection.categoryTokens)
                print("   ✓ Applied category shields")
            }

            if !selection.webDomainTokens.isEmpty {
                store.shield.webDomains = selection.webDomainTokens
                print("   ✓ Applied web domain shields")
            }

            print("✅ Restrictions applied for activity: \(activity)")

        default:
            print("❓ Unknown activity started: \(activity)")
        }
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        print("🔄 Device Activity Monitor - intervalDidEnd: \(activity)")

        // CRASH FIX: Add early guard
        guard let userDefaults = userDefaults else {
            print("❌ UserDefaults not available in intervalDidEnd")
            return
        }

        switch activity.rawValue {
        case "screenTimeSession":
            print("🔒 Screen time session ending - re-applying restrictions")

            // Re-apply restrictions when screen time session ends
            guard let data = userDefaults.data(forKey: "familyActivitySelection") else {
                print("❌ No app selection data found to re-apply restrictions")
                return
            }

            guard let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
                print("❌ Failed to decode app selection")
                return
            }

            if !selection.applicationTokens.isEmpty {
                store.shield.applications = selection.applicationTokens
                print("   ✓ Re-applied app shields")
            }

            if !selection.categoryTokens.isEmpty {
                store.shield.applicationCategories = .specific(selection.categoryTokens)
                print("   ✓ Re-applied category shields")
            }

            if !selection.webDomainTokens.isEmpty {
                store.shield.webDomains = selection.webDomainTokens
                print("   ✓ Re-applied web domain shields")
            }

            print("✅ Screen time session ended - restrictions re-applied")

        case "timerRestriction", "dailyRestriction":
            // PERFORMANCE FIX: Use targeted clearing instead of clearAllSettings()
            store.shield.applications = nil
            store.shield.applicationCategories = nil
            store.shield.webDomains = nil
            print("✅ Timer restrictions removed for activity: \(activity)")

        default:
            print("Activity ended: \(activity)")
        }
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)

        print("⏱️ Device Activity Monitor - threshold reached: \(event) for activity: \(activity)")

        // CRASH FIX: Add early guard
        guard let userDefaults = userDefaults else {
            print("❌ UserDefaults not available in threshold event")
            return
        }

        // Apply restrictions when threshold is reached
        guard let data = userDefaults.data(forKey: "familyActivitySelection") else {
            print("❌ No app selection data found for threshold event")
            return
        }

        guard let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
            print("❌ Failed to decode app selection for threshold event")
            return
        }

        if !selection.applicationTokens.isEmpty {
            store.shield.applications = selection.applicationTokens
            print("   ✓ Applied app shields on threshold")
        }

        if !selection.categoryTokens.isEmpty {
            store.shield.applicationCategories = .specific(selection.categoryTokens)
            print("   ✓ Applied category shields on threshold")
        }

        if !selection.webDomainTokens.isEmpty {
            store.shield.webDomains = selection.webDomainTokens
            print("   ✓ Applied web domain shields on threshold")
        }

        print("✅ Threshold restrictions applied")
    }
}
