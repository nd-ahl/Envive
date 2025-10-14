import XCTest
@testable import EnviveNew

// MARK: - Starter Bonus Service Tests

class StarterBonusServiceTests: XCTestCase {
    var starterBonusService: StarterBonusServiceImpl!
    var xpRepository: XPRepositoryImpl!
    var storage: MockStorage!

    let testUserId = UUID()

    override func setUp() {
        super.setUp()

        storage = MockStorage()
        xpRepository = XPRepositoryImpl(storage: storage)
        starterBonusService = StarterBonusServiceImpl(
            xpRepository: xpRepository,
            storage: storage
        )
    }

    override func tearDown() {
        starterBonusService = nil
        xpRepository = nil
        storage = nil
        super.tearDown()
    }

    // MARK: - Grant Starter Bonus Tests

    func testGrantStarterBonus_ForNewUser_Succeeds() {
        // Arrange
        XCTAssertFalse(starterBonusService.hasReceivedStarterBonus(userId: testUserId),
                      "User should not have received bonus yet")

        // Act
        let result = starterBonusService.grantStarterBonus(userId: testUserId)

        // Assert
        switch result {
        case .success(let bonusResult):
            XCTAssertEqual(bonusResult.userId, testUserId, "Result should have correct user ID")
            XCTAssertEqual(bonusResult.amountGranted, 30, "Should grant 30 XP")
            XCTAssertFalse(bonusResult.message.isEmpty, "Should have a message")

        case .failure(let error):
            XCTFail("Should succeed but failed with: \(error)")
        }

        // Verify balance was updated
        let balance = xpRepository.getBalance(userId: testUserId)
        XCTAssertNotNil(balance, "Balance should be created")
        XCTAssertEqual(balance?.currentXP, 30, "Should have 30 XP")
        XCTAssertEqual(balance?.lifetimeEarned, 30, "Lifetime earned should be 30")

        // Verify bonus was recorded
        XCTAssertTrue(starterBonusService.hasReceivedStarterBonus(userId: testUserId),
                     "User should be marked as having received bonus")
    }

    func testGrantStarterBonus_ForExistingUser_FailsWithAlreadyReceived() {
        // Arrange - Grant bonus once
        _ = starterBonusService.grantStarterBonus(userId: testUserId)

        // Act - Try to grant again
        let result = starterBonusService.grantStarterBonus(userId: testUserId)

        // Assert
        switch result {
        case .success:
            XCTFail("Should fail with alreadyReceived error")

        case .failure(let error):
            XCTAssertEqual(error, .alreadyReceived, "Should fail with alreadyReceived error")
        }

        // Balance should still be 30 (not 60)
        let balance = xpRepository.getBalance(userId: testUserId)
        XCTAssertEqual(balance?.currentXP, 30, "Balance should not have doubled")
    }

    func testGrantStarterBonus_CreatesBalanceIfNotExists() {
        // Arrange
        XCTAssertNil(xpRepository.getBalance(userId: testUserId), "Balance should not exist yet")

        // Act
        let result = starterBonusService.grantStarterBonus(userId: testUserId)

        // Assert
        XCTAssertTrue(result.isSuccess, "Should succeed")

        let balance = xpRepository.getBalance(userId: testUserId)
        XCTAssertNotNil(balance, "Balance should be created")
        XCTAssertEqual(balance?.userId, testUserId, "Balance should be for correct user")
    }

    func testGrantStarterBonus_AddsToExistingBalance() {
        // Arrange - Create existing balance
        var existingBalance = XPBalance(userId: testUserId)
        existingBalance.currentXP = 50
        existingBalance.lifetimeEarned = 50
        xpRepository.saveBalance(existingBalance)

        // Act
        let result = starterBonusService.grantStarterBonus(userId: testUserId)

        // Assert
        XCTAssertTrue(result.isSuccess, "Should succeed")

        let balance = xpRepository.getBalance(userId: testUserId)
        XCTAssertNotNil(balance, "Balance should exist")
        XCTAssertEqual(balance?.currentXP, 80, "Should add 30 to existing 50")
        XCTAssertEqual(balance?.lifetimeEarned, 80, "Lifetime should be 80")
    }

    // MARK: - Has Received Bonus Tests

    func testHasReceivedStarterBonus_ForNewUser_ReturnsFalse() {
        // Act
        let hasReceived = starterBonusService.hasReceivedStarterBonus(userId: testUserId)

        // Assert
        XCTAssertFalse(hasReceived, "New user should not have received bonus")
    }

