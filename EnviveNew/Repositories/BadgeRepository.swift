//
//  BadgeRepository.swift
//  EnviveNew
//
//  Repository for badge data persistence
//

import Foundation

// MARK: - Badge Repository Protocol

protocol BadgeRepository {
    /// Get all earned badges for a child
    func getEarnedBadges(for childId: UUID) -> [EarnedBadge]

    /// Save a newly earned badge
    func saveBadge(_ badge: EarnedBadge) throws

    /// Check if a child has a specific badge
    func hasBadge(_ badgeType: BadgeType, for childId: UUID) -> Bool

    /// Delete all badges for a child (for testing/reset)
    func deleteAllBadges(for childId: UUID) throws
}

// MARK: - Badge Repository Implementation

class BadgeRepositoryImpl: BadgeRepository {
    private let userDefaults: UserDefaults
    private let key = "earned_badges"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func getEarnedBadges(for childId: UUID) -> [EarnedBadge] {
        guard let data = userDefaults.data(forKey: key) else {
            return []
        }

        do {
            let allBadges = try JSONDecoder().decode([EarnedBadge].self, from: data)
            return allBadges.filter { $0.childId == childId }
                .sorted { $0.earnedAt > $1.earnedAt } // Most recent first
        } catch {
            print("❌ Error decoding badges: \(error)")
            return []
        }
    }

    func saveBadge(_ badge: EarnedBadge) throws {
        var allBadges = getAllBadges()

        // Check for duplicates
        if allBadges.contains(where: { $0.childId == badge.childId && $0.badgeType == badge.badgeType }) {
            print("⚠️ Badge already exists: \(badge.badgeType.displayName) for child \(badge.childId)")
            return
        }

        allBadges.append(badge)

        let data = try JSONEncoder().encode(allBadges)
        userDefaults.set(data, forKey: key)

        print("💾 Saved badge: \(badge.badgeType.displayName) for child \(badge.childId)")
    }

    func hasBadge(_ badgeType: BadgeType, for childId: UUID) -> Bool {
        let badges = getEarnedBadges(for: childId)
        return badges.contains { $0.badgeType == badgeType }
    }

    func deleteAllBadges(for childId: UUID) throws {
        var allBadges = getAllBadges()
        allBadges.removeAll { $0.childId == childId }

        let data = try JSONEncoder().encode(allBadges)
        userDefaults.set(data, forKey: key)

        print("🗑️ Deleted all badges for child \(childId)")
    }

    // MARK: - Private Helpers

    private func getAllBadges() -> [EarnedBadge] {
        guard let data = userDefaults.data(forKey: key) else {
            return []
        }

        do {
            return try JSONDecoder().decode([EarnedBadge].self, from: data)
        } catch {
            print("❌ Error decoding all badges: \(error)")
            return []
        }
    }
}
