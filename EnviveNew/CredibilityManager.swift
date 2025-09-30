import Foundation
import Combine

// MARK: - Credibility Data Models

struct CredibilityHistoryEvent: Codable, Identifiable, Hashable {
    let id: UUID
    let event: CredibilityEventType
    let amount: Int
    let timestamp: Date
    let taskId: UUID?
    let reviewerId: UUID?
    let notes: String?
    let newScore: Int
    let streakCount: Int?
    let decayed: Bool?
    let decayDate: Date?

    init(
        id: UUID = UUID(),
        event: CredibilityEventType,
        amount: Int,
        timestamp: Date = Date(),
        taskId: UUID? = nil,
        reviewerId: UUID? = nil,
        notes: String? = nil,
        newScore: Int,
        streakCount: Int? = nil,
        decayed: Bool? = nil,
        decayDate: Date? = nil
    ) {
        self.id = id
        self.event = event
        self.amount = amount
        self.timestamp = timestamp
        self.taskId = taskId
        self.reviewerId = reviewerId
        self.notes = notes
        self.newScore = newScore
        self.streakCount = streakCount
        self.decayed = decayed
        self.decayDate = decayDate
    }
}

enum CredibilityEventType: String, Codable {
    case downvote = "downvote"
    case downvoteUndone = "downvote_undone"
    case approvedTask = "approved_task"
    case streakBonus = "streak_bonus"
    case timeDecayRecovery = "time_decay_recovery"
    case redemptionBonusActivated = "redemption_bonus_activated"
    case redemptionBonusExpired = "redemption_bonus_expired"
}

struct CredibilityTier: Identifiable {
    let id = UUID()
    let name: String
    let range: ClosedRange<Int>
    let multiplier: Double
    let color: String
    let description: String
}

struct CredibilityStatus {
    let score: Int
    let tier: CredibilityTier
    let consecutiveApprovedTasks: Int
    let hasRedemptionBonus: Bool
    let redemptionBonusExpiry: Date?
    let history: [CredibilityHistoryEvent]
    let conversionRate: Double
    let recoveryPath: String?
}

// MARK: - Credibility Manager

class CredibilityManager: ObservableObject {
    // MARK: - Published Properties

    @Published var credibilityScore: Int = 100
    @Published var credibilityHistory: [CredibilityHistoryEvent] = []
    @Published var consecutiveApprovedTasks: Int = 0
    @Published var hasRedemptionBonus: Bool = false
    @Published var redemptionBonusExpiry: Date?

    // MARK: - Constants

    private let minimumScore = 0
    private let maximumScore = 100
    private let defaultScore = 100

    // Penalty constants
    private let singleDownvotePenalty = -10
    private let stackedDownvotePenalty = -15
    private let stackingWindowDays = 7

    // Recovery constants
    private let approvedTaskBonus = 2
    private let streakBonusAmount = 5
    private let streakBonusInterval = 10

    // Decay constants
    private let halfDecayDays = 30
    private let fullDecayDays = 60

    // Redemption bonus constants
    private let redemptionBonusThreshold = 95
    private let redemptionBonusPreviousThreshold = 60
    private let redemptionBonusMultiplier = 1.3
    private let redemptionBonusDays = 7

    // MARK: - Tiers

    private let tiers: [CredibilityTier] = [
        CredibilityTier(
            name: "Excellent",
            range: 90...100,
            multiplier: 1.2,
            color: "green",
            description: "Outstanding credibility! Maximum conversion rate."
        ),
        CredibilityTier(
            name: "Good",
            range: 75...89,
            multiplier: 1.0,
            color: "green",
            description: "Good standing. Standard conversion rate."
        ),
        CredibilityTier(
            name: "Fair",
            range: 60...74,
            multiplier: 0.8,
            color: "yellow",
            description: "Fair standing. Reduced conversion rate."
        ),
        CredibilityTier(
            name: "Poor",
            range: 40...59,
            multiplier: 0.5,
            color: "red",
            description: "Poor standing. Significantly reduced rate."
        ),
        CredibilityTier(
            name: "Very Poor",
            range: 0...39,
            multiplier: 0.3,
            color: "red",
            description: "Very poor standing. Minimum conversion rate."
        )
    ]

