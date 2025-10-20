import XCTest
@testable import EnviveNew

// MARK: - Task-XP Integration Tests

class TaskXPIntegrationTests: XCTestCase {
    var xpService: XPServiceImpl!
    var credibilityService: MockCredibilityServiceForXP!
    var xpRepository: XPRepositoryImpl!
    var storage: MockStorage!
    var taskVerificationManager: TaskVerificationManager!

    let testUserId = UUID()
    let testTaskId = UUID()

    override func setUp() {
        super.setUp()

        storage = MockStorage()
        xpRepository = XPRepositoryImpl(storage: storage)
        credibilityService = MockCredibilityServiceForXP(initialScore: 95)
        xpService = XPServiceImpl(repository: xpRepository, credibilityService: credibilityService)
        taskVerificationManager = TaskVerificationManager(
            xpService: xpService,
            credibilityService: credibilityService
        )
    }

    override func tearDown() {
        xpService = nil
        credibilityService = nil
        xpRepository = nil
        storage = nil
        taskVerificationManager = nil
        super.tearDown()
    }

    // MARK: - Task Approval XP Award Tests

    func testTaskApproval_AwardsCorrectXP_WithExcellentCredibility() {
        // Arrange
        credibilityService.mockScore = 100
        let verification = createMockVerification(timeMinutes: 30)

        // Act
        taskVerificationManager.approveTask(verification)

        // Assert
        let balance = xpService.getBalance(userId: testUserId)
        XCTAssertNotNil(balance, "Balance should be created")
        XCTAssertEqual(balance?.currentXP, 30, "Should earn 30 XP at 100% credibility")
        XCTAssertEqual(balance?.lifetimeEarned, 30, "Lifetime earned should be 30")

        // Check approval result
        let result = taskVerificationManager.lastApprovedTaskResult
        XCTAssertNotNil(result, "Should have approval result")
        XCTAssertEqual(result?.earnedXP, 30, "Result should show 30 XP earned")
        XCTAssertEqual(result?.credibilityScore, 100, "Result should show credibility score")
        XCTAssertEqual(result?.earningRate, 100, "Result should show 100% earning rate")
    }

    func testTaskApproval_AwardsReducedXP_WithLowerCredibility() {
        // Arrange
        credibilityService.mockScore = 85 // Good tier: 90% multiplier
        let verification = createMockVerification(timeMinutes: 40)

        // Act
        taskVerificationManager.approveTask(verification)

        // Assert
        let balance = xpService.getBalance(userId: testUserId)
        XCTAssertNotNil(balance, "Balance should be created")
        XCTAssertEqual(balance?.currentXP, 36, "Should earn 36 XP at 90% credibility (40 * 0.9 = 36)")
        XCTAssertEqual(balance?.lifetimeEarned, 36, "Lifetime earned should be 36")

        // Check approval result
        let result = taskVerificationManager.lastApprovedTaskResult
        XCTAssertEqual(result?.earnedXP, 36, "Result should show 36 XP earned")
        XCTAssertEqual(result?.credibilityScore, 85, "Result should show credibility score")
        XCTAssertEqual(result?.earningRate, 90, "Result should show 90% earning rate")
    }

    func testTaskApproval_MinimumOneXP_WithVeryLowCredibility() {
        // Arrange
        credibilityService.mockScore = 10 // Critical tier: 25% multiplier
        let verification = createMockVerification(timeMinutes: 1)

        // Act
        taskVerificationManager.approveTask(verification)

        // Assert
        let balance = xpService.getBalance(userId: testUserId)
        XCTAssertNotNil(balance, "Balance should be created")
        XCTAssertEqual(balance?.currentXP, 1, "Should earn minimum 1 XP even with low credibility")
    }

    func testMultipleTaskApprovals_AccumulateXP() {
        // Arrange
        credibilityService.mockScore = 95

        // Act - Approve three tasks
        taskVerificationManager.approveTask(createMockVerification(timeMinutes: 20))
        taskVerificationManager.approveTask(createMockVerification(timeMinutes: 30))
        taskVerificationManager.approveTask(createMockVerification(timeMinutes: 15))

        // Assert
        let balance = xpService.getBalance(userId: testUserId)
        XCTAssertNotNil(balance, "Balance should exist")
        XCTAssertEqual(balance?.currentXP, 65, "Should accumulate XP: 20 + 30 + 15 = 65")
        XCTAssertEqual(balance?.lifetimeEarned, 65, "Lifetime earned should be 65")
    }

    func testTaskApproval_WithCredibilityChange_AwardsCorrectXP() {
        // Arrange
        credibilityService.mockScore = 100

        // Act - First task at 100% credibility
        taskVerificationManager.approveTask(createMockVerification(timeMinutes: 30))

        // Change credibility for second task
        credibilityService.mockScore = 70 // Fair tier: 75% multiplier

        // Second task at 75% credibility
        taskVerificationManager.approveTask(createMockVerification(timeMinutes: 40))

        // Assert
        let balance = xpService.getBalance(userId: testUserId)
        XCTAssertNotNil(balance, "Balance should exist")
        // 30 XP (100%) + 30 XP (40 * 0.75 = 30) = 60 XP
        XCTAssertEqual(balance?.currentXP, 60, "Should accumulate XP with different rates")
    }

