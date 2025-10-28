//
//  Badge.swift
//  EnviveNew
//
//  Achievement badge system for child profiles
//

import Foundation

// MARK: - Badge Type

enum BadgeType: String, Codable, CaseIterable {
    // Getting Started
    case firstAppOpen = "first_app_open"
    case profileComplete = "profile_complete"

    // Task Achievements
    case firstTaskComplete = "first_task_complete"
    case tasksNovice = "tasks_novice"           // 5 tasks
    case tasksApprentice = "tasks_apprentice"   // 25 tasks
    case tasksExpert = "tasks_expert"           // 100 tasks
    case tasksMaster = "tasks_master"           // 500 tasks
    case perfectWeek = "perfect_week"           // All tasks complete for 7 days

    // XP Achievements
    case xpBeginner = "xp_beginner"             // 100 XP
    case xpIntermediate = "xp_intermediate"     // 1,000 XP
    case xpAdvanced = "xp_advanced"             // 10,000 XP
    case xpMaster = "xp_master"                 // 100,000 XP

    // Credibility Achievements
    case trustworthy = "trustworthy"            // Maintain 90+ credibility for 7 days
    case reliable = "reliable"                  // Maintain 95+ credibility for 30 days
    case exemplary = "exemplary"                // Maintain 98+ credibility for 90 days

    // Streak Achievements
    case streak3 = "streak_3"                   // 3 day task streak
    case streak7 = "streak_7"                   // 7 day task streak
    case streak30 = "streak_30"                 // 30 day task streak
    case streak100 = "streak_100"               // 100 day task streak

    // Special Achievements
    case earlyBird = "early_bird"               // Complete task before 8am
    case nightOwl = "night_owl"                 // Complete task after 10pm
    case speedDemon = "speed_demon"             // Complete task within 5 mins of assignment
    case overachiever = "overachiever"          // Complete 10 tasks in one day

    var displayName: String {
        switch self {
        case .firstAppOpen: return "Welcome!"
        case .profileComplete: return "All Set Up"
        case .firstTaskComplete: return "First Steps"
        case .tasksNovice: return "Task Novice"
        case .tasksApprentice: return "Task Apprentice"
        case .tasksExpert: return "Task Expert"
        case .tasksMaster: return "Task Master"
        case .perfectWeek: return "Perfect Week"
        case .xpBeginner: return "XP Beginner"
        case .xpIntermediate: return "XP Intermediate"
        case .xpAdvanced: return "XP Advanced"
        case .xpMaster: return "XP Master"
        case .trustworthy: return "Trustworthy"
        case .reliable: return "Reliable"
        case .exemplary: return "Exemplary"
        case .streak3: return "3-Day Streak"
        case .streak7: return "Week Warrior"
        case .streak30: return "Month Master"
        case .streak100: return "Streak Legend"
        case .earlyBird: return "Early Bird"
        case .nightOwl: return "Night Owl"
        case .speedDemon: return "Speed Demon"
        case .overachiever: return "Overachiever"
        }
    }

    var description: String {
        switch self {
        case .firstAppOpen: return "Opened the app for the first time"
        case .profileComplete: return "Completed your profile setup"
        case .firstTaskComplete: return "Completed your first task"
        case .tasksNovice: return "Completed 5 tasks"
        case .tasksApprentice: return "Completed 25 tasks"
        case .tasksExpert: return "Completed 100 tasks"
        case .tasksMaster: return "Completed 500 tasks"
        case .perfectWeek: return "Completed all tasks for 7 days straight"
        case .xpBeginner: return "Earned 100 XP"
        case .xpIntermediate: return "Earned 1,000 XP"
        case .xpAdvanced: return "Earned 10,000 XP"
        case .xpMaster: return "Earned 100,000 XP"
        case .trustworthy: return "Maintained 90+ credibility for 7 days"
        case .reliable: return "Maintained 95+ credibility for 30 days"
        case .exemplary: return "Maintained 98+ credibility for 90 days"
        case .streak3: return "Completed tasks 3 days in a row"
        case .streak7: return "Completed tasks 7 days in a row"
        case .streak30: return "Completed tasks 30 days in a row"
        case .streak100: return "Completed tasks 100 days in a row"
        case .earlyBird: return "Completed a task before 8 AM"
        case .nightOwl: return "Completed a task after 10 PM"
        case .speedDemon: return "Completed a task within 5 minutes"
        case .overachiever: return "Completed 10 tasks in one day"
        }
    }

    var icon: String {
        switch self {
        case .firstAppOpen: return "star.fill"
        case .profileComplete: return "checkmark.circle.fill"
        case .firstTaskComplete: return "flag.fill"
        case .tasksNovice: return "1.circle.fill"
        case .tasksApprentice: return "2.circle.fill"
        case .tasksExpert: return "3.circle.fill"
        case .tasksMaster: return "crown.fill"
        case .perfectWeek: return "calendar.badge.checkmark"
        case .xpBeginner: return "star.circle.fill"
        case .xpIntermediate: return "star.circle.fill"
        case .xpAdvanced: return "star.circle.fill"
        case .xpMaster: return "sparkles"
        case .trustworthy: return "hand.thumbsup.fill"
        case .reliable: return "checkmark.seal.fill"
        case .exemplary: return "medal.fill"
        case .streak3: return "flame.fill"
        case .streak7: return "flame.fill"
        case .streak30: return "flame.fill"
        case .streak100: return "flame.fill"
        case .earlyBird: return "sunrise.fill"
        case .nightOwl: return "moon.stars.fill"
        case .speedDemon: return "bolt.fill"
        case .overachiever: return "star.leadinghalf.filled"
        }
    }

