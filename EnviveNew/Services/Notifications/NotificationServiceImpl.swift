import Foundation
import UserNotifications
import Combine

final class NotificationServiceImpl: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published private(set) var hasPermission = false
    @Published private(set) var pendingNotifications: [UNNotificationRequest] = []

    private let notificationCenter = UNUserNotificationCenter.current()

    override init() {
        super.init()
        notificationCenter.delegate = self
        checkPermission()
    }

    // MARK: - Permission Management

    func requestPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run {
                self.hasPermission = granted
            }
            if granted {
                print("Notification permission granted")
                setupNotificationCategories()
            }
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }

    func checkPermission() {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.hasPermission = settings.authorizationStatus == .authorized
            }
        }
    }

    private func setupNotificationCategories() {
        let kudosAction = UNNotificationAction(
            identifier: "KUDOS_ACTION",
            title: "Give Kudos 👏",
            options: [.foreground]
        )

        let viewAction = UNNotificationAction(
            identifier: "VIEW_ACTION",
            title: "View Activity",
            options: [.foreground]
        )

        let taskCompletedCategory = UNNotificationCategory(
            identifier: "TASK_COMPLETED",
            actions: [kudosAction, viewAction],
            intentIdentifiers: [],
            options: []
        )

        let friendRequestCategory = UNNotificationCategory(
            identifier: "FRIEND_REQUEST",
            actions: [
                UNNotificationAction(identifier: "ACCEPT_ACTION", title: "Accept ✓", options: [.foreground]),
                UNNotificationAction(identifier: "DECLINE_ACTION", title: "Decline ✗", options: [.destructive])
            ],
            intentIdentifiers: [],
            options: []
        )

        let taskAssignedCategory = UNNotificationCategory(
            identifier: "TASK_ASSIGNED",
            actions: [
                UNNotificationAction(identifier: "VIEW_TASK", title: "View Task", options: [.foreground])
            ],
            intentIdentifiers: [],
            options: []
        )

        let taskPendingReviewCategory = UNNotificationCategory(
            identifier: "TASK_PENDING_REVIEW",
            actions: [
                UNNotificationAction(identifier: "REVIEW_TASK", title: "Review Now", options: [.foreground])
            ],
            intentIdentifiers: [],
            options: []
        )

        notificationCenter.setNotificationCategories([
            taskCompletedCategory,
            friendRequestCategory,
            taskAssignedCategory,
            taskPendingReviewCategory
        ])
    }

    // MARK: - Send Notifications

    func sendFriendCompletedTaskNotification(friendName: String, taskTitle: String, xpEarned: Int, hasPhoto: Bool = false) {
        guard hasPermission else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(friendName) completed a task!"
        content.body = "\(taskTitle) • Earned \(xpEarned) XP"

        if hasPhoto {
            content.body += " 📸"
        }

        content.sound = .default
        content.categoryIdentifier = "TASK_COMPLETED"
        content.badge = 1

        content.userInfo = [
            "type": "task_completed",
            "friend": friendName,
            "task": taskTitle,
            "xp": xpEarned
        ]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Error sending notification: \(error)")
            }
        }
    }

    func sendFriendRequestNotification(fromUser: String) {
        guard hasPermission else { return }

        let content = UNMutableNotificationContent()
        content.title = "New Friend Request!"
        content.body = "\(fromUser) wants to be your friend"
        content.sound = .default
        content.categoryIdentifier = "FRIEND_REQUEST"
        content.badge = 1

        content.userInfo = [
            "type": "friend_request",
            "from": fromUser
        ]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request)
    }

    func sendLocationShareNotification(friendName: String) {
        guard hasPermission else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(friendName) is sharing location"
        content.body = "Your friend is now sharing their location with you"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request)
    }

    func sendMilestoneNotification(milestone: String, reward: Int) {
        guard hasPermission else { return }

        let content = UNMutableNotificationContent()
        content.title = "Milestone Achieved! 🎉"
        content.body = "\(milestone) • Earned \(reward) bonus XP"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request)
    }

    func sendSessionReminderNotification(minutesRemaining: Int) {
        guard hasPermission else { return }

        let content = UNMutableNotificationContent()
        content.title = "Screen Time Ending Soon"
        content.body = "\(minutesRemaining) minutes remaining in your session"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request)
    }

    func sendDailyGoalReminder() {
        guard hasPermission else { return }

        let content = UNMutableNotificationContent()
        content.title = "Daily Goal Reminder"
        content.body = "Complete a task to maintain your streak!"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 19
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily_reminder",
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request)
    }

    // MARK: - Task Notifications

    func sendTaskAssignedNotification(childName: String, taskTitle: String, difficulty: String, xpReward: Int) {
        guard hasPermission else { return }

        let content = UNMutableNotificationContent()
        content.title = "New Task Assigned! 📋"
        content.body = "\(taskTitle) • \(difficulty) • \(xpReward) XP"
        content.sound = .default
        content.categoryIdentifier = "TASK_ASSIGNED"
        content.badge = 1

        content.userInfo = [
            "type": "task_assigned",
            "child": childName,
            "task": taskTitle,
            "xp": xpReward
        ]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Error sending task assigned notification: \(error)")
            } else {
                print("✅ Task assigned notification sent to \(childName)")
            }
        }
    }

    func sendTaskPendingReviewNotification(childName: String, taskTitle: String, xpReward: Int) {
        guard hasPermission else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(childName) completed a task! ✅"
        content.body = "\(taskTitle) is pending your approval • \(xpReward) XP"
        content.sound = .default
        content.categoryIdentifier = "TASK_PENDING_REVIEW"
        content.badge = 1

        content.userInfo = [
            "type": "task_pending_review",
            "child": childName,
            "task": taskTitle,
            "xp": xpReward
        ]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Error sending task pending review notification: \(error)")
            } else {
                print("✅ Task pending review notification sent for \(childName)")
            }
        }
    }

    // MARK: - Badge Management

    func clearBadge() {
        notificationCenter.setBadgeCount(0)
    }

    func updateBadge(count: Int) {
        notificationCenter.setBadgeCount(count)
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        switch response.actionIdentifier {
        case "KUDOS_ACTION":
            if let friendName = userInfo["friend"] as? String {
                print("User gave kudos to \(friendName)")
            }

        case "ACCEPT_ACTION":
            if let fromUser = userInfo["from"] as? String {
                print("User accepted friend request from \(fromUser)")
            }

        case "DECLINE_ACTION":
            if let fromUser = userInfo["from"] as? String {
                print("User declined friend request from \(fromUser)")
            }

        case "VIEW_ACTION":
            print("User wants to view activity")

        default:
            break
        }

        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}