    // MARK: - XP Earning and Redemption Flow Tests

    func testCompleteFlow_EarnAndRedeemXP() {
        // Arrange
        credibilityService.mockScore = 95

        // Act - Earn XP through task
        taskVerificationManager.approveTask(createMockVerification(timeMinutes: 60))

        // Redeem some XP
        let redemptionResult = xpService.redeemXP(
            amount: 30,
            userId: testUserId,
            credibilityScore: 95
        )

        // Assert
        XCTAssertTrue(redemptionResult.isSuccess, "Redemption should succeed")

        let balance = xpService.getBalance(userId: testUserId)
        XCTAssertNotNil(balance, "Balance should exist")
        XCTAssertEqual(balance?.currentXP, 30, "Should have 30 XP remaining (60 - 30)")
        XCTAssertEqual(balance?.lifetimeEarned, 60, "Lifetime earned should be 60")
        XCTAssertEqual(balance?.lifetimeSpent, 30, "Lifetime spent should be 30")
    }

    func testMultipleTasks_EarnXP_ThenRedeemAll() {
        // Arrange
        credibilityService.mockScore = 100

        // Act - Earn XP from multiple tasks
        taskVerificationManager.approveTask(createMockVerification(timeMinutes: 20))
        taskVerificationManager.approveTask(createMockVerification(timeMinutes: 25))
        taskVerificationManager.approveTask(createMockVerification(timeMinutes: 15))

        let balance = xpService.getBalance(userId: testUserId)
        let totalEarned = balance?.currentXP ?? 0

        // Redeem all XP
        let redemptionResult = xpService.redeemXP(
            amount: totalEarned,
            userId: testUserId,
            credibilityScore: 100
        )

        // Assert
        XCTAssertTrue(redemptionResult.isSuccess, "Should be able to redeem all XP")

        let finalBalance = xpService.getBalance(userId: testUserId)
        XCTAssertEqual(finalBalance?.currentXP, 0, "Balance should be zero after redeeming all")
        XCTAssertEqual(finalBalance?.lifetimeEarned, 60, "Lifetime earned should be 60 (20+25+15)")
        XCTAssertEqual(finalBalance?.lifetimeSpent, 60, "Lifetime spent should equal earned")
    }

    // MARK: - Soft Cap Tests

    func testTaskApproval_WithBalanceAboveSoftCap_AppliesDiminishingReturns() {
        // Arrange
        credibilityService.mockScore = 100

        // Create balance above soft cap (1000 XP)
        var balance = XPBalance(userId: testUserId)
        balance.currentXP = 1050
        balance.lifetimeEarned = 1050
        xpRepository.saveBalance(balance)

        // Act - Earn XP above soft cap
        taskVerificationManager.approveTask(createMockVerification(timeMinutes: 60))

        // Assert
        let newBalance = xpService.getBalance(userId: testUserId)
        XCTAssertNotNil(newBalance, "Balance should exist")
        // Above soft cap: should earn 30 XP (50% of 60)
        XCTAssertEqual(newBalance?.currentXP, 1080, "Should apply 50% diminishing returns above soft cap")
        XCTAssertEqual(newBalance?.lifetimeEarned, 1110, "Lifetime should include full 60 XP")
    }

    // MARK: - Transaction History Tests

    func testTaskApproval_CreatesTransaction() {
        // Arrange
        credibilityService.mockScore = 95

        // Act
        taskVerificationManager.approveTask(createMockVerification(timeMinutes: 45))

        // Assert
        let transactions = xpService.getRecentTransactions(userId: testUserId, limit: 10)
        XCTAssertEqual(transactions.count, 1, "Should have one transaction")

        let transaction = transactions.first
        XCTAssertNotNil(transaction, "Transaction should exist")
        XCTAssertEqual(transaction?.type, .earned, "Transaction should be earned type")
        XCTAssertEqual(transaction?.amount, 45, "Transaction should be for 45 XP")
        XCTAssertEqual(transaction?.userId, testUserId, "Transaction should be for correct user")
        XCTAssertEqual(transaction?.relatedTaskId, testTaskId, "Transaction should link to task")
        XCTAssertEqual(transaction?.credibilityAtTime, 95, "Transaction should record credibility")
    }

    func testMultipleTaskApprovals_CreatesMultipleTransactions() {
        // Arrange
        credibilityService.mockScore = 95

        // Act - Approve three tasks
        taskVerificationManager.approveTask(createMockVerification(timeMinutes: 20))
        taskVerificationManager.approveTask(createMockVerification(timeMinutes: 30))
        taskVerificationManager.approveTask(createMockVerification(timeMinutes: 15))

        // Assert
        let transactions = xpService.getRecentTransactions(userId: testUserId, limit: 10)
        XCTAssertEqual(transactions.count, 3, "Should have three transactions")

        // Transactions should be in reverse chronological order
        XCTAssertEqual(transactions[0].amount, 15, "Most recent should be 15 XP")
        XCTAssertEqual(transactions[1].amount, 30, "Second should be 30 XP")
        XCTAssertEqual(transactions[2].amount, 20, "Oldest should be 20 XP")
    }

