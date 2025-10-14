import XCTest
@testable import EnviveNew

final class XPRepositoryTests: XCTestCase {
    var sut: XPRepositoryImpl!
    var mockStorage: MockStorage!

    override func setUp() {
        super.setUp()
        mockStorage = MockStorage()
        sut = XPRepositoryImpl(storage: mockStorage)
    }

    override func tearDown() {
        mockStorage.clear()
        sut = nil
        mockStorage = nil
        super.tearDown()
    }

    // MARK: - Balance Tests

    func testGetBalance_NoExistingBalance_ReturnsNil() {
        // Arrange
        let userId = UUID()

        // Act
        let balance = sut.getBalance(userId: userId)

        // Assert
        XCTAssertNil(balance)
    }

    func testSaveBalance_PersistsBalance() {
        // Arrange
        let userId = UUID()
        let balance = XPBalance(userId: userId, currentXP: 100)

        // Act
        sut.saveBalance(balance)
        let retrieved = sut.getBalance(userId: userId)

        // Assert
        XCTAssertEqual(retrieved, balance)
    }

    func testCreateBalance_CreatesNewBalanceWithZeroXP() {
        // Arrange
        let userId = UUID()

        // Act
        let balance = sut.createBalance(userId: userId)

        // Assert
        XCTAssertEqual(balance.userId, userId)
        XCTAssertEqual(balance.currentXP, 0)
        XCTAssertEqual(balance.lifetimeEarned, 0)
        XCTAssertEqual(balance.lifetimeSpent, 0)
    }

    func testCreateBalance_PersistsNewBalance() {
        // Arrange
        let userId = UUID()

        // Act
        let created = sut.createBalance(userId: userId)
        let retrieved = sut.getBalance(userId: userId)

        // Assert
        XCTAssertEqual(retrieved, created)
    }

    // MARK: - Transaction Tests

    func testGetTransactions_NoTransactions_ReturnsEmptyArray() {
        // Arrange
        let userId = UUID()

        // Act
        let transactions = sut.getTransactions(userId: userId)

        // Assert
        XCTAssertTrue(transactions.isEmpty)
    }

