import SwiftUI
import SwiftData

// MARK: - ShopView

struct ShopView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var economies: [Economy]
    @Query private var dailyTasks: [DailyTask]
    @Query private var weeklyChallenges: [WeeklyChallenge]
    @State private var viewModel = EconomyViewModel()
    @State private var selectedTab: ShopTab = .tasks

    enum ShopTab: String, CaseIterable {
        case tasks = "Tasks"
        case shop  = "Shop"

        var localizedLabel: String {
            switch self {
            case .tasks: return L10n.t("Tasks", "任务")
            case .shop:  return L10n.t("Shop", "商店")
            }
        }
    }

    private var economy: Economy? {
        economies.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                TreeholeTheme.warmBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Currency bar
                    if let eco = economy {
                        CurrencyBar(economy: eco)
                            .padding(.horizontal, TreeholeTheme.spacingMedium)
                            .padding(.top, TreeholeTheme.spacingSmall)
                    }

                    // Segmented tab picker
                    Picker(L10n.t("Section", "分类"), selection: $selectedTab) {
                        ForEach(ShopTab.allCases, id: \.self) { tab in
                            Text(tab.localizedLabel).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, TreeholeTheme.spacingMedium)
                    .padding(.vertical, TreeholeTheme.spacingSmall)

                    // Tab content
                    ScrollView {
                        switch selectedTab {
                        case .tasks:
                            TasksPanel(economy: economy, tasks: dailyTasks, challenges: weeklyChallenges, viewModel: viewModel)
                                .padding(.horizontal, TreeholeTheme.spacingMedium)
                                .padding(.bottom, TreeholeTheme.spacingXL)
                        case .shop:
                            ShopPanel(economy: economy, modelContext: modelContext)
                                .padding(.horizontal, TreeholeTheme.spacingMedium)
                                .padding(.bottom, TreeholeTheme.spacingXL)
                        }
                    }
                }
            }
            .navigationTitle(L10n.t("Shop & Tasks", "商店 & 任务"))
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            let eco = viewModel.ensureEconomyExists(context: modelContext, economies: economies)
            eco.checkLoginStreak()
            viewModel.resetDailyTasksIfNeeded(tasks: dailyTasks, context: modelContext)
            viewModel.createDailyTasks(context: modelContext, existingTasks: dailyTasks)
            viewModel.resetWeeklyChallengesIfNeeded(challenges: weeklyChallenges, context: modelContext)
            viewModel.createWeeklyChallenges(context: modelContext, existing: weeklyChallenges)
            try? modelContext.save()
        }
    }
}

// MARK: - Currency Bar

private struct CurrencyBar: View {
    let economy: Economy

    var body: some View {
        HStack(spacing: 0) {
            CurrencyItem(emoji: "🍖", label: L10n.t("Food", "食物"), value: economy.food)
            Divider().frame(height: 30)
            CurrencyItem(emoji: "🎫", label: L10n.t("Tokens", "装饰币"), value: economy.decorationTokens)
            Divider().frame(height: 30)
            CurrencyItem(emoji: "💎", label: L10n.t("Gems", "宝石"), value: economy.gems)
        }
        .glassCard()
    }
}

private struct CurrencyItem: View {
    let emoji: String
    let label: String
    let value: Int

