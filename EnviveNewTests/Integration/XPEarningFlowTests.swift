import XCTest
@testable import EnviveNew

final class XPEarningFlowTests: XCTestCase {
    var xpService: XPServiceImpl!
    var xpRepository: XPRepositoryImpl!
    var credibilityService: MockCredibilityService!
    var mockStorage: MockStorage!
    var testUserId: UUID!

    override func setUp() {
        super.setUp()
        testUserId = UUID()
        mockStorage = MockStorage()
        xpRepository = XPRepositoryImpl(storage: mockStorage)
        credibilityService = MockCredibilityService()
        xpService = XPServiceImpl(
            repository: xpRepository,
            credibilityService: credibilityService
        )
    }

    override func tearDown() {
        mockStorage.clear()
        xpService = nil
        xpRepository = nil
        credibilityService = nil
        mockStorage = nil
        super.tearDown()
    }

    // MARK: - Full Earning and Redemption Flow

    func testFullFlow_EarnThenRedeem_Success() {
        // Arrange: Start with no balance
        XCTAssertNil(xpRepository.getBalance(userId: testUserId))

        // Act 1: Award XP for completing a 30-minute task at 100 credibility
        credibilityService.credibilityScore = 100
        let earnedXP = xpService.awardXP(
            userId: testUserId,
            timeMinutes: 30,
            taskId: UUID(),
            credibilityScore: 100
        )

        // Assert 1: Should earn 30 XP (full rate)
        XCTAssertEqual(earnedXP, 30)
        let balanceAfterEarning = xpRepository.getBalance(userId: testUserId)
        XCTAssertEqual(balanceAfterEarning?.currentXP, 30)
        XCTAssertEqual(balanceAfterEarning?.lifetimeEarned, 30)

        // Act 2: Redeem 20 XP for 20 minutes of screen time
        let redemptionResult = xpService.redeemXP(
            amount: 20,
            userId: testUserId,
            credibilityScore: 100
        )

        // Assert 2: Redemption should succeed
        switch redemptionResult {
        case .success(let result):
            XCTAssertTrue(result.success)
            XCTAssertEqual(result.xpSpent, 20)
            XCTAssertEqual(result.minutesGranted, 20, "1 XP = 1 minute")
            XCTAssertEqual(result.newBalance, 10, "30 - 20 = 10 XP remaining")
        case .failure:
            XCTFail("Redemption should succeed")
        }

        // Assert 3: Balance should be updated
        let finalBalance = xpRepository.getBalance(userId: testUserId)
        XCTAssertEqual(finalBalance?.currentXP, 10)
        XCTAssertEqual(finalBalance?.lifetimeEarned, 30)
        XCTAssertEqual(finalBalance?.lifetimeSpent, 20)
    }

    func testFullFlow_MultipleTasksWithVaryingCredibility() {
        // Scenario: Kid completes 3 tasks over time with credibility changes

        // Task 1: 20 minutes at 100 credibility (Excellent)
        credibilityService.credibilityScore = 100
        let xp1 = xpService.awardXP(
            userId: testUserId,
            timeMinutes: 20,
            taskId: UUID(),
            credibilityScore: 100
        )
        XCTAssertEqual(xp1, 20, "Full XP at excellent credibility")

        // Task 2: 30 minutes at 85 credibility (Good)
        credibilityService.credibilityScore = 85
        let xp2 = xpService.awardXP(
            userId: testUserId,
            timeMinutes: 30,
            taskId: UUID(),
            credibilityScore: 85
        )
        XCTAssertEqual(xp2, 27, "90% XP at good credibility (30 * 0.9 = 27)")

        // Task 3: 40 minutes at 70 credibility (Fair)
        credibilityService.credibilityScore = 70
        let xp3 = xpService.awardXP(
            userId: testUserId,
            timeMinutes: 40,
            taskId: UUID(),
            credibilityScore: 70
        )
        XCTAssertEqual(xp3, 30, "75% XP at fair credibility (40 * 0.75 = 30)")

        // Check total balance
        let balance = xpRepository.getBalance(userId: testUserId)
        XCTAssertEqual(balance?.currentXP, 77, "20 + 27 + 30 = 77 XP")
        XCTAssertEqual(balance?.lifetimeEarned, 77)

        // Check transactions
        let transactions = xpRepository.getTransactions(userId: testUserId)
        XCTAssertEqual(transactions.count, 3)
        XCTAssertEqual(transactions[0].amount, 20)
        XCTAssertEqual(transactions[1].amount, 27)
        XCTAssertEqual(transactions[2].amount, 30)
    }

