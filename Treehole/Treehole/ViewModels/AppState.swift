import Foundation
import Observation
import UserNotifications

@Observable
final class AppState {
    var isGuest: Bool = true
    var hasCompletedOnboarding: Bool = false
    var currentAlias: String = "Anonymous"
    var aliasExpiryDate: Date = Date()
    var showLoginPrompt: Bool = false
    var preferredLanguage: String = "en" {
        didSet { saveState() }
    }
    var isDarkMode: Bool = false {
        didSet { saveState() }
    }

    // MARK: - Alias Name Pool

    static let aliasNames = [
        "Wandering Cloud", "Quiet Moon", "Starry Breeze", "Gentle Rain",
        "Hidden River", "Silent Leaf", "Dreamy Fox", "Little Sparrow",
        "Night Owl", "Morning Dew", "Paper Crane", "Warm Stone",
        "Blue Whale", "Snow Rabbit", "Firefly", "Sleepy Cat",
        "风中云", "静月", "星风", "柔雨",
        "隐河", "落叶", "梦狐", "小雀",
        "夜鸮", "晨露", "纸鹤", "暖石",
        "蓝鲸", "雪兔", "萤火", "睡猫"
    ]

    init() {
        loadState()
        checkAliasExpiry()
    }

    // MARK: - Alias System

    var isAliasExpired: Bool {
        Date() > aliasExpiryDate
    }

    var daysUntilAliasExpiry: Int {
        guard aliasExpiryDate > Date() else { return 0 }
        return Calendar.current.dateComponents([.day], from: Date(), to: aliasExpiryDate).day ?? 0
    }

    func rotateAlias() {
        let newAlias = Self.aliasNames.randomElement() ?? "Anonymous"
        currentAlias = newAlias
        aliasExpiryDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        saveState()
        scheduleAliasRotationReminder()
    }

    func checkAliasExpiry() {
        if currentAlias == "Anonymous" || isAliasExpired {
            rotateAlias()
        }
    }

    // MARK: - Auth

    func loginAsGuest() {
        isGuest = true
        hasCompletedOnboarding = true
        if currentAlias == "Anonymous" { rotateAlias() }
        saveState()
    }

    func loginWithApple() {
        // Placeholder — real Apple Sign-In integration in Phase 2+
        isGuest = false
        hasCompletedOnboarding = true
        saveState()
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        saveState()
    }

    func logout() {
        isGuest = true
        saveState()
    }

    // MARK: - Persistence (UserDefaults for preferences)

    private func saveState() {
        let defaults = UserDefaults.standard
        defaults.set(isGuest, forKey: "isGuest")
        defaults.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        defaults.set(currentAlias, forKey: "currentAlias")
        defaults.set(aliasExpiryDate, forKey: "aliasExpiryDate")
        defaults.set(preferredLanguage, forKey: "preferredLanguage")
        defaults.set(isDarkMode, forKey: "isDarkMode")
    }

    private func loadState() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "isGuest") != nil {
            isGuest = defaults.bool(forKey: "isGuest")
        }
        hasCompletedOnboarding = defaults.bool(forKey: "hasCompletedOnboarding")
        currentAlias = defaults.string(forKey: "currentAlias") ?? "Anonymous"
        aliasExpiryDate = defaults.object(forKey: "aliasExpiryDate") as? Date ?? Date()
        preferredLanguage = defaults.string(forKey: "preferredLanguage") ?? "en"
        isDarkMode = defaults.bool(forKey: "isDarkMode")
    }

    // MARK: - Notifications

    private func scheduleAliasRotationReminder() {
        let content = UNMutableNotificationContent()
        content.title = preferredLanguage == "zh-Hans" ? "别名已更新" : "Alias Updated"
        content.body = preferredLanguage == "zh-Hans"
            ? "你的新别名是「\(currentAlias)」，7天后将再次更换。"
            : "Your new alias is \"\(currentAlias)\". It will change again in 7 days."
        content.sound = .default

        // Remove old alias notification before scheduling new one
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["aliasRotation"])

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, aliasExpiryDate.timeIntervalSinceNow),
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: "aliasRotation",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
}