    var body: some View {
        VStack(spacing: 2) {
            Text(emoji)
                .font(.title3)
            Text("\(value)")
                .font(.headline.bold())
                .foregroundStyle(TreeholeTheme.textPrimary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(TreeholeTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Tasks Panel

private struct TasksPanel: View {
    @Environment(\.modelContext) private var modelContext
    let economy: Economy?
    let tasks: [DailyTask]
    let challenges: [WeeklyChallenge]
    let viewModel: EconomyViewModel

    @State private var loginBonusClaimed = false

    private var todayTasks: [DailyTask] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return tasks.filter {
            calendar.isDate(calendar.startOfDay(for: $0.createdAt), inSameDayAs: today)
        }
    }

    private var thisWeekChallenges: [WeeklyChallenge] {
        let calendar = Calendar.current
        let weekStart = calendar.startOfWeek(for: Date())
        return challenges.filter {
            calendar.isDate($0.weekStartDate, inSameDayAs: weekStart)
        }
    }

    private var hasClaimedLoginBonus: Bool {
        guard let eco = economy else { return true }
        guard let lastLogin = eco.lastLoginDate else { return false }
        return Calendar.current.isDateInToday(lastLogin) && loginBonusClaimed
    }

    var body: some View {
        VStack(spacing: TreeholeTheme.spacingMedium) {
            // Login streak card
            if let eco = economy {
                LoginStreakCard(
                    economy: eco,
                    loginBonusClaimed: $loginBonusClaimed,
                    modelContext: modelContext
                )
            }

            // Daily task cards
            VStack(spacing: TreeholeTheme.spacingSmall) {
                ForEach(todayTasks) { task in
                    TaskCard(task: task)
                }

                if todayTasks.isEmpty {
                    EmptyStateView(
                        icon: "checkmark.circle",
                        title: L10n.t("No Tasks Yet", "暂无任务"),
                        message: L10n.t("Tasks will appear here each day", "每日任务将在这里显示")
                    )
                    .glassCard()
                }
            }

            // Reset caption
            Text(L10n.t("Tasks reset daily", "每日任务每天重置"))
                .font(.caption)
                .foregroundStyle(TreeholeTheme.textLight)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, TreeholeTheme.spacingTight)

            // Weekly challenges section
            WeeklyChallengesSection(challenges: thisWeekChallenges)
        }
        .padding(.top, TreeholeTheme.spacingSmall)
    }
}

// MARK: - Calendar extension (view-side)

private extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components) ?? startOfDay(for: date)
    }
}

// MARK: - Weekly Challenges Section

private struct WeeklyChallengesSection: View {
    let challenges: [WeeklyChallenge]

    private var completedCount: Int { challenges.filter { $0.isCompleted }.count }

    var body: some View {
        VStack(spacing: TreeholeTheme.spacingSmall) {
            // Section header
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(TreeholeTheme.warmGold)
                Text(L10n.t("Weekly Challenges", "每周挑战"))
                    .font(.headline)
                    .foregroundStyle(TreeholeTheme.textPrimary)
                Spacer()
                Text("\(completedCount)/\(challenges.count)")
                    .font(.caption.bold())
                    .foregroundStyle(TreeholeTheme.textSecondary)
            }
            .padding(.top, TreeholeTheme.spacingSmall)

            if challenges.isEmpty {
                HStack(spacing: TreeholeTheme.spacingMedium) {
                    Image(systemName: "hourglass")
                        .font(.title2)
                        .foregroundStyle(TreeholeTheme.softPurple.opacity(0.6))
                    Text(L10n.t("Weekly challenges loading…", "每周挑战加载中…"))
                        .font(.subheadline)
                        .foregroundStyle(TreeholeTheme.textSecondary)
                }
                .glassCard()
            } else {
                ForEach(challenges) { challenge in
                    WeeklyChallengeCard(challenge: challenge)
                }
            }

            Text(L10n.t("Challenges reset each Monday", "挑战每周一重置"))
                .font(.caption)
                .foregroundStyle(TreeholeTheme.textLight)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, TreeholeTheme.spacingTight)
        }
    }
}

// MARK: - Weekly Challenge Card

private struct WeeklyChallengeCard: View {
    let challenge: WeeklyChallenge

    private var iconColor: Color {
        switch challenge.type {
        case .postStreak:   return TreeholeTheme.skyBlue
        case .waterStreak:  return TreeholeTheme.mintCream
        case .journalStreak: return TreeholeTheme.gentleLavender
        case .feedStreak:   return TreeholeTheme.warmPeach
        }
    }

    private var title: String {
        L10n.lang == "zh-Hans" ? challenge.type.titleZH : challenge.type.title
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TreeholeTheme.spacingSmall) {
            HStack(spacing: TreeholeTheme.spacingMedium) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: TreeholeTheme.cornerSmall)
                        .fill(iconColor.opacity(0.25))
                        .frame(width: 44, height: 44)
                    Image(systemName: challenge.type.icon)
                        .font(.title3)
                        .foregroundStyle(iconColor)
                }

                // Title and progress text
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundStyle(challenge.isCompleted ? TreeholeTheme.textLight : TreeholeTheme.textPrimary)

                    Text("\(challenge.currentCount)/\(challenge.type.targetCount)")
                        .font(.caption)
                        .foregroundStyle(TreeholeTheme.textSecondary)
                }

                Spacer()

                // Reward or completed badge
                if challenge.isCompleted {
                    VStack(spacing: 2) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.green.opacity(0.8))
                        Text(L10n.t("Done", "完成"))
                            .font(.caption2)
                            .foregroundStyle(TreeholeTheme.textLight)
                    }
                } else {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("+\(challenge.type.foodReward) 🍖")
                            .font(.caption.bold())
                            .foregroundStyle(TreeholeTheme.textSecondary)
                        Text("+\(challenge.type.tokenReward) 🎫")
                            .font(.caption.bold())
                            .foregroundStyle(TreeholeTheme.textSecondary)
                    }
                }
            }

            // Progress bar
            ProgressBar(
                value: challenge.currentCount,
                maxValue: challenge.type.targetCount,
                color: challenge.isCompleted ? Color.green.opacity(0.6) : iconColor
            )
        }
        .padding(TreeholeTheme.spacingMedium)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: TreeholeTheme.cornerLarge))
        .opacity(challenge.isCompleted ? 0.75 : 1.0)
    }
}

