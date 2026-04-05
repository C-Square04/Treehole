import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(PrivacyLockManager.self) private var lockManager

    @State private var versionTapCount: Int = 0
    @State private var versionTapTimer: Timer? = nil
    @State private var showPasscodeSetup: Bool = false
    @State private var showRemovePasscode: Bool = false
    @State private var showCloudLockSetup: Bool = false
    @State private var showJournalLockSetup: Bool = false
    @State private var removePasscodeDigits: [Int] = []

    // Binding helpers that present setup if no passcode yet
    private var cloudLockBinding: Binding<Bool> {
        Binding(
            get: { lockManager.isCloudLockEnabled },
            set: { newValue in
                if newValue && lockManager.needsPasscodeSetup {
                    showCloudLockSetup = true
                } else if newValue {
                    lockManager.enableLock(for: .cloud)
                } else {
                    lockManager.disableLock(for: .cloud)
                }
            }
        )
    }

    private var journalLockBinding: Binding<Bool> {
        Binding(
            get: { lockManager.isJournalLockEnabled },
            set: { newValue in
                if newValue && lockManager.needsPasscodeSetup {
                    showJournalLockSetup = true
                } else if newValue {
                    lockManager.enableLock(for: .journal)
                } else {
                    lockManager.disableLock(for: .journal)
                }
            }
        )
    }

    var body: some View {
        @Bindable var state = appState

        NavigationStack {
            List {
                // Account section
                Section(L10n.t("Account", "账户")) {
                    HStack(spacing: TreeholeTheme.spacingSmall) {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundStyle(TreeholeTheme.softPurple)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(appState.currentAlias)
                                .font(.headline)
                            Text(appState.isGuest ? L10n.t("Guest", "访客") : L10n.t("Signed In", "已登录"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if appState.daysUntilAliasExpiry > 0 {
                            Text("\(appState.daysUntilAliasExpiry)d")
                                .font(.caption)
                                .foregroundStyle(TreeholeTheme.textLight)
                        }
                    }

                    NavigationLink {
                        ICloudSyncStatusView()
                    } label: {
                        HStack {
                            Image(systemName: appState.isCloudSyncAvailable ? "icloud.fill" : "icloud.slash")
                                .foregroundStyle(appState.isCloudSyncAvailable ? .green : .secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(appState.isCloudSyncAvailable
                                    ? L10n.t("iCloud Sync Active", "iCloud 同步已开启")
                                    : L10n.t("iCloud Not Available", "iCloud 不可用"))
                                Text(L10n.t("Tap for details", "点击查看详情"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    if appState.isGuest {
                        Button {
                            appState.showLoginPrompt = true
                        } label: {
                            Label(L10n.t("Sign In", "登录"), systemImage: "person.badge.plus")
                        }
                    } else {
                        // Signed in with Apple
                        HStack(spacing: TreeholeTheme.spacingSmall) {
                            Image(systemName: "apple.logo")
                                .font(.subheadline)
                                .foregroundStyle(TreeholeTheme.textPrimary)
                            Text(L10n.t("Signed in with Apple", "已通过 Apple 登录"))
                                .font(.subheadline)
                                .foregroundStyle(TreeholeTheme.textSecondary)
                        }
                        if let email = appState.appleUserEmail {
                            Text(email)
                                .font(.caption)
                                .foregroundStyle(TreeholeTheme.textLight)
                        }
                        Button(L10n.t("Sign Out", "退出登录"), role: .destructive) {
                            appState.logout()
                        }
                    }
                }

                // Alias explanation
                Section {
                    NavigationLink {
                        AliasExplanationView()
                    } label: {
                        Label(L10n.t("About Aliases", "关于别名"), systemImage: "theatermasks")
                    }
                } footer: {
                    Text(L10n.t(
                        "Your alias changes every 7 days to protect your privacy. No one can see your real identity.",
                        "你的别名每7天更换一次以保护你的隐私。没有人能看到你的真实身份。"
                    ))
                }

                // Privacy Lock
                Section(L10n.t("Privacy Lock", "隐私锁")) {
                    if lockManager.hasPasscode {
                        Toggle(L10n.t("Lock My Clouds", "锁定我的云朵"), isOn: cloudLockBinding)
                        Toggle(L10n.t("Lock Journal", "锁定日记"), isOn: journalLockBinding)

                        if lockManager.biometricType != .none {
                            @Bindable var lm = lockManager
                            Toggle(lockManager.biometricType.label, isOn: $lm.isBiometricEnabled)
                        }

                        NavigationLink {
                            PasscodeChangeView()
                                .environment(lockManager)
                        } label: {
                            Label(L10n.t("Change Passcode", "更改密码"), systemImage: "lock.rotation")
                        }

                        Button(role: .destructive) {
                            showRemovePasscode = true
                        } label: {
                            Label(L10n.t("Remove Passcode", "移除密码"), systemImage: "lock.slash")
                        }
                    } else {
                        Button {
                            showPasscodeSetup = true
                        } label: {
                            Label(L10n.t("Set Up Passcode", "设置密码"), systemImage: "lock.fill")
                        }
                    }
                }

                // Appearance
                Section(L10n.t("Appearance", "外观")) {
                    Picker(L10n.t("Language", "语言"), selection: $state.preferredLanguage) {
                        Text("English").tag("en")
                        Text("中文").tag("zh-Hans")
                    }

                    Toggle(L10n.t("Dark Mode", "深色模式"), isOn: $state.isDarkMode)
                }

                // About
                Section(L10n.t("About", "关于")) {
                    HStack {
                        Text(L10n.t("Version", "版本"))
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        versionTapCount += 1
                        versionTapTimer?.invalidate()
                        if versionTapCount >= 5 {
                            versionTapCount = 0
                            appState.isDeveloperMode.toggle()
                        } else {
                            versionTapTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
                                versionTapCount = 0
                            }
                        }
                    }
                    HStack {
                        Text("Treehole")
                        Spacer()
                        Text(L10n.t("A safe space for your thoughts", "倾诉心声的安全空间"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    NavigationLink {
                        PrivacyPolicyView()
                    } label: {
                        Label(L10n.t("Privacy Policy", "隐私政策"), systemImage: "lock.shield")
                    }
                }

                // Developer Mode (visible only when enabled)
                if appState.isDeveloperMode {
                    Section {
                        NavigationLink {
                            DeveloperSettingsView()
                        } label: {
                            Label(L10n.t("Developer Settings", "开发者设置"), systemImage: "wrench.and.screwdriver")
                                .foregroundStyle(.orange)
                        }
                    } header: {
                        Label(L10n.t("Developer", "开发者"), systemImage: "hammer")
                            .foregroundStyle(.orange)
                    }
                }


            }
            .navigationTitle(L10n.t("Settings", "设置"))
            .sheet(isPresented: $state.showLoginPrompt) {
                LoginPromptView()
            }
            .sheet(isPresented: $showPasscodeSetup) {
                NavigationStack {
                    PasscodeSetupView()
                        .environment(lockManager)
                }
            }
            .sheet(isPresented: $showCloudLockSetup) {
                NavigationStack {
                    PasscodeSetupView {
                        lockManager.enableLock(for: .cloud)
                    }
                    .environment(lockManager)
                }
            }
            .sheet(isPresented: $showJournalLockSetup) {
                NavigationStack {
                    PasscodeSetupView {
                        lockManager.enableLock(for: .journal)
                    }
                    .environment(lockManager)
                }
            }
            .alert(L10n.t("Remove Passcode", "移除密码"), isPresented: $showRemovePasscode) {
                RemovePasscodeAlert(lockManager: lockManager)
            } message: {
                Text(L10n.t("This will disable all privacy locks.", "这将关闭所有隐私锁。"))
            }
        }
    }
}

// MARK: - Remove Passcode Alert Content

private struct RemovePasscodeAlert: View {
    let lockManager: PrivacyLockManager
    @State private var passcode: String = ""

    var body: some View {
        SecureField(L10n.t("Enter passcode to confirm", "输入密码以确认"), text: $passcode)
        Button(L10n.t("Remove", "移除"), role: .destructive) {
            _ = lockManager.removePasscode(verify: passcode)
        }
        Button(L10n.t("Cancel", "取消"), role: .cancel) { }
    }
}

// MARK: - Alias Explanation View

struct AliasExplanationView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView {
            VStack(spacing: TreeholeTheme.spacingLarge) {
                // Current alias card
                VStack(spacing: TreeholeTheme.spacingSmall) {
                    Image(systemName: "theatermasks.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(TreeholeTheme.softPurple)

                    Text(L10n.t("Your Current Alias", "你的当前别名"))
                        .font(.headline)
                        .foregroundStyle(TreeholeTheme.textSecondary)

                    Text(appState.currentAlias)
                        .font(.title.bold())
                        .foregroundStyle(TreeholeTheme.textPrimary)

                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                        Text(L10n.t("Changes in \(appState.daysUntilAliasExpiry) days", "\(appState.daysUntilAliasExpiry) 天后更换"))
                    }
                    .font(.caption)
                    .foregroundStyle(TreeholeTheme.textLight)
                }
                .frame(maxWidth: .infinity)
                .glassCard()

                // Explanation cards
                VStack(alignment: .leading, spacing: TreeholeTheme.spacingMedium) {
                    ExplanationRow(
                        icon: "theatermasks",
                        color: TreeholeTheme.softPurple,
                        title: L10n.t("What are aliases?", "什么是别名？"),
                        text: L10n.t(
                            "Everyone on Treehole gets a random display name. This keeps you completely anonymous when sharing your thoughts.",
                            "树洞上的每个人都会获得一个随机显示名。这让你在分享想法时保持完全匿名。"
                        )
                    )
                    Divider()
                    ExplanationRow(
                        icon: "arrow.triangle.2.circlepath",
                        color: TreeholeTheme.skyBlue,
                        title: L10n.t("Automatic rotation", "自动轮换"),
                        text: L10n.t(
                            "Your alias changes every 7 days automatically. You'll receive a notification when it changes so you know your new name.",
                            "你的别名每7天自动更换。更换时你会收到通知，以便知道你的新名字。"
                        )
                    )
                    Divider()
                    ExplanationRow(
                        icon: "lock.shield",
                        color: TreeholeTheme.mintCream,
                        title: L10n.t("Your privacy matters", "你的隐私很重要"),
                        text: L10n.t(
                            "No one — not even other users — can see your real name or connect your posts to your identity. Your real name stays on your device only.",
                            "没有人——包括其他用户——可以看到你的真实姓名或将你的帖子与你的身份联系起来。你的真实姓名仅保存在你的设备上。"
                        )
                    )
                    Divider()
                    ExplanationRow(
                        icon: "link.badge.plus",
                        color: TreeholeTheme.coral,
                        title: L10n.t("Posts are disconnected", "帖子相互独立"),
                        text: L10n.t(
                            "When your alias changes, your old posts still show the old alias. This makes it even harder for anyone to track your activity.",
                            "当你的别名更改时，你的旧帖子仍显示旧别名。这让任何人都更难追踪你的活动。"
                        )
                    )
                }
                .glassCard()
            }
            .padding()
        }
        .navigationTitle(L10n.t("About Aliases", "关于别名"))
        .treeholeBackground()
    }
}

// MARK: - Privacy Policy View

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: TreeholeTheme.spacingLarge) {
                // Header card
                VStack(spacing: TreeholeTheme.spacingSmall) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(TreeholeTheme.softPurple)

                    Text(L10n.t("Privacy Policy", "隐私政策"))
                        .font(.title2.bold())
                        .foregroundStyle(TreeholeTheme.textPrimary)

                    Text(L10n.t("Last Updated: April 2026", "最后更新：2026年4月"))
                        .font(.caption)
                        .foregroundStyle(TreeholeTheme.textLight)
                }
                .frame(maxWidth: .infinity)
                .glassCard()

                // Policy sections card
                VStack(alignment: .leading, spacing: TreeholeTheme.spacingMedium) {
                    PrivacyPolicyRow(
                        icon: "internaldrive",
                        color: TreeholeTheme.skyBlue,
                        title: L10n.t("Data Collection", "数据收集"),
                        text: L10n.t(
                            "Treehole stores all your data locally on your device. We do not collect, transmit, or store any personal information on external servers.",
                            "树洞将你所有的数据存储在你的设备本地。我们不会在外部服务器上收集、传输或存储任何个人信息。"
                        )
                    )
                    Divider()
                    PrivacyPolicyRow(
                        icon: "theatermasks",
                        color: TreeholeTheme.softPurple,
                        title: L10n.t("Anonymous Identity", "匿名身份"),
                        text: L10n.t(
                            "Your alias is randomly generated and changes every 7 days. Your real name is never shared.",
                            "你的别名是随机生成的，每7天更换一次。你的真实姓名不会被分享。"
                        )
                    )
                    Divider()
                    PrivacyPolicyRow(
                        icon: "bell.badge",
                        color: TreeholeTheme.coral,
                        title: L10n.t("Notifications", "通知"),
                        text: L10n.t(
                            "We send local push notifications to remind you about feeding, watering, and daily check-ins. No data is sent to any server.",
                            "我们发送本地推送通知，提醒你喂食、浇水和每日签到。不会向任何服务器发送数据。"
                        )
                    )
                    Divider()
                    PrivacyPolicyRow(
                        icon: "shield.slash",
                        color: TreeholeTheme.mintCream,
                        title: L10n.t("Third-Party Services", "第三方服务"),
                        text: L10n.t(
                            "Treehole does not use any third-party analytics, advertising, or tracking services.",
                            "树洞不使用任何第三方分析、广告或追踪服务。"
                        )
                    )
                    Divider()
                    PrivacyPolicyRow(
                        icon: "trash",
                        color: TreeholeTheme.textLight,
                        title: L10n.t("Data Deletion", "数据删除"),
                        text: L10n.t(
                            "You can delete all your data by removing the app from your device. All data is stored locally and will be permanently deleted.",
                            "你可以通过从设备中删除应用来删除所有数据。所有数据均存储在本地，将被永久删除。"
                        )
                    )
                    Divider()
                    PrivacyPolicyRow(
                        icon: "envelope",
                        color: TreeholeTheme.skyBlue,
                        title: L10n.t("Contact", "联系我们"),
                        text: L10n.t(
                            "For questions about privacy, contact: toki.studio.app@gmail.com",
                            "如有隐私问题，请联系：toki.studio.app@gmail.com"
                        )
                    )
                }
                .glassCard()

                Text(L10n.t("© 2026 Toki Studio. Jimmy Chen & Kayli Cheung.", "© 2026 Toki Studio. 陈韬 & 张凯莉。"))
                    .font(.caption2)
                    .foregroundStyle(TreeholeTheme.textLight)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
        .navigationTitle(L10n.t("Privacy Policy", "隐私政策"))
        .treeholeBackground()
    }
}

private struct PrivacyPolicyRow: View {
    let icon: String
    let color: Color
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: TreeholeTheme.spacingSmall) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(TreeholeTheme.textPrimary)
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(TreeholeTheme.textSecondary)
            }
        }
    }
}