    // MARK: - Daily Stats Tests

    func testTaskApproval_UpdatesDailyStats() {
        // Arrange
        credibilityService.mockScore = 95

        // Act
        taskVerificationManager.approveTask(createMockVerification(timeMinutes: 30))
        taskVerificationManager.approveTask(createMockVerification(timeMinutes: 25))

        // Assert
        let stats = xpService.getDailyStats(userId: testUserId)
        XCTAssertEqual(stats.earnedToday, 55, "Should have earned 55 XP today")
        XCTAssertEqual(stats.redeemedToday, 0, "Should have redeemed 0 XP today")
        XCTAssertEqual(stats.currentBalance, 55, "Current balance should be 55")
        XCTAssertEqual(stats.credibilityScore, 95, "Should reflect credibility score")
        XCTAssertEqual(stats.earningRate, 1.0, "Should show 100% earning rate")
    }

    // MARK: - Edge Cases

    func testTaskApproval_WithZeroMinutes_StillAwardsMinimumXP() {
        // Arrange
        credibilityService.mockScore = 95

        // Act
        taskVerificationManager.approveTask(createMockVerification(timeMinutes: 0))

        // Assert
        let balance = xpService.getBalance(userId: testUserId)
        XCTAssertNotNil(balance, "Balance should exist")
        XCTAssertEqual(balance?.currentXP, 1, "Should award minimum 1 XP")
    }

    func testTaskApproval_WithLargeTimeValue_HandlesCorrectly() {
        // Arrange
        credibilityService.mockScore = 100

        // Act
        taskVerificationManager.approveTask(createMockVerification(timeMinutes: 480)) // 8 hours

        // Assert
        let balance = xpService.getBalance(userId: testUserId)
        XCTAssertNotNil(balance, "Balance should exist")
        XCTAssertEqual(balance?.currentXP, 480, "Should award 480 XP")
    }

    // MARK: - Helper Methods

    private func createMockVerification(timeMinutes: Int) -> TaskVerification {
        return TaskVerification(
            taskId: testTaskId,
            userId: testUserId,
            status: .pending,
            taskTitle: "Test Task",
            taskCategory: "Exercise",
            taskXPReward: timeMinutes,
            taskTimeMinutes: timeMinutes,
            completedAt: Date(),
            childName: "Test Child"
        )
    }
}

// MARK: - Mock Credibility Service for XP Testing

class MockCredibilityServiceForXP: CredibilityService {
    var mockScore: Int
    var mockHistory: [CredibilityHistoryEvent] = []
    var mockConsecutiveTasks: Int = 0
    var mockHasBonus: Bool = false
    var mockBonusExpiry: Date?

    init(initialScore: Int = 95) {
        self.mockScore = initialScore
    }

    var credibilityScore: Int {
        return mockScore
    }

    var credibilityHistory: [CredibilityHistoryEvent] {
        return mockHistory
    }

    var consecutiveApprovedTasks: Int {
        return mockConsecutiveTasks
    }

    var lastTaskUploadDate: Date? {
        return nil
    }

    var dailyStreak: Int {
        return 0
    }

    var hasRedemptionBonus: Bool {
        return mockHasBonus
    }

    var redemptionBonusExpiry: Date? {
        return mockBonusExpiry
    }

    func processDownvote(taskId: UUID, reviewerId: UUID, notes: String?) {
        mockScore = max(0, mockScore - 5)
    }

    func undoDownvote(taskId: UUID, reviewerId: UUID) {
        mockScore = min(100, mockScore + 5)
    }

    func processApprovedTask(taskId: UUID, reviewerId: UUID, notes: String?) {
        mockScore = min(100, mockScore + 1)
        mockConsecutiveTasks += 1
    }

    func processTaskUpload(taskId: UUID, userId: UUID) {
        // No-op for testing
    }

    func calculateXPToMinutes(xpAmount: Int) -> Int {
        return xpAmount
    }

    func getConversionRate() -> Double {
        return 1.0
    }

    func getCurrentTier() -> CredibilityTier {
        return CredibilityTier(
            name: "Test Tier",
            range: 0...100,
            multiplier: 1.0,
            color: "green",
            description: "Test"
        )
    }

    func getCredibilityStatus() -> CredibilityStatus {
        return CredibilityStatus(
            score: mockScore,
            tier: getCurrentTier(),
            consecutiveApprovedTasks: mockConsecutiveTasks,
            dailyStreak: 0,
            hasRedemptionBonus: mockHasBonus,
            redemptionBonusExpiry: mockBonusExpiry,
            history: mockHistory,
            conversionRate: 1.0,
            recoveryPath: nil
        )
    }

    func applyTimeBasedDecay() {
        // No-op for testing
    }
}