// MARK: - Login Streak Card

private struct LoginStreakCard: View {
    let economy: Economy
    @Binding var loginBonusClaimed: Bool
    let modelContext: ModelContext

    private var alreadyClaimed: Bool {
        guard let lastLogin = economy.lastLoginDate else { return false }
        // If last login is today AND we've been through checkLoginStreak, bonus was already given
        // We use loginBonusClaimed local state to track this session's claim
        return loginBonusClaimed
    }

    private var bonusAmount: Int {
        min(25, 5 + economy.loginStreak * 2)
    }

    var body: some View {
        HStack(spacing: TreeholeTheme.spacingMedium) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("🔥")
                        .font(.title2)
                    Text(L10n.t("Day \(economy.loginStreak)", "第 \(economy.loginStreak) 天"))
                        .font(.title3.bold())
                        .foregroundStyle(TreeholeTheme.textPrimary)
                }
                Text(L10n.t("Login Streak", "连续登录"))
                    .font(.caption)
                    .foregroundStyle(TreeholeTheme.textSecondary)
            }

            Spacer()

            if alreadyClaimed {
                Label(L10n.t("Claimed", "已领取"), systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(TreeholeTheme.mintCream)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.25), in: RoundedRectangle(cornerRadius: TreeholeTheme.cornerSmall))
            } else {
                Button {
                    economy.grantLoginBonus()
                    loginBonusClaimed = true
                    try? modelContext.save()
                } label: {
                    Text("+\(bonusAmount) 🍖")
                        .font(.subheadline.bold())
                }
                .buttonStyle(.borderedProminent)
                .tint(TreeholeTheme.warmGold)
            }
        }
        .glassCard()
    }
}

// MARK: - Task Card

private struct TaskCard: View {
    let task: DailyTask

    private var taskIcon: String {
        switch task.type {
        case .post:         return "cloud.fill"
        case .feedPet:      return "cup.and.saucer.fill"
        case .waterPlant:   return "drop.fill"
        case .writeJournal: return "book.fill"
        }
    }

    private var iconColor: Color {
        switch task.type {
        case .post:         return TreeholeTheme.skyBlue
        case .feedPet:      return TreeholeTheme.warmPeach
        case .waterPlant:   return TreeholeTheme.mintCream
        case .writeJournal: return TreeholeTheme.gentleLavender
        }
    }

    var body: some View {
        HStack(spacing: TreeholeTheme.spacingMedium) {
            // Task icon
            ZStack {
                RoundedRectangle(cornerRadius: TreeholeTheme.cornerSmall)
                    .fill(iconColor.opacity(0.3))
                    .frame(width: 44, height: 44)
                Image(systemName: taskIcon)
                    .font(.title3)
                    .foregroundStyle(iconColor)
            }

            // Title and rewards
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(task.isCompleted ? TreeholeTheme.textLight : TreeholeTheme.textPrimary)

                HStack(spacing: 8) {
                    if task.foodReward > 0 {
                        Text("+\(task.foodReward) 🍖")
                            .font(.caption)
                            .foregroundStyle(task.isCompleted ? TreeholeTheme.textLight : TreeholeTheme.textSecondary)
                    }
                    if task.tokenReward > 0 {
                        Text("+\(task.tokenReward) 🎫")
                            .font(.caption)
                            .foregroundStyle(task.isCompleted ? TreeholeTheme.textLight : TreeholeTheme.textSecondary)
                    }
                }
            }

            Spacer()

            // Completion indicator
            if task.isCompleted {
                VStack(spacing: 2) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.green.opacity(0.7))
                    Text(L10n.t("Done", "完成"))
                        .font(.caption2)
                        .foregroundStyle(TreeholeTheme.textLight)
                }
            }
        }
        .padding(TreeholeTheme.spacingMedium)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: TreeholeTheme.cornerLarge))
        .opacity(task.isCompleted ? 0.7 : 1.0)
    }
}

