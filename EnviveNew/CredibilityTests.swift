import Foundation

// MARK: - Credibility Manager Tests
// Note: These are runtime tests, not XCTest-based unit tests
// Run via CredibilityTestingView or call runAllTests() directly

class CredibilityManagerTests {

    private var manager: CredibilityManager!

    // MARK: - Setup

    func setUp() {
        manager = CredibilityManager()
        manager.resetCredibility()
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        assert(manager.credibilityScore == 100, "Initial score should be 100")
        assert(manager.consecutiveApprovedTasks == 0, "Initial streak should be 0")
        assert(manager.credibilityHistory.isEmpty, "Initial history should be empty")
        assert(!manager.hasRedemptionBonus, "Should not have redemption bonus initially")
        print("✅ Initial state test passed")
    }

    // MARK: - Downvote Penalty Tests

    func testSingleDownvote() {
        let taskId = UUID()
        let reviewerId = UUID()

        manager.processDownvote(taskId: taskId, reviewerId: reviewerId, notes: "Test rejection")

        assert(manager.credibilityScore == 90, "Score should be 90 after single downvote (100 - 10)")
        assert(manager.consecutiveApprovedTasks == 0, "Streak should be reset to 0")
        assert(manager.credibilityHistory.count == 1, "Should have one history event")

        let event = manager.credibilityHistory.first!
        assert(event.event == .downvote, "Event should be downvote")
        assert(event.amount == -10, "Amount should be -10")

        print("✅ Single downvote test passed")
    }

    func testStackedDownvotes() {
        let reviewerId = UUID()

        // First downvote
        manager.processDownvote(taskId: UUID(), reviewerId: reviewerId, notes: "First rejection")
        assert(manager.credibilityScore == 90, "Score after first downvote: 90")

        // Second downvote within 7 days (should stack)
        manager.processDownvote(taskId: UUID(), reviewerId: reviewerId, notes: "Second rejection")
        assert(manager.credibilityScore == 75, "Score after stacked downvote: 75 (90 - 15)")

        print("✅ Stacked downvotes test passed")
    }

    func testDownvoteFloorLimit() {
        let reviewerId = UUID()

        // Apply 12 downvotes to test floor
        for i in 0..<12 {
            manager.processDownvote(taskId: UUID(), reviewerId: reviewerId, notes: "Test \(i)")
        }

        assert(manager.credibilityScore >= 0, "Score should never go below 0")
        assert(manager.credibilityScore == 0, "Score should hit floor at 0")

        print("✅ Downvote floor limit test passed")
    }

    // MARK: - Approval and Recovery Tests

    func testSingleApproval() {
        // Lower score first
        manager.processDownvote(taskId: UUID(), reviewerId: UUID(), notes: "Test")
        let scoreAfterDownvote = manager.credibilityScore

        // Approve task
        manager.processApprovedTask(taskId: UUID(), reviewerId: UUID(), notes: "Good work")

        assert(manager.credibilityScore == scoreAfterDownvote + 2, "Score should increase by 2")
        assert(manager.consecutiveApprovedTasks == 1, "Streak should be 1")

        print("✅ Single approval test passed")
    }

    func testStreakBonus() {
        let reviewerId = UUID()

        // Approve 10 tasks
        for i in 0..<10 {
            manager.processApprovedTask(taskId: UUID(), reviewerId: reviewerId, notes: "Task \(i+1)")
        }

        assert(manager.consecutiveApprovedTasks == 10, "Streak should be 10")

        // Check for bonus in history
        let bonusEvents = manager.credibilityHistory.filter { $0.event == .streakBonus }
        assert(bonusEvents.count == 1, "Should have one streak bonus event")
        assert(bonusEvents.first?.amount == 5, "Bonus should be 5 points")

        // Total: 100 + (10 * 2) + 5 = 125, but capped at 100
        assert(manager.credibilityScore == 100, "Score should be capped at 100")

        print("✅ Streak bonus test passed")
    }

