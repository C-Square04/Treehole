import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState

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

                    if appState.isGuest {
                        Button {
                            appState.showLoginPrompt = true
                        } label: {
                            Label(L10n.t("Sign In", "登录"), systemImage: "person.badge.plus")
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
                    HStack {
                        Text("Treehole")
                        Spacer()
                        Text(L10n.t("A safe space for your thoughts", "倾诉心声的安全空间"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Logout
                if !appState.isGuest {
                    Section {
                        Button(L10n.t("Sign Out", "退出登录"), role: .destructive) {
                            appState.logout()
                        }
                    }
                }
            }
            .navigationTitle(L10n.t("Settings", "设置"))
            .sheet(isPresented: $state.showLoginPrompt) {
                LoginPromptView()
            }
        }
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
