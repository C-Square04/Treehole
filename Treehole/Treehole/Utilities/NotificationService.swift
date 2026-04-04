import Foundation
import UserNotifications

enum NotificationService {

    // MARK: - Identifier Prefixes

    private static let feedingID = "feeding_reminder"
    private static let wateringID = "watering_reminder"
    private static let checkinID = "checkin_reminder"

    // MARK: - Schedule Feeding Reminder (fires 4 hours after last feed)

    static func scheduleFeedingReminder() {
        cancel(type: feedingID)

        let content = UNMutableNotificationContent()
        content.title = L10n.t("Your pet is getting hungry!", "你的宠物饿了！")
        content.body = L10n.t("Come back and feed your companion", "回来喂你的小伙伴吧")
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 4 * 60 * 60,
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: feedingID,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Schedule Watering Reminder (fires 24 hours after last water)

    static func scheduleWateringReminder() {
        cancel(type: wateringID)

        let content = UNMutableNotificationContent()
        content.title = L10n.t("Your plant needs water!", "你的植物需要浇水了！")
        content.body = L10n.t("Don't let it dry out", "别让它干枯了")
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 24 * 60 * 60,
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: wateringID,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Schedule Daily Check-In Reminder at 9 AM

    static func scheduleDailyCheckIn() {
        cancel(type: checkinID)

        let content = UNMutableNotificationContent()
        content.title = L10n.t("Good morning!", "早上好！")
        content.body = L10n.t("Check in to keep your streak going", "签到保持连续记录")
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )
        let request = UNNotificationRequest(
            identifier: checkinID,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Cancel All Scheduled Reminders

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Cancel Specific Type

    static func cancel(type: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [type])
    }
}