    var bonusXP: Int {
        // DISABLED: No XP/time rewards for achievements
        // Badges are now purely cosmetic achievements
        // This prevents children from earning screen time through badge collection
        return 0

        /* PREVIOUS XP REWARDS (disabled per user request):
        // XP rewards scaled by badge tier:
        // Bronze: 25-100 XP (common, starter achievements)
        // Silver: 150-400 XP (moderate achievements)
        // Gold: 500-1500 XP (difficult achievements)
        // Platinum: 2000-10000 XP (rare, exceptional achievements)

        switch self {
        // BRONZE TIER (25-100 XP) - Common, Getting Started
        case .firstAppOpen: return 25
        case .profileComplete: return 50
        case .firstTaskComplete: return 75
        case .tasksNovice: return 100          // 5 tasks
        case .xpBeginner: return 75            // 100 XP earned
        case .streak3: return 100              // 3 day streak
        case .earlyBird: return 50
        case .nightOwl: return 50

        // SILVER TIER (150-400 XP) - Moderate Achievements
        case .tasksApprentice: return 250      // 25 tasks
        case .xpIntermediate: return 300       // 1,000 XP earned
        case .trustworthy: return 350          // 90+ credibility for 7 days
        case .streak7: return 400              // 7 day streak
        case .speedDemon: return 200

        // GOLD TIER (500-1500 XP) - Difficult Achievements
        case .tasksExpert: return 800          // 100 tasks
        case .xpAdvanced: return 1000          // 10,000 XP earned
        case .reliable: return 1200            // 95+ credibility for 30 days
        case .streak30: return 1500            // 30 day streak
        case .overachiever: return 600         // 10 tasks in one day

        // PLATINUM TIER (2000-10000 XP) - Rare, Exceptional Achievements
        case .tasksMaster: return 5000         // 500 tasks
        case .xpMaster: return 10000           // 100,000 XP earned
        case .exemplary: return 3000           // 98+ credibility for 90 days
        case .perfectWeek: return 2000         // Perfect week
        case .streak100: return 8000           // 100 day streak
        }
        */
    }

    var category: BadgeCategory {
        switch self {
        case .firstAppOpen, .profileComplete:
            return .gettingStarted
        case .firstTaskComplete, .tasksNovice, .tasksApprentice, .tasksExpert, .tasksMaster, .perfectWeek:
            return .tasks
        case .xpBeginner, .xpIntermediate, .xpAdvanced, .xpMaster:
            return .xp
        case .trustworthy, .reliable, .exemplary:
            return .credibility
        case .streak3, .streak7, .streak30, .streak100:
            return .streaks
        case .earlyBird, .nightOwl, .speedDemon, .overachiever:
            return .special
        }
    }

    var tier: BadgeTier {
        switch self {
        case .firstAppOpen, .profileComplete, .firstTaskComplete:
            return .bronze
        case .tasksNovice, .xpBeginner, .streak3, .earlyBird, .nightOwl:
            return .bronze
        case .tasksApprentice, .xpIntermediate, .trustworthy, .streak7, .speedDemon:
            return .silver
        case .tasksExpert, .xpAdvanced, .reliable, .streak30, .overachiever:
            return .gold
        case .tasksMaster, .xpMaster, .exemplary, .perfectWeek, .streak100:
            return .platinum
        }
    }
}

// MARK: - Badge Category

enum BadgeCategory: String, Codable, CaseIterable {
    case gettingStarted = "getting_started"
    case tasks = "tasks"
    case xp = "xp"
    case credibility = "credibility"
    case streaks = "streaks"
    case special = "special"

    var displayName: String {
        switch self {
        case .gettingStarted: return "Getting Started"
        case .tasks: return "Tasks"
        case .xp: return "Experience"
        case .credibility: return "Credibility"
        case .streaks: return "Streaks"
        case .special: return "Special"
        }
    }
}

// MARK: - Badge Tier

enum BadgeTier: String, Codable, Comparable {
    case bronze = "bronze"
    case silver = "silver"
    case gold = "gold"
    case platinum = "platinum"

    var displayName: String {
        rawValue.capitalized
    }

    var color: String {
        switch self {
        case .bronze: return "brown"
        case .silver: return "gray"
        case .gold: return "yellow"
        case .platinum: return "cyan"
        }
    }

    static func < (lhs: BadgeTier, rhs: BadgeTier) -> Bool {
        let order: [BadgeTier] = [.bronze, .silver, .gold, .platinum]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
}

// MARK: - Earned Badge

struct EarnedBadge: Codable, Identifiable {
    let id: UUID
    let childId: UUID
    let badgeType: BadgeType
    let earnedAt: Date
    let bonusXPAwarded: Int

    init(id: UUID = UUID(), childId: UUID, badgeType: BadgeType, earnedAt: Date = Date(), bonusXPAwarded: Int? = nil) {
        self.id = id
        self.childId = childId
        self.badgeType = badgeType
        self.earnedAt = earnedAt
        self.bonusXPAwarded = bonusXPAwarded ?? badgeType.bonusXP
    }
}

// MARK: - Badge Progress

struct BadgeProgress {
    let badgeType: BadgeType
    let current: Int
    let target: Int
    let isEarned: Bool

    var percentage: Double {
        guard target > 0 else { return 0 }
        return min(Double(current) / Double(target), 1.0)
    }
}