    private let userDefaults = UserDefaults.standard
    private let credibilityScoreKey = "userCredibilityScore"
    private let credibilityHistoryKey = "userCredibilityHistory"
    private let consecutiveApprovedTasksKey = "consecutiveApprovedTasks"
    private let redemptionBonusKey = "hasRedemptionBonus"
    private let redemptionBonusExpiryKey = "redemptionBonusExpiry"

    // MARK: - Initialization

    init() {
        loadCredibilityData()
        checkRedemptionBonusExpiry()
    }

    // MARK: - Public Methods

    /// Process a downvote (task rejection) from a parent
    func processDownvote(taskId: UUID, reviewerId: UUID, notes: String? = nil) {
        let previousScore = credibilityScore
        let penalty = calculateDownvotePenalty()

        // Apply penalty
        credibilityScore = max(minimumScore, credibilityScore + penalty)

        // Reset streak
        consecutiveApprovedTasks = 0

        // Add to history
        let event = CredibilityHistoryEvent(
            event: .downvote,
            amount: penalty,
            timestamp: Date(),
            taskId: taskId,
            reviewerId: reviewerId,
            notes: notes,
            newScore: credibilityScore
        )
        credibilityHistory.append(event)

        // Check if redemption bonus should be lost
        if hasRedemptionBonus && credibilityScore < redemptionBonusThreshold {
            deactivateRedemptionBonus()
        }

        saveCredibilityData()

        print("💔 Downvote processed: \(penalty) points. Score: \(previousScore) → \(credibilityScore)")
    }

    /// Undo a downvote (when user removes their downvote)
    func undoDownvote(taskId: UUID, reviewerId: UUID) {
        // Find the most recent downvote for this task
        guard let downvoteIndex = credibilityHistory.lastIndex(where: {
            $0.event == .downvote && $0.taskId == taskId && $0.reviewerId == reviewerId
        }) else {
            print("⚠️ No downvote found to undo for task \(taskId)")
            return
        }

        let downvoteEvent = credibilityHistory[downvoteIndex]
        let penaltyAmount = downvoteEvent.amount // This is negative (e.g., -10 or -15)
        let restoredPoints = abs(penaltyAmount) // Convert to positive for restoration

        let previousScore = credibilityScore

        // Restore the points that were removed
        credibilityScore = min(maximumScore, credibilityScore + restoredPoints)

        // Add undo event to history
        let undoEvent = CredibilityHistoryEvent(
            event: .downvoteUndone,
            amount: restoredPoints,
            timestamp: Date(),
            taskId: taskId,
            reviewerId: reviewerId,
            notes: "Downvote removed",
            newScore: credibilityScore
        )
        credibilityHistory.append(undoEvent)

        saveCredibilityData()

        print("↩️ Downvote undone: +\(restoredPoints) points. Score: \(previousScore) → \(credibilityScore)")
    }

    /// Process an approved task from a parent
    func processApprovedTask(taskId: UUID, reviewerId: UUID, notes: String? = nil) {
        let previousScore = credibilityScore
        let previousStreak = consecutiveApprovedTasks

        // Apply bonus
        credibilityScore = min(maximumScore, credibilityScore + approvedTaskBonus)

        // Increment streak
        consecutiveApprovedTasks += 1

        // Add to history
        let event = CredibilityHistoryEvent(
            event: .approvedTask,
            amount: approvedTaskBonus,
            timestamp: Date(),
            taskId: taskId,
            reviewerId: reviewerId,
            notes: notes,
            newScore: credibilityScore
        )
        credibilityHistory.append(event)

        // Check for streak bonus
        if consecutiveApprovedTasks % streakBonusInterval == 0 {
            applyStreakBonus()
        }

        // Check for redemption bonus eligibility
        if !hasRedemptionBonus &&
           credibilityScore >= redemptionBonusThreshold &&
           previousScore < redemptionBonusPreviousThreshold {
            activateRedemptionBonus()
        }

        saveCredibilityData()

        print("✅ Approved task: +\(approvedTaskBonus) points. Score: \(previousScore) → \(credibilityScore), Streak: \(previousStreak) → \(consecutiveApprovedTasks)")
    }

    /// Calculate XP to minutes conversion based on current credibility
    func calculateXPToMinutes(xpAmount: Int) -> Int {
        let tier = getCurrentTier()
        let tierMultiplier = tier.multiplier
        let redemptionMultiplier = hasRedemptionBonus ? redemptionBonusMultiplier : 1.0

        let minutes = Double(xpAmount) * tierMultiplier * redemptionMultiplier
        return Int(minutes.rounded())
    }

