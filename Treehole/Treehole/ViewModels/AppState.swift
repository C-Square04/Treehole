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
        didSet {
            L10n.lang = preferredLanguage
            saveState()
        }
    }
    var isDarkMode: Bool = false {
        didSet { saveState() }
    }
    var colorSchemePreference: String = "system" {  // "system", "light", "dark"
        didSet { saveState() }
    }
    var isDeveloperMode: Bool = false {
        didSet { saveState() }
    }
    var appleUserID: String? = nil {
        didSet { saveState() }
    }
    var appleUserEmail: String? = nil
    var isSubscribed: Bool = false {
        didSet { saveState() }
    }
    var selectedVoiceId: String = "apple_default" {
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
        L10n.lang = preferredLanguage
        checkAliasExpiry()
    }

    // MARK: - Alias System

    var isCloudSyncAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    var iCloudAccountStatus: String {
        if FileManager.default.ubiquityIdentityToken == nil {
            return L10n.t("Not signed into iCloud", "未登录 iCloud")
        }
        return L10n.t("Signed in", "已登录")
    }

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

    func loginWithApple(userID: String, email: String?) {
        appleUserID = userID
        appleUserEmail = email
        isGuest = false
        hasCompletedOnboarding = true

        // Migrate existing device_id posts to this apple_user_id
        Task {
            try? await SupabaseService.migratePostsToAppleUser(
                deviceId: SupabaseConfig.deviceId,
                appleUserId: userID
            )
        }

        saveState()
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        saveState()
    }

    func logout() {
        isGuest = true
        appleUserID = nil
        appleUserEmail = nil
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
        defaults.set(colorSchemePreference, forKey: "colorSchemePreference")
        defaults.set(isDeveloperMode, forKey: "isDeveloperMode")
        defaults.set(appleUserID, forKey: "appleUserID")
        defaults.set(appleUserEmail, forKey: "appleUserEmail")
        defaults.set(isSubscribed, forKey: "isSubscribed")
        defaults.set(selectedVoiceId, forKey: "selectedVoiceId")
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
        colorSchemePreference = defaults.string(forKey: "colorSchemePreference") ?? "system"
        isDeveloperMode = defaults.bool(forKey: "isDeveloperMode")
        appleUserID = defaults.string(forKey: "appleUserID")
        appleUserEmail = defaults.string(forKey: "appleUserEmail")
        isSubscribed = defaults.bool(forKey: "isSubscribed")
        selectedVoiceId = defaults.string(forKey: "selectedVoiceId") ?? "apple_default"
    }

    // MARK: - Subscriber Bonus

    func grantSubscriberDailyBonus(economy: Economy) {
        guard isSubscribed else { return }
        let defaults = UserDefaults.standard
        let today = Calendar.current.startOfDay(for: Date())
        let lastBonus = defaults.object(forKey: "lastSubscriberBonus") as? Date
        if lastBonus == nil || !Calendar.current.isDate(lastBonus!, inSameDayAs: today) {
            economy.addFood(30)
            defaults.set(today, forKey: "lastSubscriberBonus")
        }
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