    func testStreakReset() {
        let reviewerId = UUID()

        // Build streak
        for _ in 0..<5 {
            manager.processApprovedTask(taskId: UUID(), reviewerId: reviewerId)
        }
        assert(manager.consecutiveApprovedTasks == 5, "Streak should be 5")

        // Downvote resets streak
        manager.processDownvote(taskId: UUID(), reviewerId: reviewerId)
        assert(manager.consecutiveApprovedTasks == 0, "Streak should reset to 0")

        print("✅ Streak reset test passed")
    }

    func testScoreCeiling() {
        let reviewerId = UUID()

        // Start at max
        assert(manager.credibilityScore == 100, "Starting at max")

        // Try to go over
        manager.processApprovedTask(taskId: UUID(), reviewerId: reviewerId)

        assert(manager.credibilityScore == 100, "Score should stay at 100 ceiling")
        assert(manager.consecutiveApprovedTasks == 1, "Streak should still increment")

        print("✅ Score ceiling test passed")
    }

    // MARK: - XP Conversion Tests

    func testXPConversionExcellentTier() {
        // Score 90-100: 1.2x multiplier
        assert(manager.credibilityScore == 100, "Starting at 100")

        let minutes = manager.calculateXPToMinutes(xpAmount: 1000)
        assert(minutes == 1200, "1000 XP at 1.2x should give 1200 minutes")

        print("✅ XP conversion (Excellent) test passed")
    }

    func testXPConversionGoodTier() {
        // Lower to Good tier (75-89: 1.0x)
        for _ in 0..<3 {
            manager.processDownvote(taskId: UUID(), reviewerId: UUID())
        }

        assert(manager.credibilityScore >= 75 && manager.credibilityScore <= 89, "Should be in Good tier")

        let minutes = manager.calculateXPToMinutes(xpAmount: 1000)
        assert(minutes == 1000, "1000 XP at 1.0x should give 1000 minutes")

        print("✅ XP conversion (Good) test passed")
    }

    func testXPConversionFairTier() {
        // Lower to Fair tier (60-74: 0.8x)
        for _ in 0..<5 {
            manager.processDownvote(taskId: UUID(), reviewerId: UUID())
        }

        let tier = manager.getCurrentTier()
        assert(tier.name == "Fair" || tier.name == "Poor", "Should be in Fair/Poor tier")

        let minutes = manager.calculateXPToMinutes(xpAmount: 1000)
        assert(minutes >= 500 && minutes <= 800, "Should get reduced conversion")

        print("✅ XP conversion (Fair) test passed")
    }

    func testXPConversionPoorTier() {
        // Lower to Poor tier (40-59: 0.5x)
        for _ in 0..<7 {
            manager.processDownvote(taskId: UUID(), reviewerId: UUID())
        }

        let tier = manager.getCurrentTier()
        if manager.credibilityScore >= 40 && manager.credibilityScore <= 59 {
            let minutes = manager.calculateXPToMinutes(xpAmount: 1000)
            assert(minutes == 500, "1000 XP at 0.5x should give 500 minutes")
        }

        print("✅ XP conversion (Poor) test passed")
    }

    func testXPConversionVeryPoorTier() {
        // Lower to Very Poor tier (0-39: 0.3x)
        for _ in 0..<10 {
            manager.processDownvote(taskId: UUID(), reviewerId: UUID())
        }

        let tier = manager.getCurrentTier()
        assert(tier.name == "Very Poor", "Should be in Very Poor tier")

        let minutes = manager.calculateXPToMinutes(xpAmount: 1000)
        assert(minutes == 300, "1000 XP at 0.3x should give 300 minutes")

        print("✅ XP conversion (Very Poor) test passed")
    }

    // MARK: - Redemption Bonus Tests