    func testFullFlow_EarnSpendEarnSpend_BalanceTracking() {
        credibilityService.credibilityScore = 100

        // Earn 50 XP
        _ = xpService.awardXP(userId: testUserId, timeMinutes: 50, taskId: UUID(), credibilityScore: 100)
        XCTAssertEqual(xpRepository.getBalance(userId: testUserId)?.currentXP, 50)

        // Spend 30 XP
        _ = xpService.redeemXP(amount: 30, userId: testUserId, credibilityScore: 100)
        XCTAssertEqual(xpRepository.getBalance(userId: testUserId)?.currentXP, 20)

        // Earn 40 XP more
        _ = xpService.awardXP(userId: testUserId, timeMinutes: 40, taskId: UUID(), credibilityScore: 100)
        XCTAssertEqual(xpRepository.getBalance(userId: testUserId)?.currentXP, 60)

        // Spend 50 XP
        _ = xpService.redeemXP(amount: 50, userId: testUserId, credibilityScore: 100)
        XCTAssertEqual(xpRepository.getBalance(userId: testUserId)?.currentXP, 10)

        // Check lifetime stats
        let finalBalance = xpRepository.getBalance(userId: testUserId)
        XCTAssertEqual(finalBalance?.lifetimeEarned, 90)
        XCTAssertEqual(finalBalance?.lifetimeSpent, 80)
    }

    // MARK: - Soft Cap Tests

    func testSoftCap_EarningAbove1000XP_DiminishingReturns() {
        credibilityService.credibilityScore = 100

        // Earn 950 XP (below soft cap)
        _ = xpService.awardXP(userId: testUserId, timeMinutes: 950, taskId: UUID(), credibilityScore: 100)
        var balance = xpRepository.getBalance(userId: testUserId)
        XCTAssertEqual(balance?.currentXP, 950)

        // Earn 100 more XP (50 below cap, 50 above cap)
        _ = xpService.awardXP(userId: testUserId, timeMinutes: 100, taskId: UUID(), credibilityScore: 100)
        balance = xpRepository.getBalance(userId: testUserId)

        // Should get: 50 XP (to reach 1000) + 25 XP (50% of remaining 50) = 1025 XP
        XCTAssertEqual(balance?.currentXP, 1025, "Should apply 50% penalty above soft cap")
    }

    func testSoftCap_EarningAtCap_HalvedReturns() {
        credibilityService.credibilityScore = 100

        // Earn exactly 1000 XP (at soft cap)
        _ = xpService.awardXP(userId: testUserId, timeMinutes: 1000, taskId: UUID(), credibilityScore: 100)
        var balance = xpRepository.getBalance(userId: testUserId)
        XCTAssertEqual(balance?.currentXP, 1000)

        // Earn 100 more XP while at cap
        _ = xpService.awardXP(userId: testUserId, timeMinutes: 100, taskId: UUID(), credibilityScore: 100)
        balance = xpRepository.getBalance(userId: testUserId)

        // Should only get 50 XP (50% of 100)
        XCTAssertEqual(balance?.currentXP, 1050, "Should earn 50% above soft cap")
    }

    // MARK: - Daily Stats Tests

    func testDailyStats_TracksEarningsAndRedemptions() {
        credibilityService.credibilityScore = 90

        // Earn 50 XP
        _ = xpService.awardXP(userId: testUserId, timeMinutes: 50, taskId: UUID(), credibilityScore: 90)

        // Earn 30 more XP
        _ = xpService.awardXP(userId: testUserId, timeMinutes: 30, taskId: UUID(), credibilityScore: 90)

        // Redeem 20 XP
        _ = xpService.redeemXP(amount: 20, userId: testUserId, credibilityScore: 90)

        // Check daily stats
        let stats = xpService.getDailyStats(userId: testUserId)

        // At 90 credibility: 50 * 0.9 = 45 XP, 30 * 0.9 = 27 XP
        XCTAssertEqual(stats.earnedToday, 72, "Should track today's earnings (45 + 27)")
        XCTAssertEqual(stats.redeemedToday, 20, "Should track today's redemptions")
        XCTAssertEqual(stats.currentBalance, 52, "72 earned - 20 redeemed = 52")
        XCTAssertEqual(stats.credibilityScore, 90)
        XCTAssertEqual(stats.earningRate, 0.9)
    }

