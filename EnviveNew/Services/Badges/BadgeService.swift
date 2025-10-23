//
//  BadgeService.swift
//  EnviveNew
//
//  Service for managing badge awards and tracking
//

import Foundation

// MARK: - Badge Service Protocol

protocol BadgeService {
    /// Get all badges earned by a child
    func getEarnedBadges(for childId: UUID) -> [EarnedBadge]

    /// Award a badge to a child (returns nil if already earned)
    func awardBadge(_ badgeType: BadgeType, to childId: UUID) async throws -> EarnedBadge?

    /// Check if a child has earned a specific badge
    func hasBadge(_ badgeType: BadgeType, childId: UUID) -> Bool

    /// Get progress toward a specific badge
    func getBadgeProgress(_ badgeType: BadgeType, for childId: UUID) -> BadgeProgress?

    /// Check and award any newly earned badges based on current stats
    func checkAndAwardBadges(for childId: UUID) async throws -> [EarnedBadge]

    /// Get all available badges grouped by category
    func getAllBadgesByCategory() -> [BadgeCategory: [BadgeType]]

    /// Get count of earned badges by tier
    func getBadgeCountByTier(for childId: UUID) -> [BadgeTier: Int]
}

// MARK: - Badge Service Implementation

class BadgeServiceImpl: BadgeService {
    private let badgeRepository: BadgeRepository
    private let taskService: TaskService
    private let xpService: XPService
    private let credibilityService: CredibilityService

    init(
        badgeRepository: BadgeRepository,
        taskService: TaskService,
        xpService: XPService,
        credibilityService: CredibilityService
    ) {
        self.badgeRepository = badgeRepository
        self.taskService = taskService
        self.xpService = xpService
        self.credibilityService = credibilityService
    }

    func getEarnedBadges(for childId: UUID) -> [EarnedBadge] {
        return badgeRepository.getEarnedBadges(for: childId)
    }

    func awardBadge(_ badgeType: BadgeType, to childId: UUID) async throws -> EarnedBadge? {
        // Check if already earned
        if hasBadge(badgeType, childId: childId) {
            print("🏅 Badge \(badgeType.displayName) already earned by child \(childId)")
            return nil
        }

        // Create earned badge
        let earnedBadge = EarnedBadge(childId: childId, badgeType: badgeType)

        // Save to repository
        try badgeRepository.saveBadge(earnedBadge)

        // Award bonus XP
        _ = xpService.grantXPDirect(userId: childId, amount: badgeType.bonusXP, reason: "Badge: \(badgeType.displayName)")

        // Show notification on main thread
        await MainActor.run {
            BadgeNotificationManager.shared.showBadge(earnedBadge)
        }

        print("🏅 Awarded badge '\(badgeType.displayName)' to child \(childId) (+\(badgeType.bonusXP) XP)")

        return earnedBadge
    }

    func hasBadge(_ badgeType: BadgeType, childId: UUID) -> Bool {
        return badgeRepository.hasBadge(badgeType, for: childId)
    }

    func getBadgeProgress(_ badgeType: BadgeType, for childId: UUID) -> BadgeProgress? {
        // If already earned, return 100% progress
        if hasBadge(badgeType, childId: childId) {
            return BadgeProgress(badgeType: badgeType, current: 1, target: 1, isEarned: true)
        }

        // Calculate progress based on badge type
        let (current, target) = calculateProgress(badgeType, for: childId)

        return BadgeProgress(
            badgeType: badgeType,
            current: current,
            target: target,
            isEarned: false
        )
    }

    func checkAndAwardBadges(for childId: UUID) async throws -> [EarnedBadge] {
        var newlyEarnedBadges: [EarnedBadge] = []

        // Check each badge type
        for badgeType in BadgeType.allCases {
            // Skip if already earned
            if hasBadge(badgeType, childId: childId) {
                continue
            }

            // Check if criteria is met
            if shouldAwardBadge(badgeType, for: childId) {
                if let earnedBadge = try await awardBadge(badgeType, to: childId) {
                    newlyEarnedBadges.append(earnedBadge)
                }
            }
        }

        return newlyEarnedBadges
    }

    func getAllBadgesByCategory() -> [BadgeCategory: [BadgeType]] {
        var result: [BadgeCategory: [BadgeType]] = [:]

        for category in BadgeCategory.allCases {
            result[category] = BadgeType.allCases.filter { $0.category == category }
        }

        return result
    }

    func getBadgeCountByTier(for childId: UUID) -> [BadgeTier: Int] {
        let earnedBadges = getEarnedBadges(for: childId)
        var counts: [BadgeTier: Int] = [:]

        for earnedBadge in earnedBadges {
            let tier = earnedBadge.badgeType.tier
            counts[tier, default: 0] += 1
        }

        return counts
    }

    // MARK: - Private Helpers

    private func calculateProgress(_ badgeType: BadgeType, for childId: UUID) -> (current: Int, target: Int) {
        switch badgeType {
        // Task count badges
        case .firstTaskComplete:
            return (getCompletedTaskCount(childId), 1)
        case .tasksNovice:
            return (getCompletedTaskCount(childId), 5)
        case .tasksApprentice:
            return (getCompletedTaskCount(childId), 25)
        case .tasksExpert:
            return (getCompletedTaskCount(childId), 100)
        case .tasksMaster:
            return (getCompletedTaskCount(childId), 500)

        // XP badges
        case .xpBeginner:
            return (getTotalXP(childId), 100)
        case .xpIntermediate:
            return (getTotalXP(childId), 1000)
        case .xpAdvanced:
            return (getTotalXP(childId), 10000)
        case .xpMaster:
            return (getTotalXP(childId), 100000)

        // Streak badges
        case .streak3:
            return (getCurrentStreak(childId), 3)
        case .streak7:
            return (getCurrentStreak(childId), 7)
        case .streak30:
            return (getCurrentStreak(childId), 30)
        case .streak100:
            return (getCurrentStreak(childId), 100)

        default:
            return (0, 1)
        }
    }

    private func shouldAwardBadge(_ badgeType: BadgeType, for childId: UUID) -> Bool {
        switch badgeType {
        case .firstAppOpen:
            return true // Awarded on first app open

        case .firstTaskComplete:
            return getCompletedTaskCount(childId) >= 1

        case .tasksNovice:
            return getCompletedTaskCount(childId) >= 5

        case .tasksApprentice:
            return getCompletedTaskCount(childId) >= 25

        case .tasksExpert:
            return getCompletedTaskCount(childId) >= 100

        case .tasksMaster:
            return getCompletedTaskCount(childId) >= 500

        case .xpBeginner:
            return getTotalXP(childId) >= 100

        case .xpIntermediate:
            return getTotalXP(childId) >= 1000

        case .xpAdvanced:
            return getTotalXP(childId) >= 10000

        case .xpMaster:
            return getTotalXP(childId) >= 100000

        case .streak3:
            return getCurrentStreak(childId) >= 3

        case .streak7:
            return getCurrentStreak(childId) >= 7

        case .streak30:
            return getCurrentStreak(childId) >= 30

        case .streak100:
            return getCurrentStreak(childId) >= 100

        default:
            return false
        }
    }

    private func getCompletedTaskCount(_ childId: UUID) -> Int {
        return taskService.getChildTasks(childId: childId, status: .approved).count
    }

    private func getTotalXP(_ childId: UUID) -> Int {
        return xpService.getBalance(userId: childId)?.lifetimeEarned ?? 0
    }

    private func getCurrentStreak(_ childId: UUID) -> Int {
        // TODO: Implement streak tracking
        return 0
    }
}