    /// Get the current conversion rate (multiplier)
    func getConversionRate() -> Double {
        let tier = getCurrentTier()
        let redemptionMultiplier = hasRedemptionBonus ? redemptionBonusMultiplier : 1.0
        return tier.multiplier * redemptionMultiplier
    }

    /// Get current credibility tier
    func getCurrentTier() -> CredibilityTier {
        return tiers.first { $0.range.contains(credibilityScore) } ?? tiers.last!
    }

    /// Get comprehensive credibility status
    func getCredibilityStatus() -> CredibilityStatus {
        let tier = getCurrentTier()
        let recoveryPath = calculateRecoveryPath()

        return CredibilityStatus(
            score: credibilityScore,
            tier: tier,
            consecutiveApprovedTasks: consecutiveApprovedTasks,
            hasRedemptionBonus: hasRedemptionBonus,
            redemptionBonusExpiry: redemptionBonusExpiry,
            history: credibilityHistory,
            conversionRate: getConversionRate(),
            recoveryPath: recoveryPath
        )
    }

    /// Apply time-based decay to old downvotes
    func applyTimeBasedDecay() {
        var recoveryAmount = 0
        var newHistory: [CredibilityHistoryEvent] = []
        let now = Date()

        for var event in credibilityHistory {
            // Only process downvote events
            if event.event == .downvote {
                let daysSinceEvent = Calendar.current.dateComponents([.day], from: event.timestamp, to: now).day ?? 0

                // Full removal after 60 days
                if daysSinceEvent >= fullDecayDays {
                    recoveryAmount += abs(event.amount)
                    continue // Don't add to new history
                }
                // 50% weight reduction after 30 days (if not already decayed)
                else if daysSinceEvent >= halfDecayDays && event.decayed != true {
                    let halfRecovery = abs(event.amount) / 2
                    recoveryAmount += halfRecovery

                    // Mark as decayed
                    event = CredibilityHistoryEvent(
                        id: event.id,
                        event: event.event,
                        amount: event.amount,
                        timestamp: event.timestamp,
                        taskId: event.taskId,
                        reviewerId: event.reviewerId,
                        notes: event.notes,
                        newScore: event.newScore,
                        streakCount: event.streakCount,
                        decayed: true,
                        decayDate: now
                    )
                }
            }

            newHistory.append(event)
        }

        // Apply recovery if any
        if recoveryAmount > 0 {
            credibilityScore = min(maximumScore, credibilityScore + recoveryAmount)

            let recoveryEvent = CredibilityHistoryEvent(
                event: .timeDecayRecovery,
                amount: recoveryAmount,
                timestamp: now,
                newScore: credibilityScore
            )
            newHistory.append(recoveryEvent)

            print("🔄 Time decay applied: +\(recoveryAmount) points recovered. New score: \(credibilityScore)")
        }

        credibilityHistory = newHistory
        saveCredibilityData()
    }

    /// Get history events filtered by type
    func getHistoryByType(_ type: CredibilityEventType) -> [CredibilityHistoryEvent] {
        return credibilityHistory.filter { $0.event == type }
    }