    // MARK: - Edge Cases

    func testEdgeCase_RedeemAllXP_BalanceGoesToZero() {
        credibilityService.credibilityScore = 100

        // Earn 100 XP
        _ = xpService.awardXP(userId: testUserId, timeMinutes: 100, taskId: UUID(), credibilityScore: 100)

        // Redeem all 100 XP
        let result = xpService.redeemXP(amount: 100, userId: testUserId, credibilityScore: 100)

        switch result {
        case .success(let redemption):
            XCTAssertEqual(redemption.newBalance, 0)
        case .failure:
            XCTFail("Should succeed")
        }

        let balance = xpRepository.getBalance(userId: testUserId)
        XCTAssertEqual(balance?.currentXP, 0)
    }

    func testEdgeCase_RedeemMoreThanBalance_Fails() {
        credibilityService.credibilityScore = 100

        // Earn 50 XP
        _ = xpService.awardXP(userId: testUserId, timeMinutes: 50, taskId: UUID(), credibilityScore: 100)

        // Try to redeem 100 XP (more than balance)
        let result = xpService.redeemXP(amount: 100, userId: testUserId, credibilityScore: 100)

        switch result {
        case .success:
            XCTFail("Should fail due to insufficient balance")
        case .failure(let error):
            XCTAssertEqual(error, .insufficientXP)
        }

        // Balance should remain unchanged
        let balance = xpRepository.getBalance(userId: testUserId)
        XCTAssertEqual(balance?.currentXP, 50)
    }

    func testEdgeCase_VeryLowCredibility_StillEarnsMinimum1XP() {
        credibilityService.credibilityScore = 10  // Critical tier (25% rate)

        // Earn from 1-minute task
        let xp = xpService.awardXP(
            userId: testUserId,
            timeMinutes: 1,
            taskId: UUID(),
            credibilityScore: 10
        )

        // 1 * 0.25 = 0.25, should round up to 1
        XCTAssertEqual(xp, 1, "Should always earn minimum 1 XP")
    }

    // MARK: - Transaction History Tests

    func testTransactionHistory_MixedEarningsAndRedemptions() {
        credibilityService.credibilityScore = 100

        // Earn
        _ = xpService.awardXP(userId: testUserId, timeMinutes: 30, taskId: UUID(), credibilityScore: 100)

        // Redeem
        _ = xpService.redeemXP(amount: 10, userId: testUserId, credibilityScore: 100)

        // Earn again
        _ = xpService.awardXP(userId: testUserId, timeMinutes: 20, taskId: UUID(), credibilityScore: 100)

        // Redeem again
        _ = xpService.redeemXP(amount: 15, userId: testUserId, credibilityScore: 100)

        // Check transaction history
        let transactions = xpRepository.getTransactions(userId: testUserId)
        XCTAssertEqual(transactions.count, 4)

        XCTAssertEqual(transactions[0].type, .earned)
        XCTAssertEqual(transactions[0].amount, 30)

        XCTAssertEqual(transactions[1].type, .redeemed)
        XCTAssertEqual(transactions[1].amount, 10)

        XCTAssertEqual(transactions[2].type, .earned)
        XCTAssertEqual(transactions[2].amount, 20)

        XCTAssertEqual(transactions[3].type, .redeemed)
        XCTAssertEqual(transactions[3].amount, 15)
    }

    // MARK: - Rounding Tests

    func testRounding_AlwaysRoundsUp() {
        let testCases: [(timeMinutes: Int, credibility: Int, expectedXP: Int)] = [
            (13, 90, 12),   // 13 * 0.9 = 11.7 → 12
            (7, 75, 6),     // 7 * 0.75 = 5.25 → 6
            (3, 50, 2),     // 3 * 0.5 = 1.5 → 2
            (11, 90, 10),   // 11 * 0.9 = 9.9 → 10
        ]

        for (index, testCase) in testCases.enumerated() {
            let userId = UUID()  // Use different user for each test
            let xp = xpService.awardXP(
                userId: userId,
                timeMinutes: testCase.timeMinutes,
                taskId: UUID(),
                credibilityScore: testCase.credibility
            )

            XCTAssertEqual(
                xp,
                testCase.expectedXP,
                "Test case \(index): \(testCase.timeMinutes) min at \(testCase.credibility) credibility"
            )
        }
    }
}
