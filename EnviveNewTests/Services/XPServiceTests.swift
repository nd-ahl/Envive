import XCTest
@testable import EnviveNew

final class XPServiceTests: XCTestCase {
    var sut: XPServiceImpl!
    var mockRepository: MockXPRepository!
    var mockCredibilityService: MockCredibilityService!

    override func setUp() {
        super.setUp()
        mockRepository = MockXPRepository()
        mockCredibilityService = MockCredibilityService()
        sut = XPServiceImpl(
            repository: mockRepository,
            credibilityService: mockCredibilityService
        )
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        mockCredibilityService = nil
        super.tearDown()
    }

    // MARK: - XP Calculation Tests

    func testCalculateXP_ExcellentCredibility_FullXP() {
        // Arrange
        let timeMinutes = 30
        let credibilityScore = 100

        // Act
        let xp = sut.calculateXP(timeMinutes: timeMinutes, credibilityScore: credibilityScore)

        // Assert
        XCTAssertEqual(xp, 30, "At 100 credibility, should earn full XP (1 XP per minute)")
    }

    func testCalculateXP_GoodCredibility_90PercentXP() {
        // Arrange
        let timeMinutes = 30
        let credibilityScore = 85

        // Act
        let xp = sut.calculateXP(timeMinutes: timeMinutes, credibilityScore: credibilityScore)

        // Assert
        XCTAssertEqual(xp, 27, "At 85 credibility (Good), should earn 90% XP (27 XP)")
    }

    func testCalculateXP_FairCredibility_75PercentXP() {
        // Arrange
        let timeMinutes = 30
        let credibilityScore = 70

        // Act
        let xp = sut.calculateXP(timeMinutes: timeMinutes, credibilityScore: credibilityScore)

        // Assert
        XCTAssertEqual(xp, 23, "At 70 credibility (Fair), should earn 75% XP, rounded up to 23")
    }

    func testCalculateXP_PoorCredibility_50PercentXP() {
        // Arrange
        let timeMinutes = 30
        let credibilityScore = 50

        // Act
        let xp = sut.calculateXP(timeMinutes: timeMinutes, credibilityScore: credibilityScore)

        // Assert
        XCTAssertEqual(xp, 15, "At 50 credibility (Poor), should earn 50% XP (15 XP)")
    }

    func testCalculateXP_CriticalCredibility_25PercentXP() {
        // Arrange
        let timeMinutes = 30
        let credibilityScore = 30

        // Act
        let xp = sut.calculateXP(timeMinutes: timeMinutes, credibilityScore: credibilityScore)

        // Assert
        XCTAssertEqual(xp, 8, "At 30 credibility (Critical), should earn 25% XP, rounded up to 8")
    }

    func testCalculateXP_RoundsUp_GenerousToKid() {
        // Arrange
        let timeMinutes = 13
        let credibilityScore = 90  // 0.9x multiplier

        // Act
        let xp = sut.calculateXP(timeMinutes: timeMinutes, credibilityScore: credibilityScore)

        // Assert
        // 13 * 0.9 = 11.7, should round up to 12
        XCTAssertEqual(xp, 12, "Should round up from 11.7 to 12 XP (generous)")
    }

    func testCalculateXP_MinimumOneXP() {
        // Arrange
        let timeMinutes = 1
        let credibilityScore = 30  // 0.25x multiplier

        // Act
        let xp = sut.calculateXP(timeMinutes: timeMinutes, credibilityScore: credibilityScore)

        // Assert
        // 1 * 0.25 = 0.25, should round up to 1 (minimum)
        XCTAssertEqual(xp, 1, "Should earn minimum of 1 XP per task")
    }

    func testCalculateXP_ZeroTime_ReturnsZero() {
        // Arrange
        let timeMinutes = 0
        let credibilityScore = 100

        // Act
        let xp = sut.calculateXP(timeMinutes: timeMinutes, credibilityScore: credibilityScore)

        // Assert
        XCTAssertEqual(xp, 0, "Zero time should return zero XP")
    }

    // MARK: - Credibility Multiplier Tests

    func testCredibilityMultiplier_95To100_Returns1Point0() {
        XCTAssertEqual(sut.credibilityMultiplier(score: 100), 1.0)
        XCTAssertEqual(sut.credibilityMultiplier(score: 95), 1.0)
    }

    func testCredibilityMultiplier_80To94_Returns0Point9() {
        XCTAssertEqual(sut.credibilityMultiplier(score: 94), 0.9)
        XCTAssertEqual(sut.credibilityMultiplier(score: 85), 0.9)
        XCTAssertEqual(sut.credibilityMultiplier(score: 80), 0.9)
    }

    func testCredibilityMultiplier_60To79_Returns0Point75() {
        XCTAssertEqual(sut.credibilityMultiplier(score: 79), 0.75)
        XCTAssertEqual(sut.credibilityMultiplier(score: 70), 0.75)
        XCTAssertEqual(sut.credibilityMultiplier(score: 60), 0.75)
    }

