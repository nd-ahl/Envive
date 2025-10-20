import Foundation
import Combine

final class CredibilityServiceImpl: CredibilityService {
    private let repository: CredibilityRepository
    private let calculator: CredibilityCalculator
    private let tierProvider: CredibilityTierProvider

    private let redemptionBonusThreshold = 95
    private let redemptionBonusPreviousThreshold = 60
    private let redemptionBonusMultiplier = 1.3
    private let redemptionBonusDays = 7

    init(
        storage: StorageService,
        calculator: CredibilityCalculator,
        tierProvider: CredibilityTierProvider
    ) {
        self.repository = CredibilityRepository(storage: storage)
        self.calculator = calculator
        self.tierProvider = tierProvider
    }

    // MARK: - Per-Child Data Access

    func getCredibilityScore(childId: UUID) -> Int {
        repository.loadScore(childId: childId)
    }

    func getCredibilityHistory(childId: UUID) -> [CredibilityHistoryEvent] {
        repository.loadHistory(childId: childId)
    }

    func getConsecutiveApprovedTasks(childId: UUID) -> Int {
        repository.loadConsecutiveTasks(childId: childId)
    }

    func getHasRedemptionBonus(childId: UUID) -> Bool {
        repository.loadRedemptionBonus(childId: childId).active
    }

    func getRedemptionBonusExpiry(childId: UUID) -> Date? {
        repository.loadRedemptionBonus(childId: childId).expiry
    }

    func getLastTaskUploadDate(childId: UUID) -> Date? {
        repository.loadLastUploadDate(childId: childId)
    }

    func getDailyStreak(childId: UUID) -> Int {
        repository.loadDailyStreak(childId: childId)
    }

    func processDownvote(taskId: UUID, childId: UUID, reviewerId: UUID, notes: String? = nil) {
        var credibilityHistory = repository.loadHistory(childId: childId)
        var credibilityScore = repository.loadScore(childId: childId)
        var consecutiveApprovedTasks = repository.loadConsecutiveTasks(childId: childId)
        let bonus = repository.loadRedemptionBonus(childId: childId)
        var hasRedemptionBonus = bonus.active

        let lastDownvote = credibilityHistory
            .filter { $0.event == .downvote }
            .sorted { $0.timestamp > $1.timestamp }
            .first

        let penalty = calculator.calculateDownvotePenalty(lastDownvoteDate: lastDownvote?.timestamp)
        let previousScore = credibilityScore

        credibilityScore = calculator.clampScore(credibilityScore + penalty)
        consecutiveApprovedTasks = 0
        // NOTE: Daily streak is NOT reset on downvote - only resets after 24 hours without upload

        let event = CredibilityHistoryEvent(
            event: .downvote,
            amount: penalty,
            taskId: taskId,
            reviewerId: reviewerId,
            notes: notes,
            newScore: credibilityScore
        )
        credibilityHistory.append(event)

        if hasRedemptionBonus && credibilityScore < redemptionBonusThreshold {
            hasRedemptionBonus = false
            repository.saveRedemptionBonus(active: false, expiry: nil, childId: childId)

            let bonusEvent = CredibilityHistoryEvent(
                event: .redemptionBonusExpired,
                amount: 0,
                newScore: credibilityScore
            )
            credibilityHistory.append(bonusEvent)
        }

        repository.saveScore(credibilityScore, childId: childId)
        repository.saveHistory(credibilityHistory, childId: childId)
        repository.saveConsecutiveTasks(consecutiveApprovedTasks, childId: childId)

        print("💔 Downvote (child: \(childId)): \(penalty) points. Score: \(previousScore) → \(credibilityScore)")
    }

    func undoDownvote(taskId: UUID, childId: UUID, reviewerId: UUID) {
        var credibilityHistory = repository.loadHistory(childId: childId)
        var credibilityScore = repository.loadScore(childId: childId)

        guard let index = credibilityHistory.lastIndex(where: {
            $0.event == .downvote && $0.taskId == taskId && $0.reviewerId == reviewerId
        }) else {
            print("⚠️ No downvote found to undo for child: \(childId)")
            return
        }

        let downvote = credibilityHistory[index]
        let restored = abs(downvote.amount)
        let previousScore = credibilityScore

        credibilityScore = calculator.clampScore(credibilityScore + restored)

        let undoEvent = CredibilityHistoryEvent(
            event: .downvoteUndone,
            amount: restored,
            taskId: taskId,
            reviewerId: reviewerId,
            notes: "Downvote removed",
            newScore: credibilityScore
        )
        credibilityHistory.append(undoEvent)

        repository.saveScore(credibilityScore, childId: childId)
        repository.saveHistory(credibilityHistory, childId: childId)

        print("↩️ Downvote undone (child: \(childId)): +\(restored) points. Score: \(previousScore) → \(credibilityScore)")
    }

