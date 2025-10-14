import XCTest
@testable import EnviveNew

final class CredibilityCalculatorTests: XCTestCase {
    var calculator: CredibilityCalculator!

    override func setUp() {
        super.setUp()
        calculator = CredibilityCalculator()
    }

    override func tearDown() {
        calculator = nil
        super.tearDown()
    }

    // MARK: - Downvote Penalty Tests

    func testSingleDownvotePenalty() {
        let penalty = calculator.calculateDownvotePenalty(lastDownvoteDate: nil)
        XCTAssertEqual(penalty, -10, "First downvote should be -10 points")
    }

    func testStackedDownvotePenalty() {
        let recentDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        let penalty = calculator.calculateDownvotePenalty(lastDownvoteDate: recentDate)
        XCTAssertEqual(penalty, -15, "Stacked downvote within 7 days should be -15 points")
    }

    func testNonStackedDownvotePenalty() {
        let oldDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let penalty = calculator.calculateDownvotePenalty(lastDownvoteDate: oldDate)
        XCTAssertEqual(penalty, -10, "Downvote after 7 days should be -10 points")
    }

    func testDownvotePenaltyAtExactBoundary() {
        let exactBoundary = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let penalty = calculator.calculateDownvotePenalty(lastDownvoteDate: exactBoundary)
        XCTAssertEqual(penalty, -15, "Downvote at exactly 7 days should still stack")
    }

    // MARK: - Streak Bonus Tests

    func testStreakBonusAwarded() {
        XCTAssertTrue(calculator.shouldAwardStreakBonus(consecutiveTasks: 10))
        XCTAssertTrue(calculator.shouldAwardStreakBonus(consecutiveTasks: 20))
        XCTAssertTrue(calculator.shouldAwardStreakBonus(consecutiveTasks: 30))
    }

    func testStreakBonusNotAwarded() {
        XCTAssertFalse(calculator.shouldAwardStreakBonus(consecutiveTasks: 0))
        XCTAssertFalse(calculator.shouldAwardStreakBonus(consecutiveTasks: 9))
        XCTAssertFalse(calculator.shouldAwardStreakBonus(consecutiveTasks: 11))
        XCTAssertFalse(calculator.shouldAwardStreakBonus(consecutiveTasks: 19))
    }

    // MARK: - Score Clamping Tests

    func testScoreClampingUpperBound() {
        XCTAssertEqual(calculator.clampScore(150), 100)
        XCTAssertEqual(calculator.clampScore(101), 100)
        XCTAssertEqual(calculator.clampScore(100), 100)
    }

    func testScoreClampingLowerBound() {
        XCTAssertEqual(calculator.clampScore(-50), 0)
        XCTAssertEqual(calculator.clampScore(-1), 0)
        XCTAssertEqual(calculator.clampScore(0), 0)
    }

    func testScoreClampingWithinBounds() {
        XCTAssertEqual(calculator.clampScore(50), 50)
        XCTAssertEqual(calculator.clampScore(75), 75)
        XCTAssertEqual(calculator.clampScore(99), 99)
    }

    // MARK: - Decay Recovery Tests

    func testDecayRecoveryFullDecay() {
        let oldDate = Calendar.current.date(byAdding: .day, value: -65, to: Date())!
        let event = CredibilityHistoryEvent(
            event: .downvote,
            amount: -10,
            timestamp: oldDate,
            newScore: 90
        )

        let recovery = calculator.calculateDecayRecovery(for: [event], currentDate: Date())
        XCTAssertEqual(recovery, 10, "Full decay should recover all penalty points")
    }

    func testDecayRecoveryHalfDecay() {
        let mediumDate = Calendar.current.date(byAdding: .day, value: -35, to: Date())!
        let event = CredibilityHistoryEvent(
            event: .downvote,
            amount: -10,
            timestamp: mediumDate,
            newScore: 90
        )

        let recovery = calculator.calculateDecayRecovery(for: [event], currentDate: Date())
        XCTAssertEqual(recovery, 5, "Half decay should recover half penalty points")
    }

    func testDecayRecoveryNoDecay() {
        let recentDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        let event = CredibilityHistoryEvent(
            event: .downvote,
            amount: -10,
            timestamp: recentDate,
            newScore: 90
        )

        let recovery = calculator.calculateDecayRecovery(for: [event], currentDate: Date())
        XCTAssertEqual(recovery, 0, "Recent downvote should not have decay recovery")
    }

    func testDecayRecoveryMultipleEvents() {
        let oldDate1 = Calendar.current.date(byAdding: .day, value: -65, to: Date())!
        let oldDate2 = Calendar.current.date(byAdding: .day, value: -70, to: Date())!
        let mediumDate = Calendar.current.date(byAdding: .day, value: -35, to: Date())!

        let events = [
            CredibilityHistoryEvent(event: .downvote, amount: -10, timestamp: oldDate1, newScore: 90),
            CredibilityHistoryEvent(event: .downvote, amount: -15, timestamp: oldDate2, newScore: 75),
            CredibilityHistoryEvent(event: .downvote, amount: -10, timestamp: mediumDate, newScore: 65)
        ]

        let recovery = calculator.calculateDecayRecovery(for: events, currentDate: Date())
        XCTAssertEqual(recovery, 30, "Should recover 10 + 15 (full) + 5 (half)")
    }

    func testDecayRecoveryIgnoresNonDownvoteEvents() {
        let oldDate = Calendar.current.date(byAdding: .day, value: -65, to: Date())!
        let events = [
            CredibilityHistoryEvent(event: .downvote, amount: -10, timestamp: oldDate, newScore: 90),
            CredibilityHistoryEvent(event: .approvedTask, amount: 2, timestamp: oldDate, newScore: 92),
            CredibilityHistoryEvent(event: .streakBonus, amount: 5, timestamp: oldDate, newScore: 97)
        ]

        let recovery = calculator.calculateDecayRecovery(for: events, currentDate: Date())
        XCTAssertEqual(recovery, 10, "Should only recover from downvote events")
    }

    func testDecayRecoveryWithAlreadyDecayedEvent() {
        let mediumDate = Calendar.current.date(byAdding: .day, value: -35, to: Date())!
        let event = CredibilityHistoryEvent(
            event: .downvote,
            amount: -10,
            timestamp: mediumDate,
            newScore: 90,
            decayed: true
        )

        let recovery = calculator.calculateDecayRecovery(for: [event], currentDate: Date())
        XCTAssertEqual(recovery, 0, "Already decayed event should not recover again")
    }
}
