import Foundation
import UserNotifications
import Combine

// MARK: - Credibility Notification Types

enum CredibilityNotificationType: String {
    case taskRejected = "task_rejected"
    case taskApproved = "task_approved"
    case streakBonus = "streak_bonus"
    case lowCredibility = "low_credibility"
    case redemptionBonusUnlocked = "redemption_bonus_unlocked"
    case redemptionBonusExpiring = "redemption_bonus_expiring"
    case appealSubmitted = "appeal_submitted"
    case appealReviewed = "appeal_reviewed"
    case credibilityRecovered = "credibility_recovered"

    var category: String {
        return "CREDIBILITY_\(self.rawValue.uppercased())"
    }

    var sound: UNNotificationSound {
        switch self {
        case .taskRejected, .lowCredibility:
            return UNNotificationSound.defaultCritical
        default:
            return UNNotificationSound.default
        }
    }
}

// MARK: - Credibility Notifications Manager

class CredibilityNotificationsManager: ObservableObject {
    static let shared = CredibilityNotificationsManager()

    private let notificationCenter = UNUserNotificationCenter.current()
    private let credibilityManager = CredibilityManager()

    private init() {
        setupNotificationCategories()
    }

    // MARK: - Setup

    func setupNotificationCategories() {
        var categories: [UNNotificationCategory] = []

        // Task Rejected Category (with Appeal action)
        let appealAction = UNNotificationAction(
            identifier: "APPEAL_ACTION",
            title: "Appeal",
            options: [.foreground]
        )
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_ACTION",
            title: "Dismiss",
            options: []
        )

