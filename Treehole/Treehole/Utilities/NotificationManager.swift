//
//  NotificationManager.swift
//  Treehole
//
//  Created by Kayli Cheung & Jimmy Chen on 2025-11-06.
//

import UserNotifications
import Foundation
import Combine
import UIKit

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    @Published var isAuthorized: Bool = false

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
            }
            if let error = error {
                print("Notification authorization error: \(error)")
            }
        }
    }

    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    // MARK: - Schedule Notifications

    func scheduleReminder(type: NotificationPermission.NotificationType, title: String, body: String, delay: TimeInterval = 3600) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = NSNumber(value: 1)

        // Add custom data
        content.userInfo = ["type": type.rawValue]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }

    // MARK: - Pet-related Notifications

    func scheduleFeedingReminder(for petName: String) {
        scheduleReminder(
            type: .feeding,
            title: "Time to feed your pet!",
            body: "\(petName) is getting hungry. Give them some love!",
            delay: 3600 // 1 hour
        )
    }

    func scheduleWateringReminder(for plantName: String) {
        scheduleReminder(
            type: .watering,
            title: "Your plant needs water",
            body: "💧 \(plantName) is thirsty. Let's take care of it!",
            delay: 86400 // 1 day
        )
    }

    // MARK: - Daily Task Reminder

    func scheduleDailyTaskReminder() {
        scheduleReminder(
            type: .task,
            title: "Daily tasks are waiting!",
            body: "Complete today's tasks to earn rewards.",
            delay: 3600
        )
    }

    // MARK: - Story/Event Notification

    func scheduleStoryNotification(title: String, body: String) {
        scheduleReminder(
            type: .story,
            title: title,
            body: body,
            delay: 3600
        )
    }

    // MARK: - Delegate Methods

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Handle notification when app is in foreground
        let userInfo = notification.request.content.userInfo
        print("Foreground notification: \(userInfo)")

        // Show notification even when app is active
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle notification tap
        let userInfo = response.notification.request.content.userInfo
        if let typeString = userInfo["type"] as? String,
           let type = NotificationPermission.NotificationType(rawValue: typeString) {
            handleNotificationTap(for: type)
        }

        completionHandler()
    }

    private func handleNotificationTap(for type: NotificationPermission.NotificationType) {
        switch type {
        case .feeding:
            print("User tapped feeding reminder")
        case .watering:
            print("User tapped watering reminder")
        case .story:
            print("User tapped story notification")
        case .task:
            print("User tapped task reminder")
        case .event:
            print("User tapped event notification")
        }
    }

    // MARK: - Clear Notifications

    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
}
