import Foundation

struct CredibilityCalculationConfig {
    // UPDATED PHASE 3: Simplified credibility system
    let singleDownvotePenalty: Int = -20     // Declined task: -20 credibility
    let stackedDownvotePenalty: Int = -20    // Keep same penalty (no stacking)
    let stackingWindowDays: Int = 7
    let approvedTaskBonus: Int = 5           // Approved task: +5 credibility
    let streakBonusAmount: Int = 5
    let streakBonusInterval: Int = 10
    let halfDecayDays: Int = 30
    let fullDecayDays: Int = 60
}

final class CredibilityCalculator {
    private let config = CredibilityCalculationConfig()

    func calculateDownvotePenalty(lastDownvoteDate: Date?) -> Int {
        guard let lastDownvote = lastDownvoteDate else {
            return config.singleDownvotePenalty
        }

        let daysSince = daysBetween(from: lastDownvote, to: Date())
        return daysSince <= config.stackingWindowDays
            ? config.stackedDownvotePenalty
            : config.singleDownvotePenalty
    }

    func shouldAwardStreakBonus(consecutiveTasks: Int) -> Bool {
        consecutiveTasks > 0 && consecutiveTasks % config.streakBonusInterval == 0
    }

    func calculateDecayRecovery(for events: [CredibilityHistoryEvent], currentDate: Date) -> Int {
        events
            .filter { $0.event == .downvote }
            .reduce(0) { recovery, event in
                let daysSince = daysBetween(from: event.timestamp, to: currentDate)

                if daysSince >= config.fullDecayDays {
                    return recovery + abs(event.amount)
                } else if daysSince >= config.halfDecayDays && event.decayed != true {
                    return recovery + abs(event.amount) / 2
                }
                return recovery
            }
    }

    func clampScore(_ score: Int, min: Int = 0, max: Int = 100) -> Int {
        Swift.max(min, Swift.min(max, score))
    }

    private func daysBetween(from: Date, to: Date) -> Int {
        Calendar.current.dateComponents([.day], from: from, to: to).day ?? 0
    }
}
