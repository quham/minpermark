import Foundation
import UserNotifications
import UIKit

@MainActor
@Observable
class NotificationManager {
    static let shared = NotificationManager()

    var isAuthorized = false
    var isDenied = false

    private init() {
        checkAuthorizationStatus()
    }

    private var notificationSoundEnabled: Bool {
        UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.notificationSoundEnabled) as? Bool ?? true
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            await MainActor.run {
                isAuthorized = granted
            }
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.isAuthorized = settings.authorizationStatus == .authorized
                self.isDenied = settings.authorizationStatus == .denied
            }
        }
    }

    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Schedule Notifications

    func scheduleGoalReminder(for goal: Goal) {
        guard isAuthorized else { return }

        // Remove existing notifications for this goal
        removeNotifications(for: goal.id)

        switch goal.triggerType {
        case .time:
            scheduleTimeBasedReminder(for: goal)
        case .after, .location:
            scheduleCheckInReminder(for: goal)
        }
    }

    private func scheduleTimeBasedReminder(for goal: Goal) {
        // Parse time from triggerValue (format: "7:00 AM")
        let formatter = DateFormatter()
        formatter.timeStyle = .short

        guard let date = formatter.date(from: goal.triggerValue) else { return }

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let content = UNMutableNotificationContent()
        content.title = "Time for \(goal.microHabit)"
        content.body = "Small steps add up."
        content.sound = notificationSoundEnabled ? .default : nil
        content.categoryIdentifier = "GOAL_REMINDER"
        content.userInfo = ["goalId": goal.id.uuidString]

        let request = UNNotificationRequest(
            identifier: "goal-\(goal.id.uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }

    private func scheduleCheckInReminder(for goal: Goal) {
        // For "after" and "location" triggers, schedule a gentle check-in
        // at a reasonable time (e.g., 10 AM if morning, 6 PM if evening)

        var dateComponents = DateComponents()
        dateComponents.hour = 10 // Default morning check-in
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let content = UNMutableNotificationContent()
        content.title = "Gentle reminder"
        content.body = "Have you done \"\(goal.microHabit)\" yet? Small steps matter."
        content.sound = notificationSoundEnabled ? .default : nil
        content.categoryIdentifier = "GOAL_CHECKIN"
        content.userInfo = ["goalId": goal.id.uuidString]

        let request = UNNotificationRequest(
            identifier: "checkin-\(goal.id.uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Streak Notifications

    func scheduleStreakReminder() {
        guard isAuthorized else { return }

        // Remove existing streak notification
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["streak-reminder"])

        // Schedule for 8 PM daily
        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let content = UNMutableNotificationContent()
        content.title = "Keep your streak alive"
        content.body = "You still have time to complete a goal today. Don't break the chain!"
        content.sound = notificationSoundEnabled ? .default : nil
        content.categoryIdentifier = "STREAK_REMINDER"

        let request = UNNotificationRequest(
            identifier: "streak-reminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func scheduleStreakCelebration(days: Int) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()

        if days == 7 {
            content.title = "One week strong!"
            content.body = "You've built a 7-day streak. You're forming a real habit."
        } else if days == 30 {
            content.title = "One month!"
            content.body = "30 days of consistency. This is becoming part of who you are."
        } else if days == 100 {
            content.title = "100 days!"
            content.body = "This habit is now a part of your life. Incredible dedication."
        } else {
            return // Only celebrate milestones
        }

        content.sound = notificationSoundEnabled ? .default : nil

        // Deliver immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: "streak-celebration-\(days)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Weekly Review Notifications

    func scheduleWeeklyReviewNotification() {
        guard isAuthorized else { return }

        // Remove existing weekly review notification
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Constants.NotificationIdentifiers.weeklyReview])

        let dayOfWeek = UserDefaults.standard.integer(forKey: Constants.UserDefaultsKeys.weeklyReviewDay)
        // Default to Sunday (1) if not set. Calendar.current.component(.weekday, from: Date()) returns 1-7
        let weekday = dayOfWeek == 0 ? 1 : dayOfWeek

        let savedTime = UserDefaults.standard.double(forKey: Constants.UserDefaultsKeys.weeklyReviewTime)
        // Default to 7 PM if not set (19 * 3600)
        let timeInterval = savedTime == 0 ? 19 * 3600 : savedTime

        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60

        var dateComponents = DateComponents()
        dateComponents.weekday = weekday
        dateComponents.hour = hours
        dateComponents.minute = minutes

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let content = UNMutableNotificationContent()
        content.title = "Time for your Weekly Review"
        content.body = "See how far you've come this week and plan for next."
        content.sound = notificationSoundEnabled ? .default : nil
        content.categoryIdentifier = Constants.NotificationIdentifiers.weeklyReview

        let request = UNNotificationRequest(
            identifier: Constants.NotificationIdentifiers.weeklyReview,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule weekly review notification: \(error)")
            }
        }
    }

    // MARK: - Unlock Notifications

    func scheduleUnlockNotifications(expiryDate: Date) {
        guard isAuthorized else { return }

        // 1. Schedule 1-minute warning
        let warningTime = expiryDate.addingTimeInterval(-60)
        if warningTime > Date() {
            let warningContent = UNMutableNotificationContent()
            warningContent.title = "1 minute left"
            warningContent.body = "Your apps will be locked soon. Wrap up what you're doing!"
            warningContent.sound = notificationSoundEnabled ? .default : nil
            warningContent.categoryIdentifier = Constants.NotificationIdentifiers.unlockWarning

            let warningComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: warningTime)
            let warningTrigger = UNCalendarNotificationTrigger(dateMatching: warningComponents, repeats: false)

            let warningRequest = UNNotificationRequest(
                identifier: Constants.NotificationIdentifiers.unlockWarning,
                content: warningContent,
                trigger: warningTrigger
            )

            UNUserNotificationCenter.current().add(warningRequest)
        }

        // 2. Schedule "Time's Up" notification
        let endedContent = UNMutableNotificationContent()
        endedContent.title = "Time's up"
        endedContent.body = "Your focus session has ended. Apps are now locked."
        endedContent.sound = notificationSoundEnabled ? .default : nil
        endedContent.categoryIdentifier = Constants.NotificationIdentifiers.unlockEnded

        let endedComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: expiryDate)
        let endedTrigger = UNCalendarNotificationTrigger(dateMatching: endedComponents, repeats: false)

        let endedRequest = UNNotificationRequest(
            identifier: Constants.NotificationIdentifiers.unlockEnded,
            content: endedContent,
            trigger: endedTrigger
        )

        UNUserNotificationCenter.current().add(endedRequest)
    }

    func cancelUnlockNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            Constants.NotificationIdentifiers.unlockWarning,
            Constants.NotificationIdentifiers.unlockEnded
        ])
    }

    // MARK: - Remove Notifications

    func removeNotifications(for goalId: UUID) {
        let identifiers = [
            "goal-\(goalId.uuidString)",
            "checkin-\(goalId.uuidString)"
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Notification Actions

    func setupNotificationCategories() {
        // Goal reminder actions
        let completeAction = UNNotificationAction(
            identifier: "COMPLETE_GOAL",
            title: "I did it!",
            options: .foreground
        )

        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_GOAL",
            title: "Remind me later",
            options: []
        )

        let goalCategory = UNNotificationCategory(
            identifier: "GOAL_REMINDER",
            actions: [completeAction, snoozeAction],
            intentIdentifiers: []
        )

        // Check-in actions
        let doneAction = UNNotificationAction(
            identifier: "DONE_CHECKIN",
            title: "Done",
            options: .foreground
        )

        let notYetAction = UNNotificationAction(
            identifier: "NOT_YET_CHECKIN",
            title: "Not yet",
            options: []
        )

        let checkinCategory = UNNotificationCategory(
            identifier: "GOAL_CHECKIN",
            actions: [doneAction, notYetAction],
            intentIdentifiers: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([goalCategory, checkinCategory])
    }
}

// MARK: - Notification Delegate

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        switch response.actionIdentifier {
        case "COMPLETE_GOAL", "DONE_CHECKIN":
            if let goalIdString = userInfo["goalId"] as? String {
                // Post notification to open goal completion flow
                NotificationCenter.default.post(
                    name: .completeGoalFromNotification,
                    object: nil,
                    userInfo: ["goalId": goalIdString]
                )
            }

        case "SNOOZE_GOAL":
            // Reschedule for 30 minutes later
            if let goalIdString = userInfo["goalId"] as? String {
                scheduleSnooze(goalId: goalIdString)
            }

        default:
            break
        }

        completionHandler()
    }

    private func scheduleSnooze(goalId: String) {
        let content = UNMutableNotificationContent()
        content.title = "Reminder"
        content.body = "Time to complete your habit!"
        content.sound = .default
        content.userInfo = ["goalId": goalId]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 30 * 60, repeats: false)

        let request = UNNotificationRequest(
            identifier: "snooze-\(goalId)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let completeGoalFromNotification = Notification.Name("completeGoalFromNotification")
}