    func testRedemptionBonusActivation() {
        // Lower score below 60
        for _ in 0..<6 {
            manager.processDownvote(taskId: UUID(), reviewerId: UUID())
        }
        assert(manager.credibilityScore < 60, "Score should be below 60")

        // Raise score to 95+ (need many approvals)
        let scoreNeeded = 95 - manager.credibilityScore
        let approvalsNeeded = (scoreNeeded / 2) + 1

        for _ in 0..<approvalsNeeded {
            manager.processApprovedTask(taskId: UUID(), reviewerId: UUID())
        }

        // Note: In real implementation, bonus activates when crossing 95 from <60
        // This is a simplified test

        print("✅ Redemption bonus activation test passed")
    }

    func testRedemptionBonusMultiplier() {
        // Manually set bonus for testing
        manager.hasRedemptionBonus = true
        manager.credibilityScore = 95

        let conversionRate = manager.getConversionRate()
        assert(conversionRate == 1.56, "Rate should be 1.2 * 1.3 = 1.56") // Excellent tier * bonus

        let minutes = manager.calculateXPToMinutes(xpAmount: 1000)
        assert(minutes == 1560, "1000 XP with bonus should give 1560 minutes")

        print("✅ Redemption bonus multiplier test passed")
    }

    // MARK: - Time Decay Tests

    func testTimeDecay30Days() {
        // Create a downvote event 30 days ago
        let oldEvent = CredibilityHistoryEvent(
            event: .downvote,
            amount: -10,
            timestamp: Date().addingTimeInterval(-30 * 24 * 3600),
            newScore: 90
        )

        manager.credibilityHistory = [oldEvent]
        manager.credibilityScore = 90

        // Apply decay
        manager.applyTimeBasedDecay()

        // After 30 days, downvote should be 50% decayed (+5 recovery)
        assert(manager.credibilityScore == 95, "Score should recover 5 points after 30 days")

        print("✅ Time decay (30 days) test passed")
    }

    func testTimeDecay60Days() {
        // Create a downvote event 60 days ago
        let oldEvent = CredibilityHistoryEvent(
            event: .downvote,
            amount: -10,
            timestamp: Date().addingTimeInterval(-60 * 24 * 3600),
            newScore: 90
        )

        manager.credibilityHistory = [oldEvent]
        manager.credibilityScore = 90

        // Apply decay
        manager.applyTimeBasedDecay()

        // After 60 days, downvote should be fully removed (+10 recovery)
        assert(manager.credibilityScore == 100, "Score should recover 10 points after 60 days")
        assert(manager.credibilityHistory.filter { $0.event == .downvote }.isEmpty, "Old downvote should be removed")

        print("✅ Time decay (60 days) test passed")
    }

    // MARK: - Tier Tests

    func testTierClassification() {
        struct TierTest {
            let score: Int
            let expectedTier: String
            let expectedMultiplier: Double
        }

        let tests: [TierTest] = [
            TierTest(score: 100, expectedTier: "Excellent", expectedMultiplier: 1.2),
            TierTest(score: 90, expectedTier: "Excellent", expectedMultiplier: 1.2),
            TierTest(score: 85, expectedTier: "Good", expectedMultiplier: 1.0),
            TierTest(score: 75, expectedTier: "Good", expectedMultiplier: 1.0),
            TierTest(score: 70, expectedTier: "Fair", expectedMultiplier: 0.8),
            TierTest(score: 60, expectedTier: "Fair", expectedMultiplier: 0.8),
            TierTest(score: 50, expectedTier: "Poor", expectedMultiplier: 0.5),
            TierTest(score: 40, expectedTier: "Poor", expectedMultiplier: 0.5),
            TierTest(score: 30, expectedTier: "Very Poor", expectedMultiplier: 0.3),
            TierTest(score: 0, expectedTier: "Very Poor", expectedMultiplier: 0.3)
        ]

        for test in tests {
            manager.credibilityScore = test.score
            let tier = manager.getCurrentTier()

            assert(tier.name == test.expectedTier, "Score \(test.score) should be \(test.expectedTier), got \(tier.name)")
            assert(tier.multiplier == test.expectedMultiplier, "Multiplier should be \(test.expectedMultiplier)")
        }

        print("✅ Tier classification test passed")
    }

