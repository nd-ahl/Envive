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
    private let earnedMinutesKeyPrefix = "earnedScreenTimeMinutes_"
    private let activeSessionKeyPrefix = "activeScreenTimeSession_"
    private let sessionStartTimeKeyPrefix = "sessionStartTime_"
    private let sessionDurationKeyPrefix = "sessionDuration_"

    // Child ID for data isolation
    private var childId: UUID?

    // XP Service for syncing with task rewards
    private let xpService: XPService?
    private let credibilityService: CredibilityService?

    init(
        credibilityManager: CredibilityManager = CredibilityManager(),
        childId: UUID? = nil,
        xpService: XPService? = nil,
        credibilityService: CredibilityService? = nil
    ) {
        self.credibilityManager = credibilityManager
        self.childId = childId
        self.xpService = xpService
        self.credibilityService = credibilityService
        loadEarnedMinutes()
        restoreActiveSession()
    }

    /// Set the child ID for data isolation (must be called when switching children)
    func setChildId(_ id: UUID) {
        childId = id
        loadEarnedMinutes()
    }

    /// Get the storage key for the current child
    private func earnedMinutesKey() -> String {
        guard let childId = childId else {
            // Fallback to global key if no child ID is set (backward compatibility)
            return "earnedScreenTimeMinutes"
        }
        return "\(earnedMinutesKeyPrefix)\(childId.uuidString)"
    }

    private func activeSessionKey() -> String {
        guard let childId = childId else {
            return "activeScreenTimeSession"
        }
        return "\(activeSessionKeyPrefix)\(childId.uuidString)"
    }

    private func sessionStartTimeKey() -> String {
        guard let childId = childId else {
            return "sessionStartTime"
        }
        return "\(sessionStartTimeKeyPrefix)\(childId.uuidString)"
    }

    private func sessionDurationKey() -> String {
        guard let childId = childId else {
            return "sessionDuration"
        }
        return "\(sessionDurationKeyPrefix)\(childId.uuidString)"
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

            // Deduct from XPService if available (source of truth)
            if let childId = self.childId,
               let xpService = self.xpService,
               let credibilityService = self.credibilityService {
                let credibility = credibilityService.getCredibilityScore(childId: childId)
                let result = xpService.redeemXP(amount: durationMinutes, userId: childId, credibilityScore: credibility)

                switch result {
                case .success(let redemption):
                    print("💳 Deducted \(durationMinutes) XP from XPService for screen time session (New balance: \(redemption.newBalance))")
                    // Update local earned minutes to match XPService
                    self.earnedMinutes -= durationMinutes
                    self.saveEarnedMinutes()
                case .failure(let error):
                    print("❌ Failed to deduct from XPService: \(error)")
                    // Don't start session if XP deduction failed
                    self.isScreenTimeActive = false
                    self.activeSessionMinutes = 0
                    self.remainingSessionMinutes = 0
                    return
                }
            } else {
                // Fallback: deduct from local storage only (for backward compatibility)
                self.earnedMinutes -= durationMinutes
                self.saveEarnedMinutes()
            }

            // Start the device activity session (this will trigger the monitor extension to unblock apps)
            self.scheduler.startScreenTimeSession(durationMinutes: durationMinutes)

            // Start Live Activity for Dynamic Island
            if #available(iOS 16.1, *) {
                self.startLiveActivity(durationMinutes: durationMinutes)
            }

            // Persist session state
            self.saveSessionState(startTime: Date(), duration: durationMinutes)

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
        // Calculate actual minutes used
        let minutesUsed = activeSessionMinutes - remainingSessionMinutes

        // CRITICAL: Do NOT refund unused time
        // The XP was already deducted upfront when starting the session
        // Time spent is time spent, regardless of whether the full session completed
        print("📊 Session ended: \(minutesUsed) minutes used out of \(activeSessionMinutes) requested")

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

        // Clear persisted session state
        clearSessionState()

        // Sync earned minutes from XPService to ensure UI shows correct balance
        syncFromXPService()

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
        userDefaults.set(earnedMinutes, forKey: earnedMinutesKey())
        print("💾 Saved \(earnedMinutes) earned minutes for child: \(childId?.uuidString ?? "global")")
    }

    private func loadEarnedMinutes() {
        // Try to sync from XPService if available
        if let childId = childId,
           let xpService = xpService,
           let credibilityService = credibilityService {
            syncFromXPService()
        } else {
            // Fall back to UserDefaults storage
            earnedMinutes = userDefaults.integer(forKey: earnedMinutesKey())
            print("📂 Loaded \(earnedMinutes) earned minutes from UserDefaults for child: \(childId?.uuidString ?? "global")")
        }
    }

    /// Sync earned minutes from XPService
    /// This ensures screen time balance matches the XP earned from tasks
    /// CRITICAL: Uses 1:1 conversion (1 XP = 1 minute) to prevent time restoration exploit
    func syncFromXPService() {
        guard let childId = childId,
              let xpService = xpService,
              let credibilityService = credibilityService else {
            print("⚠️ Cannot sync from XPService - missing required services")
            return
        }

        // Get raw XP from XPService
        let rawXP: Int
        if let balance = xpService.getBalance(userId: childId) {
            rawXP = balance.currentXP
        } else {
            rawXP = 0
        }

        // CRITICAL FIX: Use 1:1 conversion for screen time (1 XP = 1 minute, always)
        // Do NOT apply credibility multiplier here - that only affects earning XP from tasks
        // If we used credibility multiplier, changing credibility would change available screen time
        // which would allow exploits where spent time gets "restored" when credibility changes
        let minutesFromXP = rawXP  // Direct 1:1 mapping

        // Update earned minutes
        earnedMinutes = minutesFromXP
        saveEarnedMinutes()

        print("🔄 Synced from XPService: \(rawXP) XP → \(minutesFromXP) minutes (1:1 conversion) for child: \(childId)")
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

    // MARK: - Session State Persistence

    /// Save active session state to UserDefaults
    private func saveSessionState(startTime: Date, duration: Int) {
        userDefaults.set(true, forKey: activeSessionKey())
        userDefaults.set(startTime.timeIntervalSince1970, forKey: sessionStartTimeKey())
        userDefaults.set(duration, forKey: sessionDurationKey())
        print("💾 Saved active session state: duration=\(duration)min, start=\(startTime)")
    }

    /// Clear session state from UserDefaults
    private func clearSessionState() {
        userDefaults.removeObject(forKey: activeSessionKey())
        userDefaults.removeObject(forKey: sessionStartTimeKey())
        userDefaults.removeObject(forKey: sessionDurationKey())
        print("🗑️ Cleared session state")
    }

    /// Restore active session from UserDefaults if app was restarted mid-session
    private func restoreActiveSession() {
        guard userDefaults.bool(forKey: activeSessionKey()) else {
            print("📂 No active session to restore")
            return
        }

        guard let startTimeInterval = userDefaults.object(forKey: sessionStartTimeKey()) as? TimeInterval else {
            print("⚠️ Could not restore session: missing start time")
            clearSessionState()
            return
        }

        let duration = userDefaults.integer(forKey: sessionDurationKey())
        guard duration > 0 else {
            print("⚠️ Could not restore session: invalid duration")
            clearSessionState()
            return
        }

        let startTime = Date(timeIntervalSince1970: startTimeInterval)
        let elapsedMinutes = Int(Date().timeIntervalSince(startTime) / 60)
        let remaining = max(0, duration - elapsedMinutes)

        print("🔄 Restoring session: duration=\(duration)min, elapsed=\(elapsedMinutes)min, remaining=\(remaining)min")

        if remaining > 0 {
            // Session still active - restore it
            isScreenTimeActive = true
            activeSessionMinutes = duration
            remainingSessionMinutes = remaining

            // Restart the scheduler and timer
            scheduler.startScreenTimeSession(durationMinutes: remaining)
            startSessionTimer()

            // Restart Live Activity if available
            if #available(iOS 16.1, *) {
                startLiveActivity(durationMinutes: remaining)
            }

            print("✅ Restored active screen time session with \(remaining) minutes remaining")
        } else {
            // Session has expired while app was closed
            // The session ran to completion naturally, so no refund needed
            print("⏰ Session expired while app was closed - session completed naturally")

            // Clean up session state without refund (time was fully used)
            isScreenTimeActive = false
            activeSessionMinutes = 0
            remainingSessionMinutes = 0
            clearSessionState()

            // Re-apply restrictions
            if appSelectionStore.hasSelectedApps {
                settingsManager.blockApps(appSelectionStore.familyActivitySelection)
            }
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