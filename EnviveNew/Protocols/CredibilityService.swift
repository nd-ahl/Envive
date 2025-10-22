import Foundation
import Combine

protocol CredibilityService {
    // Per-child data access methods
    func getCredibilityScore(childId: UUID) -> Int
    func getCredibilityHistory(childId: UUID) -> [CredibilityHistoryEvent]
    func getConsecutiveApprovedTasks(childId: UUID) -> Int
    func getHasRedemptionBonus(childId: UUID) -> Bool
    func getRedemptionBonusExpiry(childId: UUID) -> Date?
    func getLastTaskUploadDate(childId: UUID) -> Date?
    func getDailyStreak(childId: UUID) -> Int

    // Actions with childId
    func processDownvote(taskId: UUID, childId: UUID, reviewerId: UUID, notes: String?)
    func undoDownvote(taskId: UUID, childId: UUID, reviewerId: UUID)
    func processApprovedTask(taskId: UUID, childId: UUID, reviewerId: UUID, notes: String?)
    func processTaskUpload(taskId: UUID, childId: UUID)

    // Per-child calculations
    func calculateXPToMinutes(xpAmount: Int, childId: UUID) -> Int
    func getConversionRate(childId: UUID) -> Double
    func getCurrentTier(childId: UUID) -> CredibilityTier
    func getCredibilityStatus(childId: UUID) -> CredibilityStatus
    func applyTimeBasedDecay(childId: UUID)

    // Test utilities
    func resetCredibility(childId: UUID)
}
