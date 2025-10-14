import Foundation

protocol RewardService {
    var earnedMinutes: Int { get }
    var isScreenTimeActive: Bool { get }
    var remainingSessionMinutes: Int { get }

    func redeemXPForScreenTime(xpAmount: Int) -> Int
    func startScreenTimeSession(durationMinutes: Int) -> Bool
    func endScreenTimeSession()
    func addBonusMinutes(_ minutes: Int, reason: String)
}