    func processApprovedTask(taskId: UUID, childId: UUID, reviewerId: UUID, notes: String? = nil) {
        var credibilityHistory = repository.loadHistory(childId: childId)
        var credibilityScore = repository.loadScore(childId: childId)
        var consecutiveApprovedTasks = repository.loadConsecutiveTasks(childId: childId)
        let bonus = repository.loadRedemptionBonus(childId: childId)
        var hasRedemptionBonus = bonus.active
        var redemptionBonusExpiry = bonus.expiry

        let previousScore = credibilityScore
        let config = CredibilityCalculationConfig()

        credibilityScore = calculator.clampScore(credibilityScore + config.approvedTaskBonus)
        consecutiveApprovedTasks += 1

        let event = CredibilityHistoryEvent(
            event: .approvedTask,
            amount: config.approvedTaskBonus,
            taskId: taskId,
            reviewerId: reviewerId,
            notes: notes,
            newScore: credibilityScore
        )
        credibilityHistory.append(event)

        if calculator.shouldAwardStreakBonus(consecutiveTasks: consecutiveApprovedTasks) {
            // Apply streak bonus
            credibilityScore = calculator.clampScore(credibilityScore + config.streakBonusAmount)

            let streakEvent = CredibilityHistoryEvent(
                event: .streakBonus,
                amount: config.streakBonusAmount,
                newScore: credibilityScore,
                streakCount: consecutiveApprovedTasks
            )
            credibilityHistory.append(streakEvent)
            print("🔥 Streak bonus (child: \(childId))! \(consecutiveApprovedTasks) tasks. +\(config.streakBonusAmount)")
        }

        if !hasRedemptionBonus &&
           credibilityScore >= redemptionBonusThreshold &&
           previousScore < redemptionBonusPreviousThreshold {
            // Activate redemption bonus
            hasRedemptionBonus = true
            redemptionBonusExpiry = Calendar.current.date(
                byAdding: .day,
                value: redemptionBonusDays,
                to: Date()
            )

            let bonusEvent = CredibilityHistoryEvent(
                event: .redemptionBonusActivated,
                amount: 0,
                newScore: credibilityScore
            )
            credibilityHistory.append(bonusEvent)
            print("⭐️ Redemption bonus activated (child: \(childId))! 1.3x for \(redemptionBonusDays) days")
        }

        repository.saveScore(credibilityScore, childId: childId)
        repository.saveHistory(credibilityHistory, childId: childId)
        repository.saveConsecutiveTasks(consecutiveApprovedTasks, childId: childId)
        repository.saveRedemptionBonus(active: hasRedemptionBonus, expiry: redemptionBonusExpiry, childId: childId)

        print("✅ Approved (child: \(childId)): +\(config.approvedTaskBonus). Score: \(previousScore) → \(credibilityScore)")
    }

    func calculateXPToMinutes(xpAmount: Int, childId: UUID) -> Int {
        let tier = getCurrentTier(childId: childId)
        let hasBonus = repository.loadRedemptionBonus(childId: childId).active
        let multiplier = tier.multiplier * (hasBonus ? redemptionBonusMultiplier : 1.0)
        return Int((Double(xpAmount) * multiplier).rounded())
    }

    func getConversionRate(childId: UUID) -> Double {
        let tier = getCurrentTier(childId: childId)
        let hasBonus = repository.loadRedemptionBonus(childId: childId).active
        return tier.multiplier * (hasBonus ? redemptionBonusMultiplier : 1.0)
    }

    func getCurrentTier(childId: UUID) -> CredibilityTier {
        let score = repository.loadScore(childId: childId)
        return tierProvider.getTier(for: score)
    }