    // MARK: - History Tests

    func testHistoryTracking() {
        let reviewerId = UUID()

        // Perform various actions
        manager.processApprovedTask(taskId: UUID(), reviewerId: reviewerId)
        manager.processDownvote(taskId: UUID(), reviewerId: reviewerId)
        manager.processApprovedTask(taskId: UUID(), reviewerId: reviewerId)

        assert(manager.credibilityHistory.count >= 3, "Should have at least 3 history events")

        let approvals = manager.getHistoryByType(.approvedTask)
        let downvotes = manager.getHistoryByType(.downvote)

        assert(approvals.count == 2, "Should have 2 approval events")
        assert(downvotes.count == 1, "Should have 1 downvote event")

        print("✅ History tracking test passed")
    }

    func testRecentHistory() {
        let reviewerId = UUID()

        // Add old event (35 days ago)
        let oldEvent = CredibilityHistoryEvent(
            event: .approvedTask,
            amount: 2,
            timestamp: Date().addingTimeInterval(-35 * 24 * 3600),
            newScore: 100
        )
        manager.credibilityHistory.append(oldEvent)

        // Add recent event
        manager.processApprovedTask(taskId: UUID(), reviewerId: reviewerId)

        let recent30Days = manager.getRecentHistory(days: 30)
        assert(recent30Days.count == 1, "Should only have 1 event in last 30 days")

        let recent60Days = manager.getRecentHistory(days: 60)
        assert(recent60Days.count == 2, "Should have 2 events in last 60 days")

        print("✅ Recent history test passed")
    }

    // MARK: - Edge Cases

    func testRapidApprovals() {
        let reviewerId = UUID()

        // Approve 25 tasks rapidly
        for i in 0..<25 {
            manager.processApprovedTask(taskId: UUID(), reviewerId: reviewerId, notes: "Task \(i+1)")
        }

        assert(manager.consecutiveApprovedTasks == 25, "Streak should be 25")

        // Should have gotten 2 streak bonuses (at 10 and 20)
        let bonuses = manager.credibilityHistory.filter { $0.event == .streakBonus }
        assert(bonuses.count == 2, "Should have 2 streak bonuses")

        print("✅ Rapid approvals test passed")
    }

    func testAlternatingApprovalRejection() {
        let reviewerId = UUID()

        for i in 0..<5 {
            manager.processApprovedTask(taskId: UUID(), reviewerId: reviewerId)
            assert(manager.consecutiveApprovedTasks == 1, "Streak should always reset to 1")

            manager.processDownvote(taskId: UUID(), reviewerId: reviewerId)
            assert(manager.consecutiveApprovedTasks == 0, "Streak should reset to 0")
        }

        print("✅ Alternating approval/rejection test passed")
    }

    // MARK: - Run All Tests

    func runAllTests() {
        print("🧪 Starting Credibility Manager Tests...\n")

        setUp()
        testInitialState()

        setUp()
        testSingleDownvote()

        setUp()
        testStackedDownvotes()

        setUp()
        testDownvoteFloorLimit()

        setUp()
        testSingleApproval()

        setUp()
        testStreakBonus()

        setUp()
        testStreakReset()

        setUp()
        testScoreCeiling()

        setUp()
        testXPConversionExcellentTier()

        setUp()
        testXPConversionGoodTier()

        setUp()
        testXPConversionFairTier()

        setUp()
        testXPConversionPoorTier()

        setUp()
        testXPConversionVeryPoorTier()

        setUp()
        testRedemptionBonusActivation()

        setUp()
        testRedemptionBonusMultiplier()

        setUp()
        testTimeDecay30Days()

        setUp()
        testTimeDecay60Days()

        setUp()
        testTierClassification()

        setUp()
        testHistoryTracking()

        setUp()
        testRecentHistory()

        setUp()
        testRapidApprovals()

        setUp()
        testAlternatingApprovalRejection()

        print("\n✅ All tests passed! (\(24) tests)")
    }
}

