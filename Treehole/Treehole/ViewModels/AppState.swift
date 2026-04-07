import Foundation
import Observation
import UserNotifications
import CloudKit

@Observable
final class AppState {
    private var isLoading = false

    /// Real CloudKit account status — populated asynchronously by `refreshCloudKitStatus()`.
    /// `.couldNotDetermine` until the first check returns.
    var cloudKitAccountStatus: CKAccountStatus = .couldNotDetermine

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
        isLoading = true
        loadState()
        isLoading = false
        L10n.lang = preferredLanguage
        checkAliasExpiry()
        Task { await refreshCloudKitStatus() }
        NotificationCenter.default.addObserver(
            forName: .CKAccountChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { await self?.refreshCloudKitStatus() }
        }
    }

    // MARK: - iCloud Sync Status

    /// True only when the user is signed in with Apple AND CloudKit reports an available account.
    /// Guest mode never reports active sync — the social cloud posts are tied to device_id and
    /// won't follow the user across devices, so showing "sync active" would mislead them.
    var isCloudSyncAvailable: Bool {
        guard !isGuest else { return false }
        return cloudKitAccountStatus == .available
            && FileManager.default.ubiquityIdentityToken != nil
    }

    var iCloudAccountStatus: String {
        if isGuest {
            return L10n.t("Sign in with Apple to enable sync", "登录 Apple 账户以启用同步")
        }
        switch cloudKitAccountStatus {
        case .available:
            return FileManager.default.ubiquityIdentityToken != nil
                ? L10n.t("Signed in", "已登录")
                : L10n.t("iCloud Drive disabled for Treehole", "未为 Treehole 开启 iCloud 云盘")
        case .noAccount:
            return L10n.t("Not signed into iCloud", "未登录 iCloud")
        case .restricted:
            return L10n.t("iCloud restricted on this device", "此设备的 iCloud 受限")
        case .temporarilyUnavailable:
            return L10n.t("iCloud temporarily unavailable", "iCloud 暂时不可用")
        case .couldNotDetermine:
            return L10n.t("Checking iCloud status…", "正在检查 iCloud 状态…")
        @unknown default:
            return L10n.t("Unknown", "未知")
        }
    }

    @MainActor
    func refreshCloudKitStatus() async {
        do {
            let status = try await CKContainer.default().accountStatus()
            cloudKitAccountStatus = status
        } catch {
            print("[CloudKit] account status error: \(error)")
            cloudKitAccountStatus = .couldNotDetermine
        }
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
        Task { await refreshCloudKitStatus() }

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
        Task { await refreshCloudKitStatus() }
        saveState()
    }

    // MARK: - Persistence (UserDefaults for preferences)

    private func saveState() {
        guard !isLoading else { return }
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
        isDeveloperMode = defaults.bool(forKey: "isDeveloperMode")
        appleUserID = defaults.string(forKey: "appleUserID")
        appleUserEmail = defaults.string(forKey: "appleUserEmail")
        isSubscribed = defaults.bool(forKey: "isSubscribed")
        selectedVoiceId = defaults.string(forKey: "selectedVoiceId") ?? "apple_default"
        colorSchemePreference = defaults.string(forKey: "colorSchemePreference") ?? "system"
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
