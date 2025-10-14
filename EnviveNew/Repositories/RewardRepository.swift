import Foundation

protocol RewardRepository {
    func saveEarnedMinutes(_ minutes: Int)
    func loadEarnedMinutes() -> Int
}

final class RewardRepositoryImpl: RewardRepository {
    private let storage: StorageService
    private let earnedMinutesKey = "earnedScreenTimeMinutes"

    init(storage: StorageService) {
        self.storage = storage
    }

    func saveEarnedMinutes(_ minutes: Int) {
        storage.saveInt(minutes, forKey: earnedMinutesKey)
    }

    func loadEarnedMinutes() -> Int {
        storage.loadInt(forKey: earnedMinutesKey, defaultValue: 0)
    }
}
