import Foundation

// MARK: - Task Level Enum

/// Represents the difficulty/value level of a task
/// Level determines the XP reward (no multipliers)
enum TaskLevel: Int, Codable, CaseIterable, Identifiable {
    case level1 = 1  // Quick tasks → 5 XP
    case level2 = 2  // Easy tasks → 15 XP
    case level3 = 3  // Medium tasks → 30 XP
    case level4 = 4  // Hard tasks → 45 XP
    case level5 = 5  // Very hard → 60 XP

    var id: Int { rawValue }

    /// Base XP reward for this level
    var baseXP: Int {
        switch self {
        case .level1: return 5
        case .level2: return 15
        case .level3: return 30
        case .level4: return 45
        case .level5: return 60
        }
    }

    /// Display name for UI
    var displayName: String {
        switch self {
        case .level1: return "Level 1 - Quick"
        case .level2: return "Level 2 - Easy"
        case .level3: return "Level 3 - Medium"
        case .level4: return "Level 4 - Hard"
        case .level5: return "Level 5 - Very Hard"
        }
    }

    /// Short display name
    var shortName: String {
        return "Level \(rawValue)"
    }

    /// Description of what this level means
    var description: String {
        switch self {
        case .level1: return "Quick task (5 min reward)"
        case .level2: return "Easy task (15 min reward)"
        case .level3: return "Medium task (30 min reward)"
        case .level4: return "Hard task (45 min reward)"
        case .level5: return "Very hard task (60 min reward)"
        }
    }

    /// Calculate actual XP earned based on credibility
    /// Credibility is a percentage (0-100)
    func calculateEarnedXP(credibilityScore: Int) -> Int {
        let percentage = Double(credibilityScore) / 100.0
        let earned = Double(baseXP) * percentage
        return max(1, Int(earned))  // Minimum 1 XP
    }
}