    func testCredibilityMultiplier_40To59_Returns0Point5() {
        XCTAssertEqual(sut.credibilityMultiplier(score: 59), 0.5)
        XCTAssertEqual(sut.credibilityMultiplier(score: 50), 0.5)
        XCTAssertEqual(sut.credibilityMultiplier(score: 40), 0.5)
    }

    func testCredibilityMultiplier_0To39_Returns0Point25() {
        XCTAssertEqual(sut.credibilityMultiplier(score: 39), 0.25)
        XCTAssertEqual(sut.credibilityMultiplier(score: 20), 0.25)
        XCTAssertEqual(sut.credibilityMultiplier(score: 0), 0.25)
    }

    // MARK: - Credibility Tier Tests

    func testCredibilityTierName_Excellent() {
        XCTAssertEqual(sut.credibilityTierName(score: 100), "Excellent")
        XCTAssertEqual(sut.credibilityTierName(score: 95), "Excellent")
    }

    func testCredibilityTierName_Good() {
        XCTAssertEqual(sut.credibilityTierName(score: 90), "Good")
        XCTAssertEqual(sut.credibilityTierName(score: 80), "Good")
    }

    func testCredibilityTierName_Fair() {
        XCTAssertEqual(sut.credibilityTierName(score: 70), "Fair")
        XCTAssertEqual(sut.credibilityTierName(score: 60), "Fair")
    }

    func testCredibilityTierName_Poor() {
        XCTAssertEqual(sut.credibilityTierName(score: 50), "Poor")
        XCTAssertEqual(sut.credibilityTierName(score: 40), "Poor")
    }

    func testCredibilityTierName_Critical() {
        XCTAssertEqual(sut.credibilityTierName(score: 30), "Critical")
        XCTAssertEqual(sut.credibilityTierName(score: 0), "Critical")
    }

    func testEarningRatePercentage() {
        XCTAssertEqual(sut.earningRatePercentage(score: 100), 100)
        XCTAssertEqual(sut.earningRatePercentage(score: 90), 90)
        XCTAssertEqual(sut.earningRatePercentage(score: 70), 75)
        XCTAssertEqual(sut.earningRatePercentage(score: 50), 50)
        XCTAssertEqual(sut.earningRatePercentage(score: 30), 25)
    }

    // MARK: - XP Redemption Tests

    func testRedeemXP_Success_DeductsXPAndGrantsMinutes() {
        // Arrange
        let userId = UUID()
        let redemptionAmount = 60
        mockRepository.balance = XPBalance(userId: userId, currentXP: 100)
        mockCredibilityService.credibilityScore = 100

        // Act
        let result = sut.redeemXP(
            amount: redemptionAmount,
            userId: userId,
            credibilityScore: mockCredibilityService.credibilityScore
        )

        // Assert
        switch result {
        case .success(let redemptionResult):
            XCTAssertTrue(redemptionResult.success)
            XCTAssertEqual(redemptionResult.minutesGranted, 60, "1 XP = 1 minute")
            XCTAssertEqual(redemptionResult.xpSpent, 60)
            XCTAssertEqual(redemptionResult.newBalance, 40)
            XCTAssertTrue(mockRepository.saveBalanceCalled)
            XCTAssertTrue(mockRepository.saveTransactionCalled)
        case .failure:
            XCTFail("Expected success, got failure")
        }
    }

    func testRedeemXP_InsufficientBalance_ReturnsError() {
        // Arrange
        let userId = UUID()
        mockRepository.balance = XPBalance(userId: userId, currentXP: 30)

        // Act
        let result = sut.redeemXP(amount: 50, userId: userId, credibilityScore: 100)

        // Assert
        switch result {
        case .success:
            XCTFail("Expected failure, got success")
        case .failure(let error):
            XCTAssertEqual(error, .insufficientXP)
        }
    }

    func testRedeemXP_InvalidAmount_ReturnsError() {
        // Arrange
        let userId = UUID()
        mockRepository.balance = XPBalance(userId: userId, currentXP: 100)

        // Act
        let result = sut.redeemXP(amount: 0, userId: userId, credibilityScore: 100)

        // Assert
        switch result {
        case .success:
            XCTFail("Expected failure, got success")
        case .failure(let error):
            XCTAssertEqual(error, .invalidAmount)
        }
    }

    func testRedeemXP_CreatesNewBalanceIfNotExists() {
        // Arrange
        let userId = UUID()
        mockRepository.balance = nil  // No existing balance

        // Act
        let result = sut.redeemXP(amount: 10, userId: userId, credibilityScore: 100)

        // Assert
        // Should create new balance with 0 XP, then fail because insufficient
        switch result {
        case .success:
            XCTFail("Expected failure due to insufficient XP")
        case .failure(let error):
            XCTAssertEqual(error, .insufficientXP)
            XCTAssertTrue(mockRepository.createBalanceCalled)
        }
    }