    func getCredibilityStatus(childId: UUID) -> CredibilityStatus {
        let score = repository.loadScore(childId: childId)
        let history = repository.loadHistory(childId: childId)
        let consecutiveTasks = repository.loadConsecutiveTasks(childId: childId)
        let streak = repository.loadDailyStreak(childId: childId)
        let bonus = repository.loadRedemptionBonus(childId: childId)

        let tier = tierProvider.getTier(for: score)
        let recoveryPath = calculateRecoveryPath(childId: childId)

        return CredibilityStatus(
            score: score,
            tier: tier,
            consecutiveApprovedTasks: consecutiveTasks,
            dailyStreak: streak,
            hasRedemptionBonus: bonus.active,
            redemptionBonusExpiry: bonus.expiry,
            history: history,
            conversionRate: getConversionRate(childId: childId),
            recoveryPath: recoveryPath
        )
    }

    func applyTimeBasedDecay(childId: UUID) {
        var credibilityHistory = repository.loadHistory(childId: childId)
        var credibilityScore = repository.loadScore(childId: childId)

        let recovery = calculator.calculateDecayRecovery(for: credibilityHistory, currentDate: Date())

        guard recovery > 0 else { return }

        credibilityScore = calculator.clampScore(credibilityScore + recovery)

        let event = CredibilityHistoryEvent(
            event: .timeDecayRecovery,
            amount: recovery,
            newScore: credibilityScore
        )
        credibilityHistory.append(event)

        repository.saveScore(credibilityScore, childId: childId)
        repository.saveHistory(credibilityHistory, childId: childId)

        print("🔄 Time decay (child: \(childId)): +\(recovery) points. New score: \(credibilityScore)")
    }

    // MARK: - Private Helpers

    private func calculateRecoveryPath(childId: UUID) -> String? {
        let score = repository.loadScore(childId: childId)
        let currentTier = tierProvider.getTier(for: score)
        guard let nextTier = tierProvider.nextTier(above: score) else {
            return nil
        }

        let config = CredibilityCalculationConfig()
        let pointsNeeded = nextTier.range.lowerBound - score
        let tasksNeeded = (pointsNeeded + config.approvedTaskBonus - 1) / config.approvedTaskBonus

        return "Complete \(tasksNeeded) approved tasks to reach \(nextTier.name) status"
    }

    // MARK: - Daily Streak Management

    func processTaskUpload(taskId: UUID, childId: UUID) {
        var dailyStreak = repository.loadDailyStreak(childId: childId)
        let lastTaskUploadDate = repository.loadLastUploadDate(childId: childId)

        let now = Date()
        let calendar = Calendar.current

        // Check if this is the first upload today
        if let lastUpload = lastTaskUploadDate {
            if calendar.isDateInToday(lastUpload) {
                // Already uploaded today - no streak change
                print("📤 Task uploaded (child: \(childId), already counted today). Streak: \(dailyStreak)")
                return
            }

            // Check if this is the next day (consecutive)
            if calendar.isDateInYesterday(lastUpload) {
                // Consecutive day! Increment streak
                dailyStreak += 1
                print("🔥 Daily streak increased (child: \(childId))! \(dailyStreak) days")

                // Check for streak bonus every 10 days
                if dailyStreak % 10 == 0 {
                    var credibilityScore = repository.loadScore(childId: childId)
                    var credibilityHistory = repository.loadHistory(childId: childId)
                    let config = CredibilityCalculationConfig()

                    credibilityScore = calculator.clampScore(credibilityScore + config.streakBonusAmount)

                    let streakEvent = CredibilityHistoryEvent(
                        event: .streakBonus,
                        amount: config.streakBonusAmount,
                        newScore: credibilityScore,
                        streakCount: dailyStreak
                    )
                    credibilityHistory.append(streakEvent)

                    repository.saveScore(credibilityScore, childId: childId)
                    repository.saveHistory(credibilityHistory, childId: childId)

                    print("🔥 Streak bonus (child: \(childId))! \(dailyStreak) days. +\(config.streakBonusAmount)")
                }
            } else {
                // More than 24 hours passed - reset streak
                dailyStreak = 1
                print("💔 Streak broken (child: \(childId)). Starting fresh at 1 day")
            }
        } else {
            // First ever upload
            dailyStreak = 1
            print("🎉 First daily task (child: \(childId))! Streak: 1 day")
        }

        repository.saveLastUploadDate(now, childId: childId)
        repository.saveDailyStreak(dailyStreak, childId: childId)
    }
}
