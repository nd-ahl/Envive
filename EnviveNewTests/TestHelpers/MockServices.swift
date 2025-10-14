import Foundation
import FamilyControls
@testable import EnviveNew

// MARK: - Mock Credibility Service

final class MockCredibilityService: CredibilityService {
    var credibilityScore: Int = 100
    var credibilityHistory: [CredibilityHistoryEvent] = []
    var consecutiveApprovedTasks: Int = 0
    var hasRedemptionBonus: Bool = false
    var redemptionBonusExpiry: Date?

    var processDownvoteCalled = false
    var processApprovedTaskCalled = false
    var undoDownvoteCalled = false
    var applyTimeBasedDecayCalled = false

    func processDownvote(taskId: UUID, reviewerId: UUID, notes: String?) {
        processDownvoteCalled = true
        credibilityScore -= 10
        let event = CredibilityHistoryEvent(
            event: .downvote,
            amount: -10,
            taskId: taskId,
            reviewerId: reviewerId,
            notes: notes,
            newScore: credibilityScore
        )
        credibilityHistory.append(event)
    }

    func undoDownvote(taskId: UUID, reviewerId: UUID) {
        undoDownvoteCalled = true
        credibilityScore += 10
    }

    func processApprovedTask(taskId: UUID, reviewerId: UUID, notes: String?) {
        processApprovedTaskCalled = true
        credibilityScore += 2
        consecutiveApprovedTasks += 1
        let event = CredibilityHistoryEvent(
            event: .approvedTask,
            amount: 2,
            taskId: taskId,
            reviewerId: reviewerId,
            notes: notes,
            newScore: credibilityScore
        )
        credibilityHistory.append(event)
    }

    func calculateXPToMinutes(xpAmount: Int) -> Int {
        return xpAmount
    }

    func getConversionRate() -> Double {
        return 1.0
    }

    func getCurrentTier() -> CredibilityTier {
        return CredibilityTier(
            name: "Good",
            range: 75...89,
            multiplier: 1.0,
            color: "green",
            description: "Good standing"
        )
    }

    func getCredibilityStatus() -> CredibilityStatus {
        return CredibilityStatus(
            score: credibilityScore,
            tier: getCurrentTier(),
            consecutiveApprovedTasks: consecutiveApprovedTasks,
            hasRedemptionBonus: hasRedemptionBonus,
            redemptionBonusExpiry: redemptionBonusExpiry,
            history: credibilityHistory,
            conversionRate: 1.0,
            recoveryPath: nil
        )
    }

    func applyTimeBasedDecay() {
        applyTimeBasedDecayCalled = true
    }
}

// MARK: - Mock App Selection Repository

final class MockAppSelectionRepository: AppSelectionRepository {
    var savedSelection: FamilyActivitySelection?
    var saveSelectionCalled = false
    var loadSelectionCalled = false
    var clearSelectionCalled = false

    func saveSelection(_ selection: FamilyActivitySelection) {
        saveSelectionCalled = true
        savedSelection = selection
    }

    func loadSelection() -> FamilyActivitySelection? {
        loadSelectionCalled = true
        return savedSelection
    }

    func clearSelection() {
        clearSelectionCalled = true
        savedSelection = nil
    }
}

// MARK: - Mock Reward Repository

final class MockRewardRepository: RewardRepository {
    var earnedMinutes: Int = 0
    var saveEarnedMinutesCalled = false
    var loadEarnedMinutesCalled = false

    func saveEarnedMinutes(_ minutes: Int) {
        saveEarnedMinutesCalled = true
        earnedMinutes = minutes
    }

    func loadEarnedMinutes() -> Int {
        loadEarnedMinutesCalled = true
        return earnedMinutes
    }
}