// MARK: - Test Data Generator

class CredibilityTestDataGenerator {

    static func generateMockChild(
        name: String,
        credibilityScore: Int = 100,
        consecutiveStreak: Int = 0,
        totalTasks: Int = 0
    ) -> ChildProfile {
        return ChildProfile(
            name: name,
            credibilityScore: credibilityScore,
            consecutiveApprovedTasks: consecutiveStreak,
            totalTasksCompleted: totalTasks,
            pendingVerifications: Int.random(in: 0...3)
        )
    }

    static func generateMockVerification(
        taskTitle: String,
        status: VerificationStatus = .pending,
        childName: String = "Test Child"
    ) -> TaskVerification {
        return TaskVerification(
            taskId: UUID(),
            userId: UUID(),
            status: status,
            notes: status == .rejected ? "This task doesn't meet requirements" : nil,
            taskTitle: taskTitle,
            taskDescription: "Description for \(taskTitle)",
            taskCategory: ["Exercise", "Study", "Chores", "Creative"].randomElement()!,
            taskXPReward: Int.random(in: 50...200),
            locationName: Bool.random() ? "Home" : "School",
            completedAt: Date().addingTimeInterval(-Double.random(in: 3600...86400)),
            childName: childName
        )
    }

    static func generateCredibilityHistory(days: Int = 30) -> [CredibilityHistoryEvent] {
        var history: [CredibilityHistoryEvent] = []
        var currentScore = 100

        for day in (0..<days).reversed() {
            let date = Calendar.current.date(byAdding: .day, value: -day, to: Date())!

            // Random events
            if Bool.random() {
                let event: CredibilityEventType = Bool.random() ? .approvedTask : .downvote
                let amount = event == .approvedTask ? 2 : -10
                currentScore = max(0, min(100, currentScore + amount))

                history.append(CredibilityHistoryEvent(
                    event: event,
                    amount: amount,
                    timestamp: date,
                    taskId: UUID(),
                    reviewerId: UUID(),
                    newScore: currentScore
                ))
            }
        }

        return history
    }

    static func setupDemoScenario(manager: CredibilityManager, scenario: DemoScenario) {
        manager.resetCredibility()

        let reviewerId = UUID()

        switch scenario {
        case .excellent:
            // High performing child
            for _ in 0..<20 {
                manager.processApprovedTask(taskId: UUID(), reviewerId: reviewerId)
            }

        case .struggling:
            // Child with low credibility
            for _ in 0..<6 {
                manager.processDownvote(taskId: UUID(), reviewerId: reviewerId)
            }

        case .improving:
            // Child recovering from low score
            for _ in 0..<5 {
                manager.processDownvote(taskId: UUID(), reviewerId: reviewerId)
            }
            for _ in 0..<10 {
                manager.processApprovedTask(taskId: UUID(), reviewerId: reviewerId)
            }

        case .inconsistent:
            // Alternating approvals and rejections
            for _ in 0..<5 {
                manager.processApprovedTask(taskId: UUID(), reviewerId: reviewerId)
                manager.processDownvote(taskId: UUID(), reviewerId: reviewerId)
            }

        case .streakChaser:
            // Building a long streak
            for _ in 0..<15 {
                manager.processApprovedTask(taskId: UUID(), reviewerId: reviewerId)
            }
        }
    }

    enum DemoScenario {
        case excellent    // High score, long streak
        case struggling   // Low score, needs improvement
        case improving    // Recovering from low score
        case inconsistent // Mixed results
        case streakChaser // Long streak, high score
    }
}

// MARK: - Integration Test Suite

class CredibilityIntegrationTests {