    func testHasReceivedStarterBonus_AfterGranting_ReturnsTrue() {
        // Arrange
        _ = starterBonusService.grantStarterBonus(userId: testUserId)

        // Act
        let hasReceived = starterBonusService.hasReceivedStarterBonus(userId: testUserId)

        // Assert
        XCTAssertTrue(hasReceived, "Should return true after granting bonus")
    }

    func testHasReceivedStarterBonus_DifferentUsers_TrackedSeparately() {
        // Arrange
        let user1 = UUID()
        let user2 = UUID()

        // Act - Grant bonus to user1 only
        _ = starterBonusService.grantStarterBonus(userId: user1)

        // Assert
        XCTAssertTrue(starterBonusService.hasReceivedStarterBonus(userId: user1),
                     "User1 should have received bonus")
        XCTAssertFalse(starterBonusService.hasReceivedStarterBonus(userId: user2),
                      "User2 should not have received bonus")
    }

    // MARK: - Get Starter Bonus Info Tests

    func testGetStarterBonusInfo_ReturnsDefaultInfo() {
        // Act
        let info = starterBonusService.getStarterBonusInfo()

        // Assert
        XCTAssertEqual(info.amount, 30, "Default amount should be 30")
        XCTAssertFalse(info.description.isEmpty, "Should have a description")
        XCTAssertFalse(info.icon.isEmpty, "Should have an icon")
    }

    // MARK: - Multiple Users Tests

    func testGrantStarterBonus_MultipleUsers_AllReceiveBonus() {
        // Arrange
        let user1 = UUID()
        let user2 = UUID()
        let user3 = UUID()

        // Act
        let result1 = starterBonusService.grantStarterBonus(userId: user1)
        let result2 = starterBonusService.grantStarterBonus(userId: user2)
        let result3 = starterBonusService.grantStarterBonus(userId: user3)

        // Assert
        XCTAssertTrue(result1.isSuccess, "User1 should receive bonus")
        XCTAssertTrue(result2.isSuccess, "User2 should receive bonus")
        XCTAssertTrue(result3.isSuccess, "User3 should receive bonus")

        // All should have 30 XP
        XCTAssertEqual(xpRepository.getBalance(userId: user1)?.currentXP, 30)
        XCTAssertEqual(xpRepository.getBalance(userId: user2)?.currentXP, 30)
        XCTAssertEqual(xpRepository.getBalance(userId: user3)?.currentXP, 30)

        // All should be marked as received
        XCTAssertTrue(starterBonusService.hasReceivedStarterBonus(userId: user1))
        XCTAssertTrue(starterBonusService.hasReceivedStarterBonus(userId: user2))
        XCTAssertTrue(starterBonusService.hasReceivedStarterBonus(userId: user3))
    }

    // MARK: - Persistence Tests

    func testStarterBonus_PersistsAcrossServiceInstances() {
        // Arrange - Grant bonus with first service instance
        _ = starterBonusService.grantStarterBonus(userId: testUserId)

        // Act - Create new service instance with same storage
        let newService = StarterBonusServiceImpl(
            xpRepository: xpRepository,
            storage: storage
        )

        // Assert
        XCTAssertTrue(newService.hasReceivedStarterBonus(userId: testUserId),
                     "Bonus should persist across service instances")

        // Trying to grant again should fail
        let result = newService.grantStarterBonus(userId: testUserId)
        XCTAssertTrue(result.isFailure, "Should not be able to grant bonus again")
    }

    // MARK: - Edge Cases

    func testGrantStarterBonus_ConcurrentCalls_OnlyGrantsOnce() {
        // This is a simplified test - in production, would need proper thread safety testing
        // Act
        let result1 = starterBonusService.grantStarterBonus(userId: testUserId)
        let result2 = starterBonusService.grantStarterBonus(userId: testUserId)

        // Assert
        XCTAssertTrue(result1.isSuccess, "First call should succeed")
        XCTAssertTrue(result2.isFailure, "Second call should fail")

        let balance = xpRepository.getBalance(userId: testUserId)
        XCTAssertEqual(balance?.currentXP, 30, "Should only have 30 XP, not 60")
    }
}

// MARK: - Result Extension for Testing

extension Result {
    var isSuccess: Bool {
        switch self {
        case .success: return true
        case .failure: return false
        }
    }

    var isFailure: Bool {
        return !isSuccess
    }
}