    func testSaveTransaction_PersistsTransaction() {
        // Arrange
        let userId = UUID()
        let transaction = XPTransaction(
            userId: userId,
            type: .earned,
            amount: 30
        )

        // Act
        sut.saveTransaction(transaction)
        let retrieved = sut.getTransactions(userId: userId)

        // Assert
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first, transaction)
    }

    func testSaveTransaction_MultipleTransactions_PreservesOrder() {
        // Arrange
        let userId = UUID()
        let tx1 = XPTransaction(userId: userId, type: .earned, amount: 10)
        let tx2 = XPTransaction(userId: userId, type: .earned, amount: 20)
        let tx3 = XPTransaction(userId: userId, type: .redeemed, amount: 15)

        // Act
        sut.saveTransaction(tx1)
        sut.saveTransaction(tx2)
        sut.saveTransaction(tx3)
        let retrieved = sut.getTransactions(userId: userId)

        // Assert
        XCTAssertEqual(retrieved.count, 3)
        XCTAssertEqual(retrieved[0], tx1)
        XCTAssertEqual(retrieved[1], tx2)
        XCTAssertEqual(retrieved[2], tx3)
    }

    func testGetTransactions_WithLimit_ReturnsLimitedTransactions() {
        // Arrange
        let userId = UUID()
        for i in 1...10 {
            let tx = XPTransaction(userId: userId, type: .earned, amount: i)
            sut.saveTransaction(tx)
        }

        // Act
        let retrieved = sut.getTransactions(userId: userId, limit: 5)

        // Assert
        XCTAssertEqual(retrieved.count, 5)
        // Should return last 5 transactions
        XCTAssertEqual(retrieved.last?.amount, 10)
    }

    func testSaveTransaction_MoreThan1000Transactions_KeepsLast1000() {
        // Arrange
        let userId = UUID()

        // Act: Add 1100 transactions
        for i in 1...1100 {
            let tx = XPTransaction(userId: userId, type: .earned, amount: i)
            sut.saveTransaction(tx)
        }

        // Assert: Should only keep last 1000
        let retrieved = sut.getTransactions(userId: userId)
        XCTAssertEqual(retrieved.count, 1000)
        XCTAssertEqual(retrieved.first?.amount, 101)  // First 100 dropped
        XCTAssertEqual(retrieved.last?.amount, 1100)
    }

    // MARK: - Recent Transactions Tests

    func testGetRecentTransactions_WithinDays_ReturnsTransactions() {
        // Arrange
        let userId = UUID()
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: today)!
        let lastMonth = Calendar.current.date(byAdding: .day, value: -30, to: today)!

        let tx1 = XPTransaction(userId: userId, type: .earned, amount: 10, timestamp: today)
        let tx2 = XPTransaction(userId: userId, type: .earned, amount: 20, timestamp: yesterday)
        let tx3 = XPTransaction(userId: userId, type: .earned, amount: 30, timestamp: lastWeek)
        let tx4 = XPTransaction(userId: userId, type: .earned, amount: 40, timestamp: lastMonth)

        sut.saveTransaction(tx1)
        sut.saveTransaction(tx2)
        sut.saveTransaction(tx3)
        sut.saveTransaction(tx4)

        // Act: Get last 7 days
        let recent = sut.getRecentTransactions(userId: userId, days: 7)

        // Assert: Should include today, yesterday, and lastWeek (but not lastMonth)
        XCTAssertEqual(recent.count, 3)
        XCTAssertTrue(recent.contains(tx1))
        XCTAssertTrue(recent.contains(tx2))
        XCTAssertTrue(recent.contains(tx3))
        XCTAssertFalse(recent.contains(tx4))
    }

    // MARK: - Daily Totals Tests

    func testGetTotalEarnedToday_OnlyCountsToday() {
        // Arrange
        let userId = UUID()
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        let txToday1 = XPTransaction(userId: userId, type: .earned, amount: 30, timestamp: today)
        let txToday2 = XPTransaction(userId: userId, type: .earned, amount: 20, timestamp: today)
        let txYesterday = XPTransaction(userId: userId, type: .earned, amount: 50, timestamp: yesterday)

        sut.saveTransaction(txToday1)
        sut.saveTransaction(txToday2)
        sut.saveTransaction(txYesterday)

        // Act
        let total = sut.getTotalEarnedToday(userId: userId)

        // Assert
        XCTAssertEqual(total, 50, "Should only count today's earned XP (30 + 20)")
    }

    func testGetTotalRedeemedToday_OnlyCountsToday() {
        // Arrange
        let userId = UUID()
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        let txToday1 = XPTransaction(userId: userId, type: .redeemed, amount: 30, timestamp: today)
        let txToday2 = XPTransaction(userId: userId, type: .redeemed, amount: 20, timestamp: today)
        let txYesterday = XPTransaction(userId: userId, type: .redeemed, amount: 50, timestamp: yesterday)

        sut.saveTransaction(txToday1)
        sut.saveTransaction(txToday2)
        sut.saveTransaction(txYesterday)

        // Act
        let total = sut.getTotalRedeemedToday(userId: userId)

        // Assert
        XCTAssertEqual(total, 50, "Should only count today's redeemed XP (30 + 20)")
    }

    func testGetTotalEarnedToday_IgnoresRedemptions() {
        // Arrange
        let userId = UUID()
        let today = Date()

        let earned = XPTransaction(userId: userId, type: .earned, amount: 30, timestamp: today)
        let redeemed = XPTransaction(userId: userId, type: .redeemed, amount: 20, timestamp: today)

        sut.saveTransaction(earned)
        sut.saveTransaction(redeemed)

        // Act
        let total = sut.getTotalEarnedToday(userId: userId)

        // Assert
        XCTAssertEqual(total, 30, "Should only count earned, not redeemed")
    }

    func testGetTotalRedeemedToday_IgnoresEarnings() {
        // Arrange
        let userId = UUID()
        let today = Date()

        let earned = XPTransaction(userId: userId, type: .earned, amount: 30, timestamp: today)
        let redeemed = XPTransaction(userId: userId, type: .redeemed, amount: 20, timestamp: today)

        sut.saveTransaction(earned)
        sut.saveTransaction(redeemed)

        // Act
        let total = sut.getTotalRedeemedToday(userId: userId)

        // Assert
        XCTAssertEqual(total, 20, "Should only count redeemed, not earned")
    }

    // MARK: - Multiple Users Tests

    func testBalances_SeparatePerUser() {
        // Arrange
        let user1 = UUID()
        let user2 = UUID()
        let balance1 = XPBalance(userId: user1, currentXP: 100)
        let balance2 = XPBalance(userId: user2, currentXP: 200)

        // Act
        sut.saveBalance(balance1)
        sut.saveBalance(balance2)

        // Assert
        XCTAssertEqual(sut.getBalance(userId: user1)?.currentXP, 100)
        XCTAssertEqual(sut.getBalance(userId: user2)?.currentXP, 200)
    }

    func testTransactions_SeparatePerUser() {
        // Arrange
        let user1 = UUID()
        let user2 = UUID()
        let tx1 = XPTransaction(userId: user1, type: .earned, amount: 10)
        let tx2 = XPTransaction(userId: user2, type: .earned, amount: 20)

        // Act
        sut.saveTransaction(tx1)
        sut.saveTransaction(tx2)

        // Assert
        let user1Transactions = sut.getTransactions(userId: user1)
        let user2Transactions = sut.getTransactions(userId: user2)

        XCTAssertEqual(user1Transactions.count, 1)
        XCTAssertEqual(user2Transactions.count, 1)
        XCTAssertEqual(user1Transactions.first?.amount, 10)
        XCTAssertEqual(user2Transactions.first?.amount, 20)
    }
}