        let rejectedCategory = UNNotificationCategory(
            identifier: CredibilityNotificationType.taskRejected.category,
            actions: [appealAction, dismissAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        categories.append(rejectedCategory)

        // Task Approved Category
        let viewHistoryAction = UNNotificationAction(
            identifier: "VIEW_HISTORY_ACTION",
            title: "View History",
            options: [.foreground]
        )

        let approvedCategory = UNNotificationCategory(
            identifier: CredibilityNotificationType.taskApproved.category,
            actions: [viewHistoryAction],
            intentIdentifiers: [],
            options: []
        )
        categories.append(approvedCategory)

        // Streak Bonus Category
        let celebrateAction = UNNotificationAction(
            identifier: "CELEBRATE_ACTION",
            title: "View Profile",
            options: [.foreground]
        )

        let streakCategory = UNNotificationCategory(
            identifier: CredibilityNotificationType.streakBonus.category,
            actions: [celebrateAction],
            intentIdentifiers: [],
            options: []
        )
        categories.append(streakCategory)

        // Low Credibility Category
        let learnMoreAction = UNNotificationAction(
            identifier: "LEARN_MORE_ACTION",
            title: "Learn More",
            options: [.foreground]
        )

        let lowCredCategory = UNNotificationCategory(
            identifier: CredibilityNotificationType.lowCredibility.category,
            actions: [learnMoreAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        categories.append(lowCredCategory)

        // Redemption Bonus Category
        let redeemAction = UNNotificationAction(
            identifier: "REDEEM_ACTION",
            title: "Redeem XP",
            options: [.foreground]
        )

        let bonusCategory = UNNotificationCategory(
            identifier: CredibilityNotificationType.redemptionBonusUnlocked.category,
            actions: [redeemAction],
            intentIdentifiers: [],
            options: []
        )
        categories.append(bonusCategory)

        notificationCenter.setNotificationCategories(Set(categories))
    }

    // MARK: - Task Rejection Notifications

    func notifyTaskRejected(
        taskTitle: String,
        taskId: String,
        parentNotes: String,
        pointsLost: Int,
        previousScore: Int,
        newScore: Int,
        canAppeal: Bool
    ) {
        let content = UNMutableNotificationContent()
        content.title = "❌ Task Rejected"
        content.subtitle = taskTitle
        content.body = "Your parent rejected this task. You lost \(abs(pointsLost)) credibility points. Score: \(previousScore) → \(newScore)"
        content.sound = CredibilityNotificationType.taskRejected.sound
        content.categoryIdentifier = CredibilityNotificationType.taskRejected.category
        content.badge = 1

        content.userInfo = [
            "type": CredibilityNotificationType.taskRejected.rawValue,
            "taskId": taskId,
            "taskTitle": taskTitle,
            "parentNotes": parentNotes,
            "pointsLost": pointsLost,
            "previousScore": previousScore,
            "newScore": newScore,
            "canAppeal": canAppeal
        ]

        // Show immediately
        let request = UNNotificationRequest(
            identifier: "task_rejected_\(taskId)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule task rejection notification: \(error)")
            } else {
                print("✅ Task rejection notification scheduled")
            }
        }
    }

    // MARK: - Task Approval Notifications

    func notifyTaskApproved(
        taskTitle: String,
        taskId: String,
        pointsGained: Int,
        previousScore: Int,
        newScore: Int,
        currentStreak: Int
    ) {
        let content = UNMutableNotificationContent()
        content.title = "✅ Task Approved!"
        content.subtitle = taskTitle
        content.body = "Great work! You gained +\(pointsGained) credibility points. Score: \(newScore)"
        content.sound = CredibilityNotificationType.taskApproved.sound
        content.categoryIdentifier = CredibilityNotificationType.taskApproved.category

        content.userInfo = [
            "type": CredibilityNotificationType.taskApproved.rawValue,
            "taskId": taskId,
            "taskTitle": taskTitle,
            "pointsGained": pointsGained,
            "previousScore": previousScore,
            "newScore": newScore,
            "currentStreak": currentStreak
        ]

        let request = UNNotificationRequest(
            identifier: "task_approved_\(taskId)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule task approval notification: \(error)")
            } else {
                print("✅ Task approval notification scheduled")
            }
        }
    }

    // MARK: - Streak Bonus Notifications

    func notifyStreakBonus(streakCount: Int, bonusPoints: Int, newScore: Int) {
        let content = UNMutableNotificationContent()
        content.title = "🔥 Streak Bonus!"
        content.subtitle = "\(streakCount) Tasks in a Row!"
        content.body = "Amazing! You earned +\(bonusPoints) bonus points for your \(streakCount)-task streak! Keep it up!"
        content.sound = CredibilityNotificationType.streakBonus.sound
        content.categoryIdentifier = CredibilityNotificationType.streakBonus.category

        content.userInfo = [
            "type": CredibilityNotificationType.streakBonus.rawValue,
            "streakCount": streakCount,
            "bonusPoints": bonusPoints,
            "newScore": newScore
        ]

        let request = UNNotificationRequest(
            identifier: "streak_bonus_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule streak bonus notification: \(error)")
            } else {
                print("✅ Streak bonus notification scheduled")
            }
        }
    }

    // MARK: - Low Credibility Alerts

    func notifyLowCredibility(currentScore: Int, tier: String, conversionRate: Double) {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ Low Credibility Warning"
        content.subtitle = "Score: \(currentScore) - \(tier)"
        content.body = "Your credibility is low. Your XP conversion rate is only \(String(format: "%.1fx", conversionRate)). Complete tasks honestly to improve!"
        content.sound = CredibilityNotificationType.lowCredibility.sound
        content.categoryIdentifier = CredibilityNotificationType.lowCredibility.category
        content.badge = 1

        content.userInfo = [
            "type": CredibilityNotificationType.lowCredibility.rawValue,
            "currentScore": currentScore,
            "tier": tier,
            "conversionRate": conversionRate
        ]

        let request = UNNotificationRequest(
            identifier: "low_credibility_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule low credibility notification: \(error)")
            } else {
                print("✅ Low credibility notification scheduled")
            }
        }
    }

    // MARK: - Redemption Bonus Notifications

    func notifyRedemptionBonusUnlocked(currentScore: Int, bonusMultiplier: Double, expiryDays: Int) {
        let content = UNMutableNotificationContent()
        content.title = "⭐️ Redemption Bonus Unlocked!"
        content.subtitle = "Incredible Achievement!"
        content.body = "You've reached \(currentScore) credibility! You now have a \(String(format: "%.1fx", bonusMultiplier)) bonus for \(expiryDays) days!"
        content.sound = CredibilityNotificationType.redemptionBonusUnlocked.sound
        content.categoryIdentifier = CredibilityNotificationType.redemptionBonusUnlocked.category

        content.userInfo = [
            "type": CredibilityNotificationType.redemptionBonusUnlocked.rawValue,
            "currentScore": currentScore,
            "bonusMultiplier": bonusMultiplier,
            "expiryDays": expiryDays
        ]

        let request = UNNotificationRequest(
            identifier: "redemption_bonus_unlocked_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule redemption bonus notification: \(error)")
            } else {
                print("✅ Redemption bonus notification scheduled")
            }
        }
    }

    func notifyRedemptionBonusExpiring(hoursRemaining: Int) {
        let content = UNMutableNotificationContent()
        content.title = "⏰ Bonus Expiring Soon"
        content.subtitle = "\(hoursRemaining) hours left"
        content.body = "Your redemption bonus will expire in \(hoursRemaining) hours. Redeem your XP now to take advantage!"
        content.sound = CredibilityNotificationType.redemptionBonusExpiring.sound
        content.categoryIdentifier = CredibilityNotificationType.redemptionBonusExpiring.category

        content.userInfo = [
            "type": CredibilityNotificationType.redemptionBonusExpiring.rawValue,
            "hoursRemaining": hoursRemaining
        ]

        // Schedule for when specified hours remain
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: "redemption_bonus_expiring_\(hoursRemaining)",
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule bonus expiring notification: \(error)")
            } else {
                print("✅ Bonus expiring notification scheduled")
            }
        }
    }

    // MARK: - Appeal Notifications

    func notifyAppealSubmitted(taskTitle: String, childName: String) {
        // For parent
        let content = UNMutableNotificationContent()
        content.title = "📋 Appeal Submitted"
        content.subtitle = "From \(childName)"
        content.body = "\(childName) has appealed your rejection of '\(taskTitle)'. Please review their explanation."
        content.sound = CredibilityNotificationType.appealSubmitted.sound
        content.categoryIdentifier = CredibilityNotificationType.appealSubmitted.category
        content.badge = 1

        content.userInfo = [
            "type": CredibilityNotificationType.appealSubmitted.rawValue,
            "taskTitle": taskTitle,
            "childName": childName
        ]

        let request = UNNotificationRequest(
            identifier: "appeal_submitted_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule appeal submitted notification: \(error)")
            } else {
                print("✅ Appeal submitted notification scheduled")
            }
        }
    }

    func notifyAppealReviewed(taskTitle: String, approved: Bool, parentNotes: String?) {
        // For child
        let content = UNMutableNotificationContent()
        content.title = approved ? "✅ Appeal Approved" : "❌ Appeal Denied"
        content.subtitle = taskTitle
        content.body = approved
            ? "Good news! Your parent has approved your appeal. Your credibility has been restored."
            : "Your parent has reviewed your appeal and maintained their decision."
        content.sound = CredibilityNotificationType.appealReviewed.sound
        content.categoryIdentifier = CredibilityNotificationType.appealReviewed.category

        content.userInfo = [
            "type": CredibilityNotificationType.appealReviewed.rawValue,
            "taskTitle": taskTitle,
            "approved": approved,
            "parentNotes": parentNotes ?? ""
        ]

        let request = UNNotificationRequest(
            identifier: "appeal_reviewed_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule appeal reviewed notification: \(error)")
            } else {
                print("✅ Appeal reviewed notification scheduled")
            }
        }
    }

    // MARK: - Recovery Notifications

    func notifyCredibilityRecovered(oldTier: String, newTier: String, newScore: Int) {
        let content = UNMutableNotificationContent()
        content.title = "🎉 Tier Upgrade!"
        content.subtitle = "\(oldTier) → \(newTier)"
        content.body = "Excellent progress! Your credibility has improved to \(newScore). You're now in the \(newTier) tier!"
        content.sound = CredibilityNotificationType.credibilityRecovered.sound
        content.categoryIdentifier = CredibilityNotificationType.credibilityRecovered.category

        content.userInfo = [
            "type": CredibilityNotificationType.credibilityRecovered.rawValue,
            "oldTier": oldTier,
            "newTier": newTier,
            "newScore": newScore
        ]

        let request = UNNotificationRequest(
            identifier: "credibility_recovered_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule recovery notification: \(error)")
            } else {
                print("✅ Recovery notification scheduled")
            }
        }
    }

    // MARK: - Scheduled Reminders

    func scheduleRedemptionBonusExpiryReminder(expiryDate: Date) {
        // Schedule notifications for 24h, 6h, and 1h before expiry
        let timeIntervals: [(hours: Int, identifier: String)] = [
            (24, "24h"),
            (6, "6h"),
            (1, "1h")
        ]

        for (hours, identifier) in timeIntervals {
            let reminderDate = Calendar.current.date(
                byAdding: .hour,
                value: -hours,
                to: expiryDate
            )

            guard let reminderDate = reminderDate, reminderDate > Date() else {
                continue
            }

            let content = UNMutableNotificationContent()
            content.title = "⏰ Bonus Expiring Soon"
            content.body = "Your redemption bonus expires in \(hours) hour\(hours > 1 ? "s" : "")! Redeem your XP now for maximum value."
            content.sound = .default

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: reminderDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

            let request = UNNotificationRequest(
                identifier: "bonus_expiry_\(identifier)",
                content: content,
                trigger: trigger
            )

            notificationCenter.add(request) { error in
                if let error = error {
                    print("❌ Failed to schedule \(hours)h reminder: \(error)")
                } else {
                    print("✅ Scheduled \(hours)h expiry reminder")
                }
            }
        }
    }

    func cancelRedemptionBonusReminders() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [
            "bonus_expiry_24h",
            "bonus_expiry_6h",
            "bonus_expiry_1h"
        ])
    }

    // MARK: - Notification Permission

    func requestPermissionIfNeeded() {
        notificationCenter.getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                self.notificationCenter.requestAuthorization(
                    options: [.alert, .badge, .sound, .criticalAlert]
                ) { granted, error in
                    if granted {
                        print("✅ Notification permission granted")
                    } else if let error = error {
                        print("❌ Notification permission error: \(error)")
                    }
                }
            }
        }
    }

    // MARK: - Clear Badge

    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
}

