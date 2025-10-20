import Foundation

final class CredibilityRepository {
    private let storage: StorageService

    private enum Keys {
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

    func saveScore(_ score: Int) {
        storage.saveInt(score, forKey: Keys.score)
    }

    func loadScore(defaultValue: Int = 100) -> Int {
        storage.loadInt(forKey: Keys.score, defaultValue: defaultValue)
    }

    func saveHistory(_ history: [CredibilityHistoryEvent]) {
        storage.save(history, forKey: Keys.history)
    }

    func loadHistory() -> [CredibilityHistoryEvent] {
        storage.load(forKey: Keys.history) ?? []
    }

    func saveConsecutiveTasks(_ count: Int) {
        storage.saveInt(count, forKey: Keys.consecutiveTasks)
    }

    func loadConsecutiveTasks() -> Int {
        storage.loadInt(forKey: Keys.consecutiveTasks, defaultValue: 0)
    }

    func saveRedemptionBonus(active: Bool, expiry: Date?) {
        storage.saveBool(active, forKey: Keys.hasBonus)
        if let expiry = expiry {
            storage.saveDate(expiry, forKey: Keys.bonusExpiry)
        } else {
            storage.remove(forKey: Keys.bonusExpiry)
        }
    }

    func loadRedemptionBonus() -> (active: Bool, expiry: Date?) {
        let active = storage.loadBool(forKey: Keys.hasBonus)
        let expiry = storage.loadDate(forKey: Keys.bonusExpiry)
        return (active, expiry)
    }

    func saveLastUploadDate(_ date: Date?) {
        if let date = date {
            storage.saveDate(date, forKey: Keys.lastUploadDate)
        } else {
            storage.remove(forKey: Keys.lastUploadDate)
        }
    }

    func loadLastUploadDate() -> Date? {
        storage.loadDate(forKey: Keys.lastUploadDate)
    }

    func saveDailyStreak(_ streak: Int) {
        storage.saveInt(streak, forKey: Keys.dailyStreak)
    }

    func loadDailyStreak() -> Int {
        storage.loadInt(forKey: Keys.dailyStreak, defaultValue: 0)
    }
}
