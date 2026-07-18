import Foundation
import UserNotifications

enum NotificationService {

    // MARK: - Identifier Prefixes

    private static let feedingID = "feeding_reminder"
    private static let wateringID = "watering_reminder"
    private static let checkinID = "checkin_reminder"
    private static let eveningCheckinID = "eveningCheckIn"

    // MARK: - UserDefaults keys

    static let lastUnreadCheckKey = "notif_lastUnreadCheck"
    static let lastNotificationFiredKey = "notif_lastNotificationFired"

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

    // The trigger repeats, so the content must be evergreen: an unread count
    // fetched at scheduling time would replay the same stale number every
    // morning. Count-specific messages go through the on-demand
    // checkUnreadInteractionsAndNotify() path (runs on scene active) instead.
    static func scheduleDailyCheckIn() {
        cancel(type: checkinID)

        let content = UNMutableNotificationContent()
        content.title = L10n.t("Good morning!", "早上好！")
        content.body = L10n.t(
            "Take a moment to check in with yourself 💙",
            "花点时间关注一下自己 💙"
        )
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

    // MARK: - Schedule Evening Check-In Reminder at 6 PM

    static func scheduleEveningCheckIn() {
        cancel(type: eveningCheckinID)

        let content = UNMutableNotificationContent()
        content.title = L10n.t("Evening check-in", "晚间问候")
        content.body = L10n.t("Your tree pet misses you 🐱 Stop by for a moment", "你的树洞宠物想你了 🐱 来看看吧")
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 18
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )
        let request = UNNotificationRequest(
            identifier: eveningCheckinID,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Schedule All Daily Notifications

    static func scheduleAllNotifications() {
        scheduleDailyCheckIn()
        scheduleEveningCheckIn()
    }

    // MARK: - Check Unread Interactions and Notify

    /// Call from scene active. Fetches unread counts since last check and fires a
    /// local notification if interactions exist. Throttled to once per 6 hours.
    static func checkUnreadInteractionsAndNotify() async {
        let defaults = UserDefaults.standard

        // Throttle: don't fire more than once per 6 hours
        if let lastFired = defaults.object(forKey: lastNotificationFiredKey) as? Date {
            let sixHours: TimeInterval = 6 * 3600
            if Date().timeIntervalSince(lastFired) < sixHours {
                return
            }
        }

        // Determine since date (default: 7 days ago)
        let since: Date
        if let stored = defaults.object(forKey: lastUnreadCheckKey) as? Date {
            since = stored
        } else {
            since = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        }

        let (commentCount, reactionCount) = await SupabaseService.fetchUnreadCount(since: since)
        let total = commentCount + reactionCount
        // Keep the home-screen widget's unread state fresh either way.
        WidgetStateStore.setUnreadCount(total)

        guard total > 0 else {
            // Update check timestamp even when no unread, so we move window forward
            defaults.set(Date(), forKey: lastUnreadCheckKey)
            return
        }

        // Fire immediate local notification
        let content = UNMutableNotificationContent()
        content.title = L10n.t("New replies on your clouds", "你的云朵收到新回复")
        content.body = L10n.t(
            "\(commentCount) new comments and \(reactionCount) new reactions",
            "\(commentCount) 条新评论和 \(reactionCount) 个新反应"
        )
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "unread_interactions_\(UUID().uuidString)",
            content: content,
            trigger: nil // fire immediately
        )
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("[Notification] checkUnreadInteractionsAndNotify failed: \(error)")
        }

        // Update timestamps after firing
        defaults.set(Date(), forKey: lastUnreadCheckKey)
        defaults.set(Date(), forKey: lastNotificationFiredKey)
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
