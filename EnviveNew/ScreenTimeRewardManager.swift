import SwiftUI
import Combine

class ScreenTimeRewardManager: ObservableObject {
    @Published var earnedMinutes: Int = 0
    @Published var isScreenTimeActive = false
    @Published var activeSessionMinutes: Int = 0

    private let settingsManager = SettingsManager()
    private let scheduler = ActivityScheduler()
    private let appSelectionStore = AppSelectionStore()

    private let xpToMinutesRatio: Double = 10.0 // 10 XP = 1 minute
    private let userDefaults = UserDefaults.standard
    private let earnedMinutesKey = "earnedScreenTimeMinutes"

    init() {
        loadEarnedMinutes()
    }

    func redeemXPForScreenTime(xpAmount: Int) -> Int {
        let earnedMinutes = Int(Double(xpAmount) / xpToMinutesRatio)
        self.earnedMinutes += earnedMinutes
        saveEarnedMinutes()
        print("Redeemed \(xpAmount) XP for \(earnedMinutes) minutes of screen time")
        return earnedMinutes
    }

    func startScreenTimeSession(durationMinutes: Int) -> Bool {
        guard durationMinutes <= earnedMinutes else {
            print("Insufficient earned minutes: requested \(durationMinutes), available \(earnedMinutes)")
            return false
        }

        // Remove used minutes
        earnedMinutes -= durationMinutes
        saveEarnedMinutes()

        // Temporarily lift restrictions for earned time
        settingsManager.unblockApps()
        isScreenTimeActive = true
        activeSessionMinutes = durationMinutes

        // Schedule re-application of restrictions
        scheduler.startScreenTimeSession(durationMinutes: durationMinutes)

        // Schedule end of session
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(durationMinutes * 60)) {
            self.endScreenTimeSession()
        }

        print("Started screen time session for \(durationMinutes) minutes")
        return true
    }

    func endScreenTimeSession() {
        // Re-apply restrictions using stored app selection
        if appSelectionStore.hasSelectedApps {
            settingsManager.blockApps(appSelectionStore.familyActivitySelection)
        }

        isScreenTimeActive = false
        activeSessionMinutes = 0
        scheduler.stopAllMonitoring()
        print("Ended screen time session")
    }

    func addBonusMinutes(_ minutes: Int, reason: String = "Task completion") {
        earnedMinutes += minutes
        saveEarnedMinutes()
        print("Added \(minutes) bonus minutes: \(reason)")
    }

    private func saveEarnedMinutes() {
        userDefaults.set(earnedMinutes, forKey: earnedMinutesKey)
    }

    private func loadEarnedMinutes() {
        earnedMinutes = userDefaults.integer(forKey: earnedMinutesKey)
    }

    // MARK: - Convenience Properties

    var hasEarnedTime: Bool {
        earnedMinutes > 0
    }

    var canStartSession: Bool {
        hasEarnedTime && !isScreenTimeActive
    }

    func formattedEarnedTime() -> String {
        if earnedMinutes >= 60 {
            let hours = earnedMinutes / 60
            let minutes = earnedMinutes % 60
            return "\(hours)h \(minutes)m"
        } else {
            return "\(earnedMinutes)m"
        }
    }

    func formattedActiveTime() -> String {
        if activeSessionMinutes >= 60 {
            let hours = activeSessionMinutes / 60
            let minutes = activeSessionMinutes % 60
            return "\(hours)h \(minutes)m"
        } else {
            return "\(activeSessionMinutes)m"
        }
    }
}