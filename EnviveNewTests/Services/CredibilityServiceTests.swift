import XCTest
@testable import EnviveNew

final class CredibilityServiceTests: XCTestCase {
    var service: CredibilityServiceImpl!
    var mockStorage: MockStorage!

    override func setUp() {
        super.setUp()
        mockStorage = MockStorage()
        service = CredibilityServiceImpl(
            storage: mockStorage,
            calculator: CredibilityCalculator(),
            tierProvider: CredibilityTierProvider()
        )
    }

    override func tearDown() {
        mockStorage.clear()
        service = nil
        mockStorage = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialScore() {
        XCTAssertEqual(service.credibilityScore, 100)
        XCTAssertEqual(service.consecutiveApprovedTasks, 0)
        XCTAssertFalse(service.hasRedemptionBonus)
        XCTAssertNil(service.redemptionBonusExpiry)
        XCTAssertTrue(service.credibilityHistory.isEmpty)
    }

    // MARK: - Downvote Tests

    func testProcessDownvote() {
        let taskId = UUID()
        let reviewerId = UUID()

        service.processDownvote(taskId: taskId, reviewerId: reviewerId, notes: "Test downvote")

        XCTAssertEqual(service.credibilityScore, 90)
        XCTAssertEqual(service.consecutiveApprovedTasks, 0)
        XCTAssertEqual(service.credibilityHistory.count, 1)
        XCTAssertEqual(service.credibilityHistory.first?.event, .downvote)
        XCTAssertEqual(service.credibilityHistory.first?.amount, -10)
    }

    func testMultipleDownvotesResetStreak() {
        let taskId1 = UUID()
        let taskId2 = UUID()
        let reviewerId = UUID()

        // Build up a streak first
        service.processApprovedTask(taskId: UUID(), reviewerId: reviewerId, notes: nil)
        service.processApprovedTask(taskId: UUID(), reviewerId: reviewerId, notes: nil)
        XCTAssertEqual(service.consecutiveApprovedTasks, 2)

        // Downvote should reset streak
        service.processDownvote(taskId: taskId1, reviewerId: reviewerId, notes: nil)
        XCTAssertEqual(service.consecutiveApprovedTasks, 0)
    }

    func testUndoDownvote() {
        let taskId = UUID()
        let reviewerId = UUID()

        service.processDownvote(taskId: taskId, reviewerId: reviewerId, notes: nil)
        XCTAssertEqual(service.credibilityScore, 90)

        service.undoDownvote(taskId: taskId, reviewerId: reviewerId)
        XCTAssertEqual(service.credibilityScore, 100)

        let undoEvents = service.credibilityHistory.filter { $0.event == .downvoteUndone }
        XCTAssertEqual(undoEvents.count, 1)
    }

    func testUndoNonexistentDownvote() {
        let initialScore = service.credibilityScore
        let taskId = UUID()
        let reviewerId = UUID()

        service.undoDownvote(taskId: taskId, reviewerId: reviewerId)

        // Should not change anything
        XCTAssertEqual(service.credibilityScore, initialScore)
        XCTAssertTrue(service.credibilityHistory.isEmpty)
    }

    // MARK: - Approved Task Tests

    func testProcessApprovedTask() {
        let taskId = UUID()
        let reviewerId = UUID()

        service.processApprovedTask(taskId: taskId, reviewerId: reviewerId, notes: "Great job!")

        XCTAssertEqual(service.credibilityScore, 100) // Already at max
        XCTAssertEqual(service.consecutiveApprovedTasks, 1)
        XCTAssertEqual(service.credibilityHistory.count, 1)
        XCTAssertEqual(service.credibilityHistory.first?.event, .approvedTask)
    }

    func testConsecutiveApprovedTasksIncrement() {
        let reviewerId = UUID()

        for i in 1...5 {
            service.processApprovedTask(taskId: UUID(), reviewerId: reviewerId, notes: nil)
            XCTAssertEqual(service.consecutiveApprovedTasks, i)
        }
    }

    func testStreakBonus() {
        let reviewerId = UUID()

        // Complete 10 tasks to trigger streak bonus
        for _ in 0..<10 {
            service.processApprovedTask(taskId: UUID(), reviewerId: reviewerId, notes: nil)
        }

        // Should have streak bonus event
        let streakEvents = service.credibilityHistory.filter { $0.event == .streakBonus }
        XCTAssertEqual(streakEvents.count, 1)
        XCTAssertEqual(service.consecutiveApprovedTasks, 10)
    }

    // MARK: - XP Conversion Tests

    func testXPToMinutesConversion() {
        let minutes = service.calculateXPToMinutes(xpAmount: 100)

        // At 100 score (Excellent tier), multiplier is 1.2
        XCTAssertEqual(minutes, 120)
    }

    func testXPToMinutesWithLowerScore() {
        // Lower the score to Fair tier (60-74, 0.8x)
        let taskId = UUID()
        let reviewerId = UUID()

        for _ in 0..<20 {
            service.processDownvote(taskId: taskId, reviewerId: reviewerId, notes: nil)
        }

        let minutes = service.calculateXPToMinutes(xpAmount: 100)
        XCTAssertEqual(minutes, 80)
    }

    func testConversionRate() {
        let rate = service.getConversionRate()
        XCTAssertEqual(rate, 1.2) // Excellent tier at 100 score
    }

    // MARK: - Tier Tests

    func testGetCurrentTier() {
        let tier = service.getCurrentTier()
        XCTAssertEqual(tier.name, "Excellent")
        XCTAssertEqual(tier.multiplier, 1.2)
    }

    func testGetCredibilityStatus() {
        let status = service.getCredibilityStatus()
        XCTAssertEqual(status.score, 100)
        XCTAssertEqual(status.tier.name, "Excellent")
        XCTAssertEqual(status.consecutiveApprovedTasks, 0)
        XCTAssertFalse(status.hasRedemptionBonus)
    }

    // MARK: - Persistence Tests

    func testPersistence() {
        let taskId = UUID()
        let reviewerId = UUID()

        service.processApprovedTask(taskId: taskId, reviewerId: reviewerId, notes: "Test")

        // Create new service with same storage
        let newService = CredibilityServiceImpl(
            storage: mockStorage,
            calculator: CredibilityCalculator(),
            tierProvider: CredibilityTierProvider()
        )

        XCTAssertEqual(newService.credibilityScore, service.credibilityScore)
        XCTAssertEqual(newService.consecutiveApprovedTasks, service.consecutiveApprovedTasks)
        XCTAssertEqual(newService.credibilityHistory.count, service.credibilityHistory.count)
    }

    // MARK: - Time-Based Decay Tests

    func testApplyTimeBasedDecay() {
        // Create an old downvote event manually in storage
        let oldDate = Calendar.current.date(byAdding: .day, value: -65, to: Date())!
        let event = CredibilityHistoryEvent(
            event: .downvote,
            amount: -10,
            timestamp: oldDate,
            newScore: 90
        )

        // Manually set up state
        mockStorage.saveInt(90, forKey: "userCredibilityScore")
        mockStorage.save([event], forKey: "userCredibilityHistory")

        // Create new service to load this state
        let testService = CredibilityServiceImpl(
            storage: mockStorage,
            calculator: CredibilityCalculator(),
            tierProvider: CredibilityTierProvider()
        )

        let scoreBefore = testService.credibilityScore
        testService.applyTimeBasedDecay()

        XCTAssertGreaterThan(testService.credibilityScore, scoreBefore)
    }
}
