import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if appState.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingFlowView()
            }
        }
        .onAppear {
            #if DEBUG
            UITestSupport.applyLaunchOverridesIfNeeded(context: modelContext)
            #endif
        }
    }
}

// MARK: - Main Tab Navigation

struct MainTabView: View {
    @State private var selectedTab = 0
    @Query private var dailyTasks: [DailyTask]

    /// Remaining daily tasks nudge on the Me tab — cleared when all 4 are done.
    private var remainingTasks: Int {
        dailyTasks.filter { !$0.isCompleted }.count
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            CloudPostListView()
                .tabItem { Label(L10n.t("Clouds", "云朵"), systemImage: "cloud.fill") }
                .tag(0)
            PetHomeView()
                .tabItem { Label(L10n.t("Pet", "宠物"), systemImage: "cat.fill") }
                .tag(1)
            PlantGardenView()
                .tabItem { Label(L10n.t("Garden", "花园"), systemImage: "leaf.fill") }
                .tag(2)
            JournalView()
                .tabItem { Label(L10n.t("Journal", "日记"), systemImage: "book.fill") }
                .tag(3)
            MeView()
                .tabItem { Label(L10n.t("Me", "我"), systemImage: "person.fill") }
                .tag(4)
                .badge(remainingTasks)
        }
        .tint(TreeholeTheme.accentPurple)
    }
}

// MARK: - Me Tab (profile home: alias, streak, currencies, links)

struct MeView: View {
    @Environment(AppState.self) private var appState
    @Query private var economies: [Economy]
    @Query private var dailyTasks: [DailyTask]

    private var economy: Economy? { economies.first }
    private var completedTasks: Int { dailyTasks.filter(\.isCompleted).count }

    var body: some View {
        NavigationStack {
            ZStack {
                TreeholeTheme.warmBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: TreeholeTheme.spacingMedium) {
                        aliasCard
                        statsCard
                        linksSection
                        Spacer(minLength: TreeholeTheme.spacingXL)
                    }
                    .padding(.top, TreeholeTheme.spacingSmall)
                }
            }
            .navigationTitle(L10n.t("Me", "我"))
        }
    }

    // MARK: Alias hero card

    private var aliasCard: some View {
        NavigationLink {
            AliasExplanationView()
        } label: {
            VStack(spacing: TreeholeTheme.spacingSmall) {
                Image(systemName: "theatermasks")
                    .font(.system(size: 34))
                    .foregroundStyle(TreeholeTheme.accentPurple)
                    .accessibilityHidden(true)
                Text(appState.currentAlias)
                    .font(.system(.title2, design: .serif, weight: .bold))
                    .foregroundStyle(TreeholeTheme.textPrimary)
                Text(
                    appState.daysUntilAliasExpiry > 0
                        ? L10n.t("New alias in \(appState.daysUntilAliasExpiry)d — you stay anonymous", "\(appState.daysUntilAliasExpiry) 天后更换别名——你始终匿名")
                        : L10n.t("New alias soon — you stay anonymous", "别名即将更换——你始终匿名")
                )
                .font(.caption)
                .foregroundStyle(TreeholeTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, TreeholeTheme.spacingMedium)
        }
        .buttonStyle(.plain)
        .glassCard()
        .padding(.horizontal)
        .accessibilityHint(L10n.t("Learn how aliases work", "了解别名机制"))
    }

    // MARK: Streak + currencies + tasks

    private var statsCard: some View {
        HStack(spacing: 0) {
            statCell(emoji: "🔥", value: "\(economy?.loginStreak ?? 0)", label: L10n.t("Streak", "连续"))
            statCell(emoji: "🍖", value: "\(economy?.food ?? 0)", label: L10n.t("Food", "食物"))
            statCell(emoji: "🎫", value: "\(economy?.decorationTokens ?? 0)", label: L10n.t("Tokens", "代币"))
            statCell(emoji: "💎", value: "\(economy?.gems ?? 0)", label: L10n.t("Gems", "宝石"))
        }
        .frame(maxWidth: .infinity)
        .glassCard()
        .padding(.horizontal)
    }

    private func statCell(emoji: String, value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(emoji).font(.title3)
            Text(value)
                .font(.headline)
                .foregroundStyle(TreeholeTheme.textPrimary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(TreeholeTheme.textLight)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    // MARK: Links

    private var linksSection: some View {
        VStack(spacing: TreeholeTheme.spacingSmall) {
            NavigationLink {
                ShopView()
            } label: {
                linkRow(
                    icon: "bag.fill",
                    color: TreeholeTheme.warmGold,
                    title: L10n.t("Shop & Tasks", "商店 & 任务"),
                    subtitle: L10n.t("\(completedTasks)/\(dailyTasks.count) tasks done today", "今日任务 \(completedTasks)/\(dailyTasks.count)")
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                SettingsView()
            } label: {
                linkRow(
                    icon: "gearshape.fill",
                    color: TreeholeTheme.softPurple,
                    title: L10n.t("Settings", "设置"),
                    subtitle: L10n.t("Account, privacy lock, appearance", "账户、隐私锁、外观")
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
    }

    private func linkRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: TreeholeTheme.spacingSmall) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.15), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(TreeholeTheme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(TreeholeTheme.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(TreeholeTheme.textLight)
        }
        .glassCard()
    }
}