// MARK: - Explanation Row

private struct ExplanationRow: View {
    let icon: String
    let color: Color
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: TreeholeTheme.spacingSmall) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(TreeholeTheme.textPrimary)
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(TreeholeTheme.textSecondary)
            }
        }
    }
}

// MARK: - iCloud Sync Status View

struct ICloudSyncStatusView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: appState.isCloudSyncAvailable ? "person.icloud.fill" : "icloud.slash")
                        .foregroundStyle(appState.isCloudSyncAvailable ? .green : .red)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.t("iCloud Account", "iCloud 账户"))
                        Text(appState.iCloudAccountStatus)
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }

                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(TreeholeTheme.skyBlue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.t("Sync Mode", "同步模式"))
                        Text(L10n.t("Automatic (when online)", "自动（联网时）"))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text(L10n.t("Status", "状态"))
            } footer: {
                Text(L10n.t(
                    "iCloud syncs when online. Data is safe locally even offline.",
                    "iCloud 联网时自动同步。离线时数据安全保存在本地。"
                ))
            }
            Section(L10n.t("Synced Data", "同步数据")) {
                SyncDataRow(icon: "cat.fill", color: TreeholeTheme.coral, title: L10n.t("Pet", "宠物"), detail: L10n.t("Hunger, energy, level, theme", "饥饿、能量、等级、主题"))
                SyncDataRow(icon: "leaf.fill", color: TreeholeTheme.mintCream, title: L10n.t("Plants", "植物"), detail: L10n.t("Growth, hydration, species", "成长、水分、品种"))
                SyncDataRow(icon: "book.fill", color: TreeholeTheme.warmGold, title: L10n.t("Journal", "日记"), detail: L10n.t("Entries, moods, photos", "日记、情绪、照片"))
                SyncDataRow(icon: "bag.fill", color: TreeholeTheme.softPurple, title: L10n.t("Economy", "经济"), detail: L10n.t("Food, tokens, tasks", "食物、装饰币、任务"))
            }
            Section {
                SyncDataRow(icon: "cloud.fill", color: TreeholeTheme.skyBlue, title: L10n.t("Cloud Posts", "云朵帖子"), detail: L10n.t("Synced via server", "通过服务器同步"))
            } header: {
                Text(L10n.t("Server Data", "服务器数据"))
            } footer: {
                Text(L10n.t("Cloud posts sync via Apple ID across all devices.", "云朵帖子通过 Apple ID 在所有设备间同步。"))
            }
            Section(L10n.t("Info", "说明")) {
                Text(L10n.t("iCloud sync happens automatically. Changes appear on other devices within minutes.", "iCloud 自动同步，更改会在几分钟内出现在其他设备上。"))
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle(L10n.t("iCloud Sync", "iCloud 同步"))
    }
}

private struct SyncDataRow: View {
    let icon: String; let color: Color; let title: String; let detail: String
    var body: some View {
        HStack(spacing: TreeholeTheme.spacingSmall) {
            Image(systemName: icon).foregroundStyle(color).frame(width: 24)
            VStack(alignment: .leading, spacing: 2) { Text(title); Text(detail).font(.caption).foregroundStyle(.secondary) }
            Spacer()
            Image(systemName: "checkmark.icloud.fill").foregroundStyle(.green).font(.caption)
        }
    }
}
