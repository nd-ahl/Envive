import Foundation
import Combine

final class CredibilityServiceImpl: ObservableObject, CredibilityService {
    @Published private(set) var credibilityScore: Int
    @Published private(set) var credibilityHistory: [CredibilityHistoryEvent]
    @Published private(set) var consecutiveApprovedTasks: Int
    @Published private(set) var hasRedemptionBonus: Bool
    @Published private(set) var redemptionBonusExpiry: Date?

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

        // Load persisted state
        self.credibilityScore = repository.loadScore()
        self.credibilityHistory = repository.loadHistory()
        self.consecutiveApprovedTasks = repository.loadConsecutiveTasks()

        let bonus = repository.loadRedemptionBonus()
        self.hasRedemptionBonus = bonus.active
        self.redemptionBonusExpiry = bonus.expiry

        checkRedemptionBonusExpiry()
    }

    func processDownvote(taskId: UUID, reviewerId: UUID, notes: String? = nil) {
        let lastDownvote = credibilityHistory
            .filter { $0.event == .downvote }
            .sorted { $0.timestamp > $1.timestamp }
            .first

        let penalty = calculator.calculateDownvotePenalty(lastDownvoteDate: lastDownvote?.timestamp)
        let previousScore = credibilityScore

        credibilityScore = calculator.clampScore(credibilityScore + penalty)
        consecutiveApprovedTasks = 0

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
            deactivateRedemptionBonus()
        }

        persistState()
        print("💔 Downvote: \(penalty) points. Score: \(previousScore) → \(credibilityScore)")
    }

    func undoDownvote(taskId: UUID, reviewerId: UUID) {
        guard let index = credibilityHistory.lastIndex(where: {
            $0.event == .downvote && $0.taskId == taskId && $0.reviewerId == reviewerId
        }) else {
            print("⚠️ No downvote found to undo")
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

        persistState()
        print("↩️ Downvote undone: +\(restored) points. Score: \(previousScore) → \(credibilityScore)")
    }

    func processApprovedTask(taskId: UUID, reviewerId: UUID, notes: String? = nil) {
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
            applyStreakBonus()
        }

        if !hasRedemptionBonus &&
           credibilityScore >= redemptionBonusThreshold &&
           previousScore < redemptionBonusPreviousThreshold {
            activateRedemptionBonus()
        }

        persistState()
        print("✅ Approved: +\(config.approvedTaskBonus). Score: \(previousScore) → \(credibilityScore)")
    }

    func calculateXPToMinutes(xpAmount: Int) -> Int {
        let tier = getCurrentTier()
        let multiplier = tier.multiplier * (hasRedemptionBonus ? redemptionBonusMultiplier : 1.0)
        return Int((Double(xpAmount) * multiplier).rounded())
    }

    func getConversionRate() -> Double {
        let tier = getCurrentTier()
        return tier.multiplier * (hasRedemptionBonus ? redemptionBonusMultiplier : 1.0)
    }

    func getCurrentTier() -> CredibilityTier {
        tierProvider.getTier(for: credibilityScore)
    }

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

    func applyTimeBasedDecay() {
        let recovery = calculator.calculateDecayRecovery(for: credibilityHistory, currentDate: Date())

        guard recovery > 0 else { return }

        credibilityScore = calculator.clampScore(credibilityScore + recovery)

        let event = CredibilityHistoryEvent(
            event: .timeDecayRecovery,
            amount: recovery,
            newScore: credibilityScore
        )
        credibilityHistory.append(event)

        persistState()
        print("🔄 Time decay: +\(recovery) points. New score: \(credibilityScore)")
    }

    // MARK: - Private

    private func applyStreakBonus() {
        let config = CredibilityCalculationConfig()
        let previousScore = credibilityScore

        credibilityScore = calculator.clampScore(credibilityScore + config.streakBonusAmount)

        let event = CredibilityHistoryEvent(
            event: .streakBonus,
            amount: config.streakBonusAmount,
            newScore: credibilityScore,
            streakCount: consecutiveApprovedTasks
        )
        credibilityHistory.append(event)

        print("🔥 Streak bonus! \(consecutiveApprovedTasks) tasks. +\(config.streakBonusAmount)")
    }

    private func activateRedemptionBonus() {
        hasRedemptionBonus = true
        redemptionBonusExpiry = Calendar.current.date(
            byAdding: .day,
            value: redemptionBonusDays,
            to: Date()
        )

        let event = CredibilityHistoryEvent(
            event: .redemptionBonusActivated,
            amount: 0,
            newScore: credibilityScore
        )
        credibilityHistory.append(event)

        print("⭐️ Redemption bonus activated! 1.3x for \(redemptionBonusDays) days")
    }

    private func deactivateRedemptionBonus() {
        hasRedemptionBonus = false
        redemptionBonusExpiry = nil

        let event = CredibilityHistoryEvent(
            event: .redemptionBonusExpired,
            amount: 0,
            newScore: credibilityScore
        )
        credibilityHistory.append(event)
    }

    private func checkRedemptionBonusExpiry() {
        guard hasRedemptionBonus,
              let expiry = redemptionBonusExpiry,
              Date() > expiry else { return }

        deactivateRedemptionBonus()
        persistState()
    }

    private func calculateRecoveryPath() -> String? {
        let currentTier = getCurrentTier()
        guard let nextTier = tierProvider.nextTier(above: credibilityScore) else {
            return nil
        }

        let config = CredibilityCalculationConfig()
        let pointsNeeded = nextTier.range.lowerBound - credibilityScore
        let tasksNeeded = (pointsNeeded + config.approvedTaskBonus - 1) / config.approvedTaskBonus

        return "Complete \(tasksNeeded) approved tasks to reach \(nextTier.name) status"
    }

    private func persistState() {
        repository.saveScore(credibilityScore)
        repository.saveHistory(credibilityHistory)
        repository.saveConsecutiveTasks(consecutiveApprovedTasks)
        repository.saveRedemptionBonus(active: hasRedemptionBonus, expiry: redemptionBonusExpiry)
    }
}