// MARK: - Credibility Manager Extension

extension CredibilityManager {
    func processDownvoteWithNotification(
        taskId: UUID,
        taskTitle: String,
        reviewerId: UUID,
        notes: String? = nil
    ) {
        let previousScore = credibilityScore
        let previousTier = getCurrentTier()

        processDownvote(taskId: taskId, reviewerId: reviewerId, notes: notes)

        let newScore = credibilityScore
        let pointsLost = newScore - previousScore

        // Send notification
        CredibilityNotificationsManager.shared.notifyTaskRejected(
            taskTitle: taskTitle,
            taskId: taskId.uuidString,
            parentNotes: notes ?? "",
            pointsLost: pointsLost,
            previousScore: previousScore,
            newScore: newScore,
            canAppeal: true
        )

        // Check for low credibility
        if newScore < 60 && previousScore >= 60 {
            let tier = getCurrentTier()
            CredibilityNotificationsManager.shared.notifyLowCredibility(
                currentScore: newScore,
                tier: tier.name,
                conversionRate: getConversionRate()
            )
        }
    }

    func processApprovedTaskWithNotification(
        taskId: UUID,
        taskTitle: String,
        reviewerId: UUID,
        notes: String? = nil
    ) {
        let previousScore = credibilityScore
        let previousStreak = consecutiveApprovedTasks
        let previousTier = getCurrentTier()

        processApprovedTask(taskId: taskId, reviewerId: reviewerId, notes: notes)

        let newScore = credibilityScore
        let newStreak = consecutiveApprovedTasks
        let newTier = getCurrentTier()
        let pointsGained = newScore - previousScore

        // Send approval notification
        CredibilityNotificationsManager.shared.notifyTaskApproved(
            taskTitle: taskTitle,
            taskId: taskId.uuidString,
            pointsGained: pointsGained,
            previousScore: previousScore,
            newScore: newScore,
            currentStreak: newStreak
        )

        // Check for streak bonus
        if newStreak % 10 == 0 && newStreak > previousStreak {
            CredibilityNotificationsManager.shared.notifyStreakBonus(
                streakCount: newStreak,
                bonusPoints: 5,
                newScore: newScore
            )
        }

        // Check for tier improvement
        if newTier.range.lowerBound > previousTier.range.lowerBound {
            CredibilityNotificationsManager.shared.notifyCredibilityRecovered(
                oldTier: previousTier.name,
                newTier: newTier.name,
                newScore: newScore
            )
        }

        // Check for redemption bonus unlock
        if !hasRedemptionBonus && newScore >= 95 && previousScore < 60 {
            CredibilityNotificationsManager.shared.notifyRedemptionBonusUnlocked(
                currentScore: newScore,
                bonusMultiplier: 1.3,
                expiryDays: 7
            )

            // Schedule expiry reminders
            if let expiryDate = redemptionBonusExpiry {
                CredibilityNotificationsManager.shared.scheduleRedemptionBonusExpiryReminder(
                    expiryDate: expiryDate
                )
            }
        }
    }
}