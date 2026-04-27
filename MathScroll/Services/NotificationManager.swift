import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()
        _ = try? await center.requestAuthorization(options: [.alert, .badge, .sound])
    }

    func scheduleWeeklyDigest() {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "Your weekly maths digest"
        content.body = "See your top 3 weaknesses and recommended practice."
        var date = DateComponents()
        date.weekday = 1   // Sunday
        date.hour = 19
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let req = UNNotificationRequest(identifier: "weekly_digest", content: content, trigger: trigger)
        center.add(req)
    }
}
