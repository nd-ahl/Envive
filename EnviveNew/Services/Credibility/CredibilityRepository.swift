import Foundation

final class CredibilityRepository {
    private let storage: StorageService

    private enum KeyPrefix {
        static let score = "userCredibilityScore"
        static let history = "userCredibilityHistory"
        static let consecutiveTasks = "consecutiveApprovedTasks"
        static let hasBonus = "hasRedemptionBonus"
        static let bonusExpiry = "redemptionBonusExpiry"
        static let lastUploadDate = "lastTaskUploadDate"
        static let dailyStreak = "dailyTaskStreak"
    }

    init(storage: StorageService) {
        self.storage = storage
    }

    // MARK: - User-specific keys

    private func scoreKey(for childId: UUID) -> String {
        "\(KeyPrefix.score)_\(childId.uuidString)"
    }

    private func historyKey(for childId: UUID) -> String {
        "\(KeyPrefix.history)_\(childId.uuidString)"
    }

    private func consecutiveTasksKey(for childId: UUID) -> String {
        "\(KeyPrefix.consecutiveTasks)_\(childId.uuidString)"
    }

    private func hasBonusKey(for childId: UUID) -> String {
        "\(KeyPrefix.hasBonus)_\(childId.uuidString)"
    }

    private func bonusExpiryKey(for childId: UUID) -> String {
        "\(KeyPrefix.bonusExpiry)_\(childId.uuidString)"
    }

    private func lastUploadDateKey(for childId: UUID) -> String {
        "\(KeyPrefix.lastUploadDate)_\(childId.uuidString)"
    }

    private func dailyStreakKey(for childId: UUID) -> String {
        "\(KeyPrefix.dailyStreak)_\(childId.uuidString)"
    }

    func saveScore(_ score: Int, childId: UUID) {
        storage.saveInt(score, forKey: scoreKey(for: childId))
    }

    func loadScore(childId: UUID, defaultValue: Int = 100) -> Int {
        storage.loadInt(forKey: scoreKey(for: childId), defaultValue: defaultValue)
    }

    func saveHistory(_ history: [CredibilityHistoryEvent], childId: UUID) {
        storage.save(history, forKey: historyKey(for: childId))
    }

    func loadHistory(childId: UUID) -> [CredibilityHistoryEvent] {
        storage.load(forKey: historyKey(for: childId)) ?? []
    }

    func saveConsecutiveTasks(_ count: Int, childId: UUID) {
        storage.saveInt(count, forKey: consecutiveTasksKey(for: childId))
    }

    func loadConsecutiveTasks(childId: UUID) -> Int {
        storage.loadInt(forKey: consecutiveTasksKey(for: childId), defaultValue: 0)
    }

    func saveRedemptionBonus(active: Bool, expiry: Date?, childId: UUID) {
        storage.saveBool(active, forKey: hasBonusKey(for: childId))
        if let expiry = expiry {
            storage.saveDate(expiry, forKey: bonusExpiryKey(for: childId))
        } else {
            storage.remove(forKey: bonusExpiryKey(for: childId))
        }
    }

    func loadRedemptionBonus(childId: UUID) -> (active: Bool, expiry: Date?) {
        let active = storage.loadBool(forKey: hasBonusKey(for: childId))
        let expiry = storage.loadDate(forKey: bonusExpiryKey(for: childId))
        return (active, expiry)
    }

    func saveLastUploadDate(_ date: Date?, childId: UUID) {
        if let date = date {
            storage.saveDate(date, forKey: lastUploadDateKey(for: childId))
        } else {
            storage.remove(forKey: lastUploadDateKey(for: childId))
        }
    }

    func loadLastUploadDate(childId: UUID) -> Date? {
        storage.loadDate(forKey: lastUploadDateKey(for: childId))
    }

    func saveDailyStreak(_ streak: Int, childId: UUID) {
        storage.saveInt(streak, forKey: dailyStreakKey(for: childId))
    }

    func loadDailyStreak(childId: UUID) -> Int {
        storage.loadInt(forKey: dailyStreakKey(for: childId), defaultValue: 0)
    }

    // MARK: - Test Utilities

    func resetCredibility(childId: UUID) {
        saveScore(100, childId: childId)
        storage.save([] as [CredibilityHistoryEvent], forKey: historyKey(for: childId))
        storage.saveInt(0, forKey: consecutiveTasksKey(for: childId))
        storage.saveBool(false, forKey: hasBonusKey(for: childId))
        storage.remove(forKey: bonusExpiryKey(for: childId))
        storage.remove(forKey: lastUploadDateKey(for: childId))
        storage.saveInt(0, forKey: dailyStreakKey(for: childId))
        print("🗑️ Reset credibility to 100 for child: \(childId)")
    }
}