// MARK: - Shop Panel

private struct ShopPanel: View {
    let economy: Economy?
    let modelContext: ModelContext

    var body: some View {
        VStack(spacing: TreeholeTheme.spacingMedium) {
            // Food section header
            HStack {
                Image(systemName: "bag.fill")
                    .foregroundStyle(TreeholeTheme.warmGold)
                Text(L10n.t("Food Packs", "食物礼包"))
                    .font(.headline)
                    .foregroundStyle(TreeholeTheme.textPrimary)
                Spacer()
            }
            .padding(.top, TreeholeTheme.spacingSmall)

            // Food pack cards
            VStack(spacing: TreeholeTheme.spacingSmall) {
                FoodPackCard(
                    name: L10n.t("Small Pack", "小礼包"),
                    emoji: "🍖",
                    foodAmount: 10,
                    tokenCost: 1,
                    economy: economy,
                    modelContext: modelContext
                )
                FoodPackCard(
                    name: L10n.t("Medium Pack", "中礼包"),
                    emoji: "🍗",
                    foodAmount: 25,
                    tokenCost: 2,
                    economy: economy,
                    modelContext: modelContext
                )
                FoodPackCard(
                    name: L10n.t("Large Pack", "大礼包"),
                    emoji: "🥩",
                    foodAmount: 50,
                    tokenCost: 4,
                    economy: economy,
                    modelContext: modelContext
                )
            }

            // Coming soon section
            VStack(spacing: TreeholeTheme.spacingSmall) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(TreeholeTheme.softPurple)
                    Text(L10n.t("More Items", "更多商品"))
                        .font(.headline)
                        .foregroundStyle(TreeholeTheme.textPrimary)
                    Spacer()
                }

                HStack(spacing: TreeholeTheme.spacingMedium) {
                    Image(systemName: "clock.badge.fill")
                        .font(.title2)
                        .foregroundStyle(TreeholeTheme.softPurple.opacity(0.6))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.t("More items coming soon!", "更多商品即将推出！"))
                            .font(.subheadline.bold())
                            .foregroundStyle(TreeholeTheme.textSecondary)
                        Text(L10n.t("Decorations, accessories, and more", "装饰品、配件等"))
                            .font(.caption)
                            .foregroundStyle(TreeholeTheme.textLight)
                    }
                    Spacer()
                }
                .glassCard()
            }
        }
        .padding(.top, TreeholeTheme.spacingSmall)
    }
}

// MARK: - Food Pack Card

private struct FoodPackCard: View {
    let name: String
    let emoji: String
    let foodAmount: Int
    let tokenCost: Int
    let economy: Economy?
    let modelContext: ModelContext

    @State private var purchaseConfirmed = false

    private var canAfford: Bool {
        (economy?.decorationTokens ?? 0) >= tokenCost
    }

    var body: some View {
        HStack(spacing: TreeholeTheme.spacingMedium) {
            // Icon
            Text(emoji)
                .font(.title)
                .frame(width: 48, height: 48)
                .background(TreeholeTheme.warmPeach.opacity(0.25), in: RoundedRectangle(cornerRadius: TreeholeTheme.cornerSmall))

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.subheadline.bold())
                    .foregroundStyle(TreeholeTheme.textPrimary)
                Text("+\(foodAmount) 🍖")
                    .font(.caption)
                    .foregroundStyle(TreeholeTheme.textSecondary)
            }

            Spacer()

            // Buy button
            if purchaseConfirmed {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.green)
                    .transition(.scale.combined(with: .opacity))
            } else {
                Button {
                    guard let eco = economy else { return }
                    if eco.spendTokens(tokenCost) {
                        eco.addFood(foodAmount)
                        try? modelContext.save()
                        withAnimation(.spring(response: 0.3)) {
                            purchaseConfirmed = true
                        }
                        // Reset after brief delay
                        Task { @MainActor in
                            try? await Task.sleep(for: .seconds(1.5))
                            withAnimation {
                                purchaseConfirmed = false
                            }
                        }
                    }
                } label: {
                    Text("\(tokenCost) 🎫")
                        .font(.subheadline.bold())
                }
                .buttonStyle(.borderedProminent)
                .tint(canAfford ? TreeholeTheme.coral : TreeholeTheme.textLight)
                .disabled(!canAfford)
            }
        }
        .glassCard()
        .animation(.spring(response: 0.3), value: purchaseConfirmed)
    }
}
