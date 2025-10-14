import Foundation

// MARK: - XP Balance Model

/// Represents a user's XP balance and earning/spending history
struct XPBalance: Codable, Equatable {
    let userId: UUID
    var currentXP: Int
    var lifetimeEarned: Int
    var lifetimeSpent: Int
    let createdAt: Date
    var lastUpdated: Date

    // MARK: - Constants

    static let softCap: Int = 1000
    static let starterXP: Int = 0

    // MARK: - Initializer

    init(
        userId: UUID,
        currentXP: Int = XPBalance.starterXP,
        lifetimeEarned: Int = 0,
        lifetimeSpent: Int = 0,
        createdAt: Date = Date(),
        lastUpdated: Date = Date()
    ) {
        self.userId = userId
        self.currentXP = currentXP
        self.lifetimeEarned = lifetimeEarned
        self.lifetimeSpent = lifetimeSpent
        self.createdAt = createdAt
        self.lastUpdated = lastUpdated
    }

    // MARK: - Public Methods

    /// Earn XP with diminishing returns above soft cap
    mutating func earn(baseXP: Int, credibilityMultiplier: Double) {
        guard baseXP > 0 else { return }

        // Calculate XP with credibility modifier (round up, generous)
        let rawXP = Double(baseXP) * credibilityMultiplier
        let earnedXP = Int(ceil(rawXP))

        // Ensure minimum of 1 XP per task
        let finalXP = max(earnedXP, 1)

        // Apply diminishing returns above soft cap
        if currentXP >= XPBalance.softCap {
            // Only earn 50% above cap
            let overflow = finalXP / 2
            currentXP += overflow
            lifetimeEarned += overflow
        } else if currentXP + finalXP > XPBalance.softCap {
            // Split between below cap (full) and above cap (50%)
            let belowCap = XPBalance.softCap - currentXP
            let aboveCap = (finalXP - belowCap) / 2
            let totalEarned = belowCap + aboveCap
            currentXP += totalEarned
            lifetimeEarned += totalEarned
        } else {
            // Below soft cap, earn full amount
            currentXP += finalXP
            lifetimeEarned += finalXP
        }

        lastUpdated = Date()
    }

    /// Redeem XP for screen time
    mutating func redeem(xp: Int) -> Bool {
        guard xp > 0, currentXP >= xp else { return false }

        currentXP -= xp
        lifetimeSpent += xp
        lastUpdated = Date()
        return true
    }

    /// Check if balance is at or above soft cap
    var isAtSoftCap: Bool {
        return currentXP >= XPBalance.softCap
    }

    /// Calculate percentage toward soft cap
    var softCapPercentage: Double {
        guard XPBalance.softCap > 0 else { return 0 }
        return min(Double(currentXP) / Double(XPBalance.softCap) * 100, 100)
    }
}

// MARK: - XP Transaction Model

/// Represents a single XP transaction (earning or spending)
struct XPTransaction: Codable, Equatable, Identifiable {
    let id: UUID
    let userId: UUID
    let type: TransactionType
    let amount: Int
    let timestamp: Date
    let relatedTaskId: UUID?
    let credibilityAtTime: Int?
    let notes: String?

    enum TransactionType: String, Codable {
        case earned
        case redeemed
        case granted  // Emergency or bonus grants
    }

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        userId: UUID,
        type: TransactionType,
        amount: Int,
        timestamp: Date = Date(),
        relatedTaskId: UUID? = nil,
        credibilityAtTime: Int? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.type = type
        self.amount = amount
        self.timestamp = timestamp
        self.relatedTaskId = relatedTaskId
        self.credibilityAtTime = credibilityAtTime
        self.notes = notes
    }
}

// MARK: - Redemption Result

/// Result of a redemption attempt
struct RedemptionResult: Equatable {
    let success: Bool
    let minutesGranted: Int
    let xpSpent: Int
    let newBalance: Int
    let message: String
}

// MARK: - Redemption Error

/// Errors that can occur during redemption
enum RedemptionError: Error, Equatable {
    case insufficientXP
    case invalidAmount
    case userNotFound
    case systemError(String)

    var localizedDescription: String {
        switch self {
        case .insufficientXP:
            return "You don't have enough XP for this redemption."
        case .invalidAmount:
            return "Invalid redemption amount. Must be greater than 0."
        case .userNotFound:
            return "User not found."
        case .systemError(let message):
            return "System error: \(message)"
        }
    }
}