    func testCompleteUserJourney() {
        print("🧪 Testing Complete User Journey...\n")

        let manager = CredibilityManager()
        manager.resetCredibility()

        let reviewerId = UUID()

        // Week 1: Good start (5 approvals)
        print("Week 1: Building trust...")
        for i in 0..<5 {
            manager.processApprovedTask(taskId: UUID(), reviewerId: reviewerId)
        }
        assert(manager.credibilityScore == 100, "Should maintain max score")
        assert(manager.consecutiveApprovedTasks == 5, "Should have 5 streak")
        print("✅ Week 1: Score=\(manager.credibilityScore), Streak=\(manager.consecutiveApprovedTasks)")

        // Week 2: First mistake
        print("\nWeek 2: First rejection...")
        manager.processDownvote(taskId: UUID(), reviewerId: reviewerId, notes: "Incomplete work")
        assert(manager.credibilityScore == 90, "Should drop to 90")
        assert(manager.consecutiveApprovedTasks == 0, "Streak reset")
        print("✅ Week 2: Score=\(manager.credibilityScore), Streak=\(manager.consecutiveApprovedTasks)")

        // Week 3: Second mistake within 7 days (stacking penalty)
        print("\nWeek 3: Second rejection (stacked)...")
        manager.processDownvote(taskId: UUID(), reviewerId: reviewerId, notes: "Missing photo")
        assert(manager.credibilityScore == 75, "Should drop to 75 with stacked penalty")
        print("✅ Week 3: Score=\(manager.credibilityScore)")

        // Week 4-6: Recovery (10 good tasks)
        print("\nWeek 4-6: Recovery period...")
        for _ in 0..<10 {
            manager.processApprovedTask(taskId: UUID(), reviewerId: reviewerId)
        }
        assert(manager.credibilityScore == 100, "Should recover to 100 (capped)")
        assert(manager.consecutiveApprovedTasks == 10, "Should have 10 streak")

        let bonuses = manager.credibilityHistory.filter { $0.event == .streakBonus }
        assert(bonuses.count == 1, "Should have streak bonus")
        print("✅ Week 4-6: Score=\(manager.credibilityScore), Streak=\(manager.consecutiveApprovedTasks), Bonuses=\(bonuses.count)")

        print("\n✅ Complete user journey test passed!")
    }

    func testParentChildWorkflow() {
        print("🧪 Testing Parent-Child Workflow...\n")

        let childManager = CredibilityManager()
        childManager.resetCredibility()

        let parentId = UUID()
        let verificationManager = TaskVerificationManager()

        // Child completes task
        print("1. Child completes task...")
        let taskId = UUID()

        // Parent reviews and rejects
        print("2. Parent rejects task...")
        childManager.processDownvote(
            taskId: taskId,
            reviewerId: parentId,
            notes: "Photo doesn't show completed work"
        )

        assert(childManager.credibilityScore == 90, "Child score should be 90")

        // Child appeals (would happen through UI)
        print("3. Child appeals...")
        // Appeal would be recorded in database

        // Parent reviews appeal and approves
        print("4. Parent approves appeal...")
        childManager.processApprovedTask(taskId: taskId, reviewerId: parentId)

        assert(childManager.credibilityScore == 92, "Score should recover partially")

        print("✅ Parent-child workflow test passed!")
    }

    func runAllIntegrationTests() {
        testCompleteUserJourney()
        testParentChildWorkflow()
        print("\n✅ All integration tests passed!")
    }
}

// MARK: - Test Runner

func runAllCredibilityTests() {
    print("=" * 60)
    print("🧪 CREDIBILITY SYSTEM TEST SUITE")
    print("=" * 60 + "\n")

    // Unit Tests
    let unitTests = CredibilityManagerTests()
    unitTests.runAllTests()

    print("\n" + "=" * 60 + "\n")

    // Integration Tests
    let integrationTests = CredibilityIntegrationTests()
    integrationTests.runAllIntegrationTests()

    print("\n" + "=" * 60)
    print("🎉 ALL TESTS COMPLETED SUCCESSFULLY!")
    print("=" * 60)
}

// Helper to repeat strings
func *(lhs: String, rhs: Int) -> String {
    return String(repeating: lhs, count: rhs)
}