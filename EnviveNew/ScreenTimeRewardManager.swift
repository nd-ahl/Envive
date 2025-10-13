import SwiftUI
import Combine
import ActivityKit

struct ScreenTimeActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var remainingMinutes: Int
        var totalMinutes: Int
        var sessionStartTime: Date
    }

    // Fixed properties for the activity
    var sessionType: String
}

class ScreenTimeRewardManager: ObservableObject {
    @Published var earnedMinutes: Int = 0
    @Published var isScreenTimeActive = false
    @Published var activeSessionMinutes: Int = 0
    @Published var remainingSessionMinutes: Int = 0
    @Published var lastConversionRate: Double = 1.0
    @Published var lastConversionTier: String = "Good"

    private let settingsManager = SettingsManager()
    private let scheduler = ActivityScheduler()
    private let appSelectionStore = AppSelectionStore()
    private let credibilityManager: CredibilityManager

    private var sessionTimer: Timer?
    private var currentActivity: Any? // Will hold Activity<ScreenTimeActivityAttributes> on iOS 16.1+

    private let userDefaults = UserDefaults.standard
    private let earnedMinutesKey = "earnedScreenTimeMinutes"

    init(credibilityManager: CredibilityManager = CredibilityManager()) {
        self.credibilityManager = credibilityManager
        loadEarnedMinutes()
    }

    func redeemXPForScreenTime(xpAmount: Int) -> Int {
        // Use credibility-based conversion
        let earnedMinutes = credibilityManager.calculateXPToMinutes(xpAmount: xpAmount)

        // Store conversion details for display
        lastConversionRate = credibilityManager.getConversionRate()
        lastConversionTier = credibilityManager.getCurrentTier().name

        self.earnedMinutes += earnedMinutes
        saveEarnedMinutes()

        let status = credibilityManager.getCredibilityStatus()
        print("✨ Redeemed \(xpAmount) XP for \(earnedMinutes) minutes (Rate: \(credibilityManager.getFormattedConversionRate()), Tier: \(status.tier.name))")

        return earnedMinutes
    }

    /// Preview conversion without actually redeeming
    func previewConversion(xpAmount: Int) -> (minutes: Int, rate: Double, tier: String, hasBonus: Bool) {
        let minutes = credibilityManager.calculateXPToMinutes(xpAmount: xpAmount)
        let rate = credibilityManager.getConversionRate()
        let tier = credibilityManager.getCurrentTier().name
        let hasBonus = credibilityManager.hasRedemptionBonus

        return (minutes, rate, tier, hasBonus)
    }

    /// Get current credibility status for display
    func getCredibilityStatus() -> CredibilityStatus {
        return credibilityManager.getCredibilityStatus()
    }

    /// Get formatted conversion rate for display
    func getFormattedConversionRate() -> String {
        return credibilityManager.getFormattedConversionRate()
    }

    /// Get credibility score color for UI
    func getCredibilityColor() -> String {
        return credibilityManager.getScoreColor()
    }

    func startScreenTimeSession(durationMinutes: Int) -> Bool {
        guard durationMinutes <= earnedMinutes else {
            print("Insufficient earned minutes: requested \(durationMinutes), available \(earnedMinutes)")
            return false
        }

        guard appSelectionStore.hasSelectedApps else {
            print("No apps selected for restrictions - cannot start screen time session")
            return false
        }

        // Ensure app selection is saved to shared storage for the monitor extension
        appSelectionStore.saveSelection()

        // Give the shared storage a moment to sync
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Update state first
            self.isScreenTimeActive = true
            self.activeSessionMinutes = durationMinutes
            self.remainingSessionMinutes = durationMinutes

            // Remove used minutes
            self.earnedMinutes -= durationMinutes
            self.saveEarnedMinutes()

            // Start the device activity session (this will trigger the monitor extension to unblock apps)
            self.scheduler.startScreenTimeSession(durationMinutes: durationMinutes)

            // Start Live Activity for Dynamic Island
            if #available(iOS 16.1, *) {
                self.startLiveActivity(durationMinutes: durationMinutes)
            }

            // Start timer to update remaining time and Live Activity
            self.startSessionTimer()

            // Schedule end of session as backup (the device activity monitor should handle this)
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(durationMinutes * 60)) {
                self.endScreenTimeSession()
            }

            print("Started screen time session for \(durationMinutes) minutes")
        }

        return true
    }

    func endScreenTimeSession() {
        // Stop timer first
        stopSessionTimer()

        // Stop the device activity monitoring (this will trigger re-application of restrictions)
        scheduler.stopAllMonitoring()

        // End Live Activity
        if #available(iOS 16.1, *) {
            endLiveActivity()
        }

        // Update state
        isScreenTimeActive = false
        activeSessionMinutes = 0
        remainingSessionMinutes = 0

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

    func formattedRemainingTime() -> String {
        if remainingSessionMinutes >= 60 {
            let hours = remainingSessionMinutes / 60
            let minutes = remainingSessionMinutes % 60
            return "\(hours)h \(minutes)m"
        } else {
            return "\(remainingSessionMinutes)m"
        }
    }

    // MARK: - Timer Management

    private func startSessionTimer() {
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            if self.remainingSessionMinutes > 0 {
                self.remainingSessionMinutes -= 1

                // Update Live Activity
                if #available(iOS 16.1, *) {
                    self.updateLiveActivity(
                        remainingMinutes: self.remainingSessionMinutes,
                        totalMinutes: self.activeSessionMinutes
                    )
                }

                // End session when time runs out
                if self.remainingSessionMinutes <= 0 {
                    self.endScreenTimeSession()
                }
            }
        }
    }

    private func stopSessionTimer() {
        sessionTimer?.invalidate()
        sessionTimer = nil
    }

    // MARK: - Live Activity Management

    @available(iOS 16.1, *)
    private func startLiveActivity(durationMinutes: Int, sessionType: String = "Screen Time") {
        // Check if Live Activities are supported and enabled
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("❌ Live Activities are not enabled")
            return
        }

        // End any existing activity first
        endLiveActivity()

        let attributes = ScreenTimeActivityAttributes(sessionType: sessionType)
        let contentState = ScreenTimeActivityAttributes.ContentState(
            remainingMinutes: durationMinutes,
            totalMinutes: durationMinutes,
            sessionStartTime: Date()
        )

        do {
            let activity = try Activity<ScreenTimeActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
            print("✅ Live Activity started successfully")
        } catch {
            print("❌ Error starting Live Activity: \(error)")
        }
    }

    @available(iOS 16.1, *)
    private func updateLiveActivity(remainingMinutes: Int, totalMinutes: Int) {
        guard let activity = currentActivity as? Activity<ScreenTimeActivityAttributes> else {
            print("❌ No active Live Activity to update")
            return
        }

        let updatedState = ScreenTimeActivityAttributes.ContentState(
            remainingMinutes: remainingMinutes,
            totalMinutes: totalMinutes,
            sessionStartTime: activity.content.state.sessionStartTime
        )

        Task {
            await activity.update(.init(state: updatedState, staleDate: nil))
            print("✅ Live Activity updated: \(remainingMinutes) minutes remaining")
        }
    }

    @available(iOS 16.1, *)
    private func endLiveActivity() {
        guard let activity = currentActivity as? Activity<ScreenTimeActivityAttributes> else {
            return
        }

        Task {
            await activity.end(.init(state: activity.content.state, staleDate: nil), dismissalPolicy: .immediate)
            print("✅ Live Activity ended")
        }

        currentActivity = nil
    }
}