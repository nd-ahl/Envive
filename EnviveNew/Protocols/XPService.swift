import Foundation

// MARK: - XP Service Protocol

protocol XPService {
    /// Calculate XP earned for a given time and credibility score
    func calculateXP(timeMinutes: Int, credibilityScore: Int) -> Int

    /// Get the credibility multiplier for a given score
    func credibilityMultiplier(score: Int) -> Double

    /// Get the credibility tier name
    func credibilityTierName(score: Int) -> String

    /// Get earning rate percentage (e.g., 90 for 0.9x)
    func earningRatePercentage(score: Int) -> Int

    /// Redeem XP for screen time minutes
    func redeemXP(amount: Int, userId: UUID, credibilityScore: Int) -> Result<RedemptionResult, RedemptionError>

    /// Get current XP balance for user
    func getBalance(userId: UUID) -> XPBalance?

    /// Get recent transactions for user
    func getRecentTransactions(userId: UUID, limit: Int) -> [XPTransaction]

    /// Get daily redemption status
    func getDailyStats(userId: UUID) -> DailyXPStats

    /// Award XP for completing a task
    func awardXP(userId: UUID, timeMinutes: Int, taskId: UUID, credibilityScore: Int) -> Int

    /// Grant XP directly (for emergency grants, bypasses credibility)
    func grantXPDirect(userId: UUID, amount: Int, reason: String) -> Bool
}

// MARK: - Daily XP Stats

struct DailyXPStats: Equatable {
    let earnedToday: Int
    let redeemedToday: Int
    let currentBalance: Int
    let credibilityScore: Int
    let earningRate: Double
}
