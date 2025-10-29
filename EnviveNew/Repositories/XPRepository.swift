import Foundation

// MARK: - XP Repository Protocol

protocol XPRepository {
    func getBalance(userId: UUID) -> XPBalance?
    func saveBalance(_ balance: XPBalance)
    func createBalance(userId: UUID) -> XPBalance
    func getTransactions(userId: UUID, limit: Int?) -> [XPTransaction]
    func saveTransaction(_ transaction: XPTransaction)
    func getRecentTransactions(userId: UUID, days: Int) -> [XPTransaction]
    func getTotalEarnedToday(userId: UUID) -> Int
    func getTotalRedeemedToday(userId: UUID) -> Int

    // Test utilities
    func resetBalance(userId: UUID)
    func deleteAllTransactions(userId: UUID)
}

// MARK: - XP Repository Implementation

final class XPRepositoryImpl: XPRepository {
    private let storage: StorageService

    // Storage keys
    private let balanceKeyPrefix = "xp_balance_"
    private let transactionsKeyPrefix = "xp_transactions_"

    init(storage: StorageService) {
        self.storage = storage
    }

    // MARK: - Balance Methods

    func getBalance(userId: UUID) -> XPBalance? {
        let key = balanceKey(for: userId)
        let balance: XPBalance? = storage.load(forKey: key)
        if let balance = balance {
            print("📂 XPRepository: Loaded balance for user \(userId.uuidString): \(balance.currentXP) XP")
        } else {
            print("📂 XPRepository: No balance found for user \(userId.uuidString)")
        }
        return balance
    }

    func saveBalance(_ balance: XPBalance) {
        let key = balanceKey(for: balance.userId)
        print("💾 XPRepository: Saving balance for user \(balance.userId.uuidString): \(balance.currentXP) XP")
        storage.save(balance, forKey: key)
        print("💾 XPRepository: Balance saved successfully")
    }

    func createBalance(userId: UUID) -> XPBalance {
        let balance = XPBalance(userId: userId)
        saveBalance(balance)
        return balance
    }

    // MARK: - Transaction Methods

    func getTransactions(userId: UUID, limit: Int? = nil) -> [XPTransaction] {
        let key = transactionsKey(for: userId)
        guard let transactions: [XPTransaction] = storage.load(forKey: key) else {
            return []
        }

        if let limit = limit {
            return Array(transactions.suffix(limit))
        }
        return transactions
    }

    func saveTransaction(_ transaction: XPTransaction) {
        let key = transactionsKey(for: transaction.userId)
        var transactions: [XPTransaction] = storage.load(forKey: key) ?? []

        transactions.append(transaction)

        // Keep only last 1000 transactions to prevent storage bloat
        if transactions.count > 1000 {
            transactions = Array(transactions.suffix(1000))
        }

        storage.save(transactions, forKey: key)
    }

    func getRecentTransactions(userId: UUID, days: Int) -> [XPTransaction] {
        let transactions = getTransactions(userId: userId)
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        return transactions.filter { $0.timestamp >= cutoffDate }
    }

    func getTotalEarnedToday(userId: UUID) -> Int {
        let todayTransactions = getTodayTransactions(userId: userId)
        return todayTransactions
            .filter { $0.type == .earned }
            .reduce(0) { $0 + $1.amount }
    }

    func getTotalRedeemedToday(userId: UUID) -> Int {
        let todayTransactions = getTodayTransactions(userId: userId)
        return todayTransactions
            .filter { $0.type == .redeemed }
            .reduce(0) { $0 + $1.amount }
    }

    // MARK: - Test Utilities

    func resetBalance(userId: UUID) {
        let balance = XPBalance(userId: userId)
        saveBalance(balance)
        print("🗑️ Reset XP balance to 0 for user: \(userId)")
    }

    func deleteAllTransactions(userId: UUID) {
        let key = transactionsKey(for: userId)
        storage.save([] as [XPTransaction], forKey: key)
        print("🗑️ Deleted all XP transactions for user: \(userId)")
    }

    // MARK: - Private Helpers

    private func balanceKey(for userId: UUID) -> String {
        return "\(balanceKeyPrefix)\(userId.uuidString)"
    }

    private func transactionsKey(for userId: UUID) -> String {
        return "\(transactionsKeyPrefix)\(userId.uuidString)"
    }

    private func getTodayTransactions(userId: UUID) -> [XPTransaction] {
        let transactions = getTransactions(userId: userId)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return transactions.filter { transaction in
            let transactionDay = calendar.startOfDay(for: transaction.timestamp)
            return transactionDay == today
        }
    }
}
