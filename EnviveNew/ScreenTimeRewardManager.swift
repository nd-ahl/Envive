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

        // Ensure app selection is saved to shared storage for the monitor extension
        appSelectionStore.saveSelection()

        // Remove used minutes
        earnedMinutes -= durationMinutes
        saveEarnedMinutes()

        // Update state
        isScreenTimeActive = true
        activeSessionMinutes = durationMinutes

        // Start the device activity session (this will trigger the monitor extension to unblock apps)
        scheduler.startScreenTimeSession(durationMinutes: durationMinutes)

        // Schedule end of session as backup (the device activity monitor should handle this)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(durationMinutes * 60)) {
            self.endScreenTimeSession()
        }

        print("Started screen time session for \(durationMinutes) minutes")
        return true
    }

    func endScreenTimeSession() {
        // Stop the device activity monitoring (this will trigger re-application of restrictions)
        scheduler.stopAllMonitoring()

        // Update state
        isScreenTimeActive = false
        activeSessionMinutes = 0

        // Fallback: Re-apply restrictions using settings manager in case device activity monitor fails
        if appSelectionStore.hasSelectedApps {
            settingsManager.blockApps(appSelectionStore.familyActivitySelection)
        }

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