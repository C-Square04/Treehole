import SwiftUI
import SwiftData

// MARK: - ShopView

struct ShopView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var economies: [Economy]
    @Query private var dailyTasks: [DailyTask]
    @State private var viewModel = EconomyViewModel()
    @State private var selectedTab: ShopTab = .tasks

    enum ShopTab: String, CaseIterable {
        case tasks = "Tasks"
        case shop  = "Shop"
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
                    Picker("Section", selection: $selectedTab) {
                        ForEach(ShopTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, TreeholeTheme.spacingMedium)
                    .padding(.vertical, TreeholeTheme.spacingSmall)

                    // Tab content
                    ScrollView {
                        switch selectedTab {
                        case .tasks:
                            TasksPanel(economy: economy, tasks: dailyTasks, viewModel: viewModel)
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
            .navigationTitle("Shop & Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(TreeholeTheme.softPurple)
                    }
                }
            }
        }
        .onAppear {
            let eco = viewModel.ensureEconomyExists(context: modelContext, economies: economies)
            eco.checkLoginStreak()
            viewModel.resetDailyTasksIfNeeded(tasks: dailyTasks, context: modelContext)
            viewModel.createDailyTasks(context: modelContext, existingTasks: dailyTasks)
            try? modelContext.save()
        }
    }
}

// MARK: - Currency Bar

private struct CurrencyBar: View {
    let economy: Economy

    var body: some View {
        HStack(spacing: 0) {
            CurrencyItem(emoji: "🍖", label: "Food", value: economy.food)
            Divider().frame(height: 30)
            CurrencyItem(emoji: "🎫", label: "Tokens", value: economy.decorationTokens)
            Divider().frame(height: 30)
            CurrencyItem(emoji: "💎", label: "Gems", value: economy.gems)
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
    let viewModel: EconomyViewModel

    @State private var loginBonusClaimed = false

    private var todayTasks: [DailyTask] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return tasks.filter {
            calendar.isDate(calendar.startOfDay(for: $0.createdAt), inSameDayAs: today)
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

            // Task cards
            VStack(spacing: TreeholeTheme.spacingSmall) {
                ForEach(todayTasks) { task in
                    TaskCard(task: task)
                }

                if todayTasks.isEmpty {
                    EmptyStateView(
                        icon: "checkmark.circle",
                        title: "No Tasks Yet",
                        message: "Tasks will appear here each day"
                    )
                    .glassCard()
                }
            }

            // Reset caption
            Text("Tasks reset daily")
                .font(.caption)
                .foregroundStyle(TreeholeTheme.textLight)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, TreeholeTheme.spacingTight)
        }
        .padding(.top, TreeholeTheme.spacingSmall)
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
                    Text("Day \(economy.loginStreak)")
                        .font(.title3.bold())
                        .foregroundStyle(TreeholeTheme.textPrimary)
                }
                Text("Login Streak")
                    .font(.caption)
                    .foregroundStyle(TreeholeTheme.textSecondary)
            }

            Spacer()

            if alreadyClaimed {
                Label("Claimed", systemImage: "checkmark.circle.fill")
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
                    Text("Done")
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
                Text("Food Packs")
                    .font(.headline)
                    .foregroundStyle(TreeholeTheme.textPrimary)
                Spacer()
            }
            .padding(.top, TreeholeTheme.spacingSmall)

            // Food pack cards
            VStack(spacing: TreeholeTheme.spacingSmall) {
                FoodPackCard(
                    name: "Small Pack",
                    emoji: "🍖",
                    foodAmount: 10,
                    tokenCost: 1,
                    economy: economy,
                    modelContext: modelContext
                )
                FoodPackCard(
                    name: "Medium Pack",
                    emoji: "🍗",
                    foodAmount: 25,
                    tokenCost: 2,
                    economy: economy,
                    modelContext: modelContext
                )
                FoodPackCard(
                    name: "Large Pack",
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
                    Text("More Items")
                        .font(.headline)
                        .foregroundStyle(TreeholeTheme.textPrimary)
                    Spacer()
                }

                HStack(spacing: TreeholeTheme.spacingMedium) {
                    Image(systemName: "clock.badge.fill")
                        .font(.title2)
                        .foregroundStyle(TreeholeTheme.softPurple.opacity(0.6))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("More items coming soon!")
                            .font(.subheadline.bold())
                            .foregroundStyle(TreeholeTheme.textSecondary)
                        Text("Decorations, accessories, and more")
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
