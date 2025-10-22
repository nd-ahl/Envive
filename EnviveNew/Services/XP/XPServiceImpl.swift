import Foundation

// MARK: - XP Service Implementation

final class XPServiceImpl: XPService {
    private let repository: XPRepository
    private let credibilityService: CredibilityService

    // MARK: - Initializer

    init(repository: XPRepository, credibilityService: CredibilityService) {
        self.repository = repository
        self.credibilityService = credibilityService
    }

    // MARK: - XP Calculation

    func calculateXP(timeMinutes: Int, credibilityScore: Int) -> Int {
        guard timeMinutes > 0 else { return 0 }

        // Base rate: 1 XP per minute
        let baseXP = Double(timeMinutes)

        // Apply credibility multiplier
        let multiplier = credibilityMultiplier(score: credibilityScore)
        let rawXP = baseXP * multiplier

        // Always round UP (generous to the kid)
        let finalXP = Int(ceil(rawXP))

        // Ensure minimum of 1 XP per task
        return max(finalXP, 1)
    }

    func credibilityMultiplier(score: Int) -> Double {
        // SIMPLIFIED: Credibility score directly = earning percentage
        // 100 credibility = 100% XP (1.0x)
        // 90 credibility = 90% XP (0.9x)
        // 50 credibility = 50% XP (0.5x)
        // etc.
        let percentage = Double(max(0, min(100, score))) / 100.0
        return percentage
    }

    func credibilityTierName(score: Int) -> String {
        switch score {
        case 95...100: return "Excellent"
        case 80...94:  return "Good"
        case 60...79:  return "Fair"
        case 40...59:  return "Poor"
        case 0...39:   return "Critical"
        default:       return "Unknown"
        }
    }

    func earningRatePercentage(score: Int) -> Int {
        // Return credibility score directly as percentage
        return max(0, min(100, score))
    }

    // MARK: - XP Redemption

    func redeemXP(
        amount: Int,
        userId: UUID,
        credibilityScore: Int
    ) -> Result<RedemptionResult, RedemptionError> {
        // Validate amount
        guard amount > 0 else {
            return .failure(.invalidAmount)
        }

        // Get or create balance
        var balance = repository.getBalance(userId: userId) ?? repository.createBalance(userId: userId)

        // Check if user has enough XP
        guard balance.currentXP >= amount else {
            return .failure(.insufficientXP)
        }

        // Redeem XP (1 XP = 1 minute, always)
        let minutesGranted = amount

        // Update balance
        let redeemed = balance.redeem(xp: amount)
        guard redeemed else {
            return .failure(.systemError("Failed to redeem XP"))
        }

        // Save updated balance
        repository.saveBalance(balance)

        // Create transaction record
        let transaction = XPTransaction(
            userId: userId,
            type: .redeemed,
            amount: amount,
            credibilityAtTime: credibilityScore,
            notes: "Redeemed \(amount) XP for \(minutesGranted) minutes"
        )
        repository.saveTransaction(transaction)

        // Return success result
        let result = RedemptionResult(
            success: true,
            minutesGranted: minutesGranted,
            xpSpent: amount,
            newBalance: balance.currentXP,
            message: "Successfully redeemed \(amount) XP for \(minutesGranted) minutes"
        )

        return .success(result)
    }

    // MARK: - Balance & Transactions

    func getBalance(userId: UUID) -> XPBalance? {
        return repository.getBalance(userId: userId)
    }

    func getRecentTransactions(userId: UUID, limit: Int = 10) -> [XPTransaction] {
        return repository.getTransactions(userId: userId, limit: limit)
    }

    func getDailyStats(userId: UUID) -> DailyXPStats {
        let earnedToday = repository.getTotalEarnedToday(userId: userId)
        let redeemedToday = repository.getTotalRedeemedToday(userId: userId)
        let balance = repository.getBalance(userId: userId)
        let credibilityScore = credibilityService.getCredibilityScore(childId: userId)
        let earningRate = credibilityMultiplier(score: credibilityScore)

        return DailyXPStats(
            earnedToday: earnedToday,
            redeemedToday: redeemedToday,
            currentBalance: balance?.currentXP ?? 0,
            credibilityScore: credibilityScore,
            earningRate: earningRate
        )
    }

    // MARK: - Earning XP (for task completion)

    /// Award XP for completing a task
    func awardXP(
        userId: UUID,
        timeMinutes: Int,
        taskId: UUID,
        credibilityScore: Int
    ) -> Int {
        // Calculate XP with credibility modifier
        let earnedXP = calculateXP(timeMinutes: timeMinutes, credibilityScore: credibilityScore)

        // Get or create balance
        var balance = repository.getBalance(userId: userId) ?? repository.createBalance(userId: userId)

        // Award XP with credibility multiplier
        let multiplier = credibilityMultiplier(score: credibilityScore)
        balance.earn(baseXP: timeMinutes, credibilityMultiplier: multiplier)

        // Save updated balance
        repository.saveBalance(balance)

        // Create transaction record
        let transaction = XPTransaction(
            userId: userId,
            type: .earned,
            amount: earnedXP,
            relatedTaskId: taskId,
            credibilityAtTime: credibilityScore,
            notes: "Earned \(earnedXP) XP for \(timeMinutes) minutes of work"
        )
        repository.saveTransaction(transaction)

        return earnedXP
    }

    // MARK: - Direct XP Grant (for emergency grants)

    /// Grant XP directly without credibility multiplier (for emergency grants)
    func grantXPDirect(userId: UUID, amount: Int, reason: String) -> Bool {
        guard amount > 0 else { return false }

        // Get or create balance
        var balance = repository.getBalance(userId: userId) ?? repository.createBalance(userId: userId)

        // Grant XP directly (no credibility multiplier)
        balance.currentXP += amount
        balance.lifetimeEarned += amount

        // Save updated balance
        repository.saveBalance(balance)

        // Create transaction record
        let transaction = XPTransaction(
            userId: userId,
            type: .earned,
            amount: amount,
            credibilityAtTime: nil, // No credibility for emergency grants
            notes: "Emergency grant: \(reason)"
        )
        repository.saveTransaction(transaction)

        return true
    }

    // MARK: - Test Utilities

    func resetBalance(userId: UUID) {
        if let repo = repository as? XPRepositoryImpl {
            repo.resetBalance(userId: userId)
        }
    }

    func deleteAllTransactions(userId: UUID) {
        if let repo = repository as? XPRepositoryImpl {
            repo.deleteAllTransactions(userId: userId)
        }
    }
}