    /// Get recent history (last N days)
    func getRecentHistory(days: Int = 30) -> [CredibilityHistoryEvent] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return credibilityHistory.filter { $0.timestamp >= cutoffDate }
    }

    // MARK: - Private Methods

    private func calculateDownvotePenalty() -> Int {
        // Find most recent downvote
        let recentDownvotes = credibilityHistory
            .filter { $0.event == .downvote }
            .sorted { $0.timestamp > $1.timestamp }

        guard let lastDownvote = recentDownvotes.first else {
            return singleDownvotePenalty
        }

        // Check if within stacking window
        let daysSinceLastDownvote = Calendar.current.dateComponents(
            [.day],
            from: lastDownvote.timestamp,
            to: Date()
        ).day ?? 0

        if daysSinceLastDownvote <= stackingWindowDays {
            return stackedDownvotePenalty
        } else {
            return singleDownvotePenalty
        }
    }

    private func applyStreakBonus() {
        let previousScore = credibilityScore
        credibilityScore = min(maximumScore, credibilityScore + streakBonusAmount)

        let event = CredibilityHistoryEvent(
            event: .streakBonus,
            amount: streakBonusAmount,
            timestamp: Date(),
            newScore: credibilityScore,
            streakCount: consecutiveApprovedTasks
        )
        credibilityHistory.append(event)

        print("🔥 Streak bonus! \(consecutiveApprovedTasks) consecutive tasks. +\(streakBonusAmount) points. Score: \(previousScore) → \(credibilityScore)")
    }

    private func activateRedemptionBonus() {
        hasRedemptionBonus = true
        redemptionBonusExpiry = Calendar.current.date(byAdding: .day, value: redemptionBonusDays, to: Date())

        let event = CredibilityHistoryEvent(
            event: .redemptionBonusActivated,
            amount: 0,
            timestamp: Date(),
            newScore: credibilityScore
        )
        credibilityHistory.append(event)

        print("⭐️ Redemption bonus activated! 1.3x multiplier for \(redemptionBonusDays) days")
    }

    private func deactivateRedemptionBonus() {
        hasRedemptionBonus = false
        redemptionBonusExpiry = nil

        let event = CredibilityHistoryEvent(
            event: .redemptionBonusExpired,
            amount: 0,
            timestamp: Date(),
            newScore: credibilityScore
        )
        credibilityHistory.append(event)

        print("❌ Redemption bonus expired")
    }

    private func checkRedemptionBonusExpiry() {
        guard hasRedemptionBonus,
              let expiry = redemptionBonusExpiry,
              Date() > expiry else {
            return
        }

        deactivateRedemptionBonus()
        saveCredibilityData()
    }

    private func calculateRecoveryPath() -> String? {
        let currentTier = getCurrentTier()

        // If at maximum tier, no recovery needed
        if currentTier.name == "Excellent" && credibilityScore == maximumScore {
            return nil
        }

        // Find next tier
        let sortedTiers = tiers.sorted { $0.range.lowerBound > $1.range.lowerBound }
        guard let nextTier = sortedTiers.first(where: { $0.range.lowerBound > credibilityScore }) else {
            return nil
        }

        let pointsNeeded = nextTier.range.lowerBound - credibilityScore
        let tasksNeeded = (pointsNeeded + approvedTaskBonus - 1) / approvedTaskBonus // Round up

        return "Complete \(tasksNeeded) approved tasks to reach \(nextTier.name) status"
    }

    // MARK: - Persistence

    private func saveCredibilityData() {
        userDefaults.set(credibilityScore, forKey: credibilityScoreKey)
        userDefaults.set(consecutiveApprovedTasks, forKey: consecutiveApprovedTasksKey)
        userDefaults.set(hasRedemptionBonus, forKey: redemptionBonusKey)

        if let expiry = redemptionBonusExpiry {
            userDefaults.set(expiry, forKey: redemptionBonusExpiryKey)
        } else {
            userDefaults.removeObject(forKey: redemptionBonusExpiryKey)
        }

        // Save history as JSON
        if let historyData = try? JSONEncoder().encode(credibilityHistory) {
            userDefaults.set(historyData, forKey: credibilityHistoryKey)
        }
    }

    private func loadCredibilityData() {
        credibilityScore = userDefaults.integer(forKey: credibilityScoreKey)
        if credibilityScore == 0 {
            credibilityScore = defaultScore
        }

        consecutiveApprovedTasks = userDefaults.integer(forKey: consecutiveApprovedTasksKey)
        hasRedemptionBonus = userDefaults.bool(forKey: redemptionBonusKey)
        redemptionBonusExpiry = userDefaults.object(forKey: redemptionBonusExpiryKey) as? Date

        // Load history from JSON
        if let historyData = userDefaults.data(forKey: credibilityHistoryKey),
           let history = try? JSONDecoder().decode([CredibilityHistoryEvent].self, from: historyData) {
            credibilityHistory = history
        }
    }

    // MARK: - Utility Methods

    /// Format score with color coding
    func getScoreColor() -> String {
        let tier = getCurrentTier()
        return tier.color
    }

    /// Get formatted conversion rate display
    func getFormattedConversionRate() -> String {
        let rate = getConversionRate()
        return String(format: "%.1fx", rate)
    }

    /// Reset credibility (for testing/debugging)
    func resetCredibility() {
        credibilityScore = defaultScore
        credibilityHistory = []
        consecutiveApprovedTasks = 0
        hasRedemptionBonus = false
        redemptionBonusExpiry = nil
        saveCredibilityData()
        print("🔄 Credibility reset to default")
    }
}