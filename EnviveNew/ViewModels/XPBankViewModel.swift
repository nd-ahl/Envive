import Foundation
import SwiftUI
import Combine

// MARK: - XP Bank View Model

final class XPBankViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var currentBalance: Int = 0
    @Published var credibilityScore: Int = 100
    @Published var credibilityTier: String = "Excellent"
    @Published var earningRatePercentage: Int = 100
    @Published var recentTransactions: [XPTransaction] = []
    @Published var dailyStats: DailyXPStats?
    @Published var redemptionAmount: Int = 60
    @Published var isRedeeming: Bool = false
    @Published var redemptionMessage: String?
    @Published var showRedemptionSuccess: Bool = false
    @Published var showRedemptionError: Bool = false

    // MARK: - Private Properties

    private let xpService: XPService
    private let credibilityService: CredibilityService
    private let userId: UUID
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer

    init(
        userId: UUID,
        xpService: XPService,
        credibilityService: CredibilityService
    ) {
        self.userId = userId
        self.xpService = xpService
        self.credibilityService = credibilityService

        loadData()
    }

    // MARK: - Public Methods

    func loadData() {
        // Load XP balance
        if let balance = xpService.getBalance(userId: userId) {
            currentBalance = balance.currentXP
        } else {
            currentBalance = 0
        }

        // Load credibility info
        credibilityScore = credibilityService.credibilityScore
        credibilityTier = xpService.credibilityTierName(score: credibilityScore)
        earningRatePercentage = xpService.earningRatePercentage(score: credibilityScore)

        // Load recent transactions
        recentTransactions = xpService.getRecentTransactions(userId: userId, limit: 10)

        // Load daily stats
        dailyStats = xpService.getDailyStats(userId: userId)
    }

    func redeemXP() {
        guard redemptionAmount > 0 else {
            redemptionMessage = "Please enter a valid amount"
            showRedemptionError = true
            return
        }

        guard redemptionAmount <= currentBalance else {
            redemptionMessage = "You don't have enough XP. Your balance is \(currentBalance) XP."
            showRedemptionError = true
            return
        }

        isRedeeming = true

        // Attempt redemption
        let result = xpService.redeemXP(
            amount: redemptionAmount,
            userId: userId,
            credibilityScore: credibilityScore
        )

        isRedeeming = false

        switch result {
        case .success(let redemptionResult):
            redemptionMessage = redemptionResult.message
            showRedemptionSuccess = true
            loadData()  // Refresh data after successful redemption

        case .failure(let error):
            redemptionMessage = error.localizedDescription
            showRedemptionError = true
        }
    }

    func dismissRedemptionMessage() {
        showRedemptionSuccess = false
        showRedemptionError = false
        redemptionMessage = nil
    }

    // MARK: - Computed Properties

    var balanceDisplay: String {
        return "\(currentBalance) XP"
    }

    var credibilityDisplay: String {
        return "\(credibilityScore) (\(credibilityTier))"
    }

    var earningRateDisplay: String {
        return "You're earning \(earningRatePercentage)% XP per task"
    }

    var redemptionMinutes: Int {
        return redemptionAmount  // 1 XP = 1 minute
    }

    var remainingAfterRedemption: Int {
        return max(currentBalance - redemptionAmount, 0)
    }

    var canRedeem: Bool {
        return redemptionAmount > 0 && redemptionAmount <= currentBalance
    }

    var softCapWarning: String? {
        guard let balance = xpService.getBalance(userId: userId) else { return nil }

        if balance.isAtSoftCap {
            return "You're at the XP soft cap. Earnings above 1000 XP are reduced by 50%."
        } else if balance.currentXP >= 800 {
            let percentage = Int(balance.softCapPercentage)
            return "You're \(percentage)% toward the 1000 XP soft cap."
        }
        return nil
    }
}