    // MARK: - Get Balance Tests

    func testGetBalance_ReturnsBalance() {
        // Arrange
        let userId = UUID()
        let expectedBalance = XPBalance(userId: userId, currentXP: 150)
        mockRepository.balance = expectedBalance

        // Act
        let balance = sut.getBalance(userId: userId)

        // Assert
        XCTAssertEqual(balance, expectedBalance)
    }

    func testGetBalance_NoBalance_ReturnsNil() {
        // Arrange
        let userId = UUID()
        mockRepository.balance = nil

        // Act
        let balance = sut.getBalance(userId: userId)

        // Assert
        XCTAssertNil(balance)
    }

    // MARK: - Get Recent Transactions Tests

    func testGetRecentTransactions_ReturnsLimitedTransactions() {
        // Arrange
        let userId = UUID()
        let transactions = [
            XPTransaction(userId: userId, type: .earned, amount: 10),
            XPTransaction(userId: userId, type: .earned, amount: 20),
            XPTransaction(userId: userId, type: .redeemed, amount: 15)
        ]
        mockRepository.transactions = transactions

        // Act
        let recent = sut.getRecentTransactions(userId: userId, limit: 10)

        // Assert
        XCTAssertEqual(recent.count, 3)
    }

    // MARK: - Award XP Tests

    func testAwardXP_CreatesTransactionAndUpdatesBalance() {
        // Arrange
        let userId = UUID()
        let taskId = UUID()
        mockRepository.balance = XPBalance(userId: userId, currentXP: 50)
        mockCredibilityService.credibilityScore = 100

        // Act
        let earnedXP = sut.awardXP(
            userId: userId,
            timeMinutes: 30,
            taskId: taskId,
            credibilityScore: 100
        )

        // Assert
        XCTAssertEqual(earnedXP, 30)
        XCTAssertTrue(mockRepository.saveBalanceCalled)
        XCTAssertTrue(mockRepository.saveTransactionCalled)
    }

    func testAwardXP_WithLowCredibility_ReducedXP() {
        // Arrange
        let userId = UUID()
        let taskId = UUID()
        mockRepository.balance = XPBalance(userId: userId, currentXP: 50)

        // Act
        let earnedXP = sut.awardXP(
            userId: userId,
            timeMinutes: 30,
            taskId: taskId,
            credibilityScore: 50  // Poor credibility (50% rate)
        )

        // Assert
        XCTAssertEqual(earnedXP, 15, "At 50 credibility, should earn 50% XP (15 XP)")
    }

    // MARK: - Daily Stats Tests

    func testGetDailyStats_ReturnsCorrectStats() {
        // Arrange
        let userId = UUID()
        mockRepository.balance = XPBalance(userId: userId, currentXP: 100)
        mockRepository.totalEarnedToday = 50
        mockRepository.totalRedeemedToday = 30
        mockCredibilityService.credibilityScore = 95

        // Act
        let stats = sut.getDailyStats(userId: userId)

        // Assert
        XCTAssertEqual(stats.earnedToday, 50)
        XCTAssertEqual(stats.redeemedToday, 30)
        XCTAssertEqual(stats.currentBalance, 100)
        XCTAssertEqual(stats.credibilityScore, 95)
        XCTAssertEqual(stats.earningRate, 1.0)
    }
}

// MARK: - Mock XP Repository

final class MockXPRepository: XPRepository {
    var balance: XPBalance?
    var transactions: [XPTransaction] = []
    var totalEarnedToday: Int = 0
    var totalRedeemedToday: Int = 0

    var getBalanceCalled = false
    var saveBalanceCalled = false
    var createBalanceCalled = false
    var saveTransactionCalled = false

    func getBalance(userId: UUID) -> XPBalance? {
        getBalanceCalled = true
        return balance
    }

    func saveBalance(_ balance: XPBalance) {
        saveBalanceCalled = true
        self.balance = balance
    }

    func createBalance(userId: UUID) -> XPBalance {
        createBalanceCalled = true
        let newBalance = XPBalance(userId: userId)
        self.balance = newBalance
        return newBalance
    }

    func getTransactions(userId: UUID, limit: Int?) -> [XPTransaction] {
        if let limit = limit {
            return Array(transactions.suffix(limit))
        }
        return transactions
    }

    func saveTransaction(_ transaction: XPTransaction) {
        saveTransactionCalled = true
        transactions.append(transaction)
    }

    func getRecentTransactions(userId: UUID, days: Int) -> [XPTransaction] {
        return transactions
    }

    func getTotalEarnedToday(userId: UUID) -> Int {
        return totalEarnedToday
    }

    func getTotalRedeemedToday(userId: UUID) -> Int {
        return totalRedeemedToday
    }
}
