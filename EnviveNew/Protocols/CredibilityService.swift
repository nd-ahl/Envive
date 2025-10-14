import Foundation
import Combine

protocol CredibilityService {
    var credibilityScore: Int { get }
    var credibilityHistory: [CredibilityHistoryEvent] { get }
    var consecutiveApprovedTasks: Int { get }
    var hasRedemptionBonus: Bool { get }
    var redemptionBonusExpiry: Date? { get }

    func processDownvote(taskId: UUID, reviewerId: UUID, notes: String?)
    func undoDownvote(taskId: UUID, reviewerId: UUID)
    func processApprovedTask(taskId: UUID, reviewerId: UUID, notes: String?)
    func calculateXPToMinutes(xpAmount: Int) -> Int
    func getConversionRate() -> Double
    func getCurrentTier() -> CredibilityTier
    func getCredibilityStatus() -> CredibilityStatus
    func applyTimeBasedDecay()
}
