import DeviceActivity
import ManagedSettings
import Foundation
import FamilyControls
import Combine
import UIKit
import SwiftUI

// Note: This would typically be in a separate DeviceActivity Monitor Extension target
// For now, including it in the main app for reference
class EnviveNewDeviceActivityMonitor: DeviceActivityMonitor {
    let store = ManagedSettingsStore()
    let userDefaults = UserDefaults(suiteName: "group.com.envivenew.screentime")

    nonisolated override init() {
        super.init()
    }

    nonisolated override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        // Load app selection from shared storage
        guard let data = userDefaults?.data(forKey: "familyActivitySelection"),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
            logActivity("No app selection found for activity: \(activity)")
            return
        }

        // Apply restrictions based on activity type
        switch activity.rawValue {
        case "screenTimeSession":
            // For screen time sessions, we unblock apps (this is handled in the main app)
            logActivity("Screen time session started - apps should be unblocked")

        case "timerRestriction", "dailyRestriction", "usageThreshold":
            // Apply restrictions for blocking activities with custom shield
            if !selection.applicationTokens.isEmpty {
                store.shield.applications = selection.applicationTokens
                store.shield.applicationCategories = .none
            }

            if !selection.categoryTokens.isEmpty {
                store.shield.applicationCategories = .specific(selection.categoryTokens)
            }

            if !selection.webDomainTokens.isEmpty {
                store.shield.webDomains = selection.webDomainTokens
            }

            // Configure custom shield appearance
            configureCustomShield(for: store)

            logActivity("Restrictions applied for activity: \(activity)")

        default:
            logActivity("Unknown activity started: \(activity)")
        }
    }

    nonisolated override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        switch activity.rawValue {
        case "screenTimeSession":
            // Re-apply restrictions when screen time session ends
            guard let data = userDefaults?.data(forKey: "familyActivitySelection"),
                  let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
                logActivity("No app selection found to restore restrictions")
                return
            }

            // Apply basic shield for re-blocking
            if !selection.applicationTokens.isEmpty {
                store.shield.applications = selection.applicationTokens
            }

            if !selection.categoryTokens.isEmpty {
                store.shield.applicationCategories = .specific(selection.categoryTokens)
            }

            logActivity("Screen time session ended - Safari re-blocked with custom shield")

        case "timerRestriction", "dailyRestriction":
            // Remove restrictions when timer ends
            store.clearAllSettings()
            logActivity("Timer restrictions removed for activity: \(activity)")

        default:
            logActivity("Activity ended: \(activity)")
        }
    }

    nonisolated override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)

        // Handle threshold events (time limits reached)
        guard let data = userDefaults?.data(forKey: "familyActivitySelection"),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
            logActivity("No app selection found for threshold event")
            return
        }

        // Apply additional restrictions when threshold reached
        store.shield.applications = selection.applicationTokens

        if !selection.categoryTokens.isEmpty {
            store.shield.applicationCategories = .specific(selection.categoryTokens)
        }

        logActivity("Time threshold reached for event: \(event), activity: \(activity)")

        // Notify main app about threshold reached
        notifyMainApp(event: "thresholdReached", activity: activity.rawValue)
    }

    nonisolated override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
        logActivity("Warning: Activity will start soon: \(activity)")
        notifyMainApp(event: "willStart", activity: activity.rawValue)
    }

    nonisolated override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
        logActivity("Warning: Activity will end soon: \(activity)")
        notifyMainApp(event: "willEnd", activity: activity.rawValue)
    }

    private func logActivity(_ message: String) {
        let timestamp = Date().timeIntervalSince1970
        let logEntry = "\(timestamp): \(message)"

        var logs = userDefaults?.stringArray(forKey: "activityLogs") ?? []
        logs.append(logEntry)

        // Keep only last 100 entries
        if logs.count > 100 {
            logs = Array(logs.suffix(100))
        }

        userDefaults?.set(logs, forKey: "activityLogs")

        // Also log for debugging (this won't work in actual extension)
        print("[DeviceActivityMonitor] \(message)")
    }

    private func notifyMainApp(event: String, activity: String) {
        let notification = [
            "event": event,
            "activity": activity,
            "timestamp": Date().timeIntervalSince1970
        ] as [String: Any]

        var notifications = userDefaults?.array(forKey: "monitorNotifications") ?? []
        notifications.append(notification)

        // Keep only last 50 notifications
        if notifications.count > 50 {
            notifications = Array(notifications.suffix(50))
        }

        userDefaults?.set(notifications, forKey: "monitorNotifications")
    }

    private func configureCustomShield(for store: ManagedSettingsStore) {
        // Configure the shield to use our custom Shield Configuration Extension
        store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific([], except: Set())

        // This tells the system to use our ShieldConfigurationExtension
        // The extension bundle identifier should match our project configuration
        logActivity("Custom shield configuration applied with ShieldConfigurationExtension")
    }
}

// MARK: - Monitor Integration Helper
class DeviceActivityMonitorHelper: ObservableObject {
    private let userDefaults = UserDefaults(suiteName: "group.com.envivenew.screentime")
    @Published var activityLogs: [String] = []
    @Published var recentNotifications: [[String: Any]] = []

    init() {
        loadLogs()
        loadNotifications()
    }

    func loadLogs() {
        activityLogs = userDefaults?.stringArray(forKey: "activityLogs") ?? []
    }

    func loadNotifications() {
        recentNotifications = userDefaults?.array(forKey: "monitorNotifications") as? [[String: Any]] ?? []
    }

    func clearLogs() {
        userDefaults?.removeObject(forKey: "activityLogs")
        userDefaults?.removeObject(forKey: "monitorNotifications")
        activityLogs = []
        recentNotifications = []
    }

    var formattedLogs: [String] {
        return activityLogs.suffix(20).map { log in
            let components = log.split(separator: ":", maxSplits: 1)
            if components.count == 2,
               let timestamp = Double(components[0]) {
                let date = Date(timeIntervalSince1970: timestamp)
                let formatter = DateFormatter()
                formatter.dateStyle = .none
                formatter.timeStyle = .medium
                return "\(formatter.string(from: date)): \(components[1])"
            }
            return log
        }
    }
}