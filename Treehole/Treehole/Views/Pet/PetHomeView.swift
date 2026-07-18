import SwiftUI
import SwiftData

struct PetHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query private var pets: [Pet]
    @Query private var economies: [Economy]
    @Query private var dailyTasks: [DailyTask]
    @Query private var weeklyChallenges: [WeeklyChallenge]
    @State private var viewModel = PetViewModel()
    @State private var economyVM = EconomyViewModel()
    @State private var feedbackText: String?
    @State private var showInsufficientFood = false
    @State private var showChat = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack {
            if let pet = pets.first {
                petContentView(pet: pet)
            } else {
                ProgressView(L10n.t("Loading...", "加载中..."))
                    .onAppear { createPetIfNeeded() }
            }
        }
    }

    private func createPetIfNeeded() {
        guard pets.isEmpty else { return }
        let newPet = Pet(name: "Companion")
        modelContext.insert(newPet)
        try? modelContext.save()
    }

    @ViewBuilder
    private func petContentView(pet: Pet) -> some View {
        let themeColors = pet.homeTheme.gradient
        let lang = appState.preferredLanguage

        ZStack {
            LinearGradient(colors: [themeColors.0, themeColors.1], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: TreeholeTheme.spacingLarge) {
                    CartoonCatView(mood: pet.mood, showFeedingAnimation: viewModel.showFeedingAnimation)
                        .frame(height: 280)
                        .overlay(alignment: .top) {
                            if let text = feedbackText {
                                Text(text)
                                    .font(.caption.bold())
                                    .foregroundStyle(showInsufficientFood ? TreeholeTheme.coral : TreeholeTheme.warmGold)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                                    .offset(y: -10)
                            }
                        }

                    VStack(spacing: 4) {
                        Text(pet.name)
                            .font(.title2.bold())
                            .foregroundStyle(pet.homeTheme.textColor)
                        Text("\(pet.mood.emoji) \(lang == "zh-Hans" ? pet.mood.labelZH : pet.mood.labelEN)")
                            .font(.subheadline)
                            .foregroundStyle(pet.homeTheme.secondaryTextColor)
                    }

                    VStack(spacing: TreeholeTheme.spacingSmall) {
                        StatBadge(label: L10n.t("Hunger", "饥饿度"), value: "\(pet.hungerLevel)/100 - \(hungerDescription(pet: pet, lang: lang))", icon: "fork.knife", color: TreeholeTheme.coral)
                        ProgressBar(value: pet.hungerLevel, maxValue: 100, color: TreeholeTheme.coral)

                        StatBadge(label: L10n.t("Energy", "能量"), value: "\(pet.energy)/100", icon: "bolt.fill", color: TreeholeTheme.skyBlue)
                        ProgressBar(value: pet.energy, maxValue: 100, color: TreeholeTheme.skyBlue)

                        StatBadge(label: L10n.t("Level", "等级"), value: "Lv.\(pet.level) • \(pet.experience)/\(pet.nextLevelExp) XP", icon: "star.fill", color: TreeholeTheme.warmGold)
                        ProgressBar(value: pet.experience, maxValue: pet.nextLevelExp, color: TreeholeTheme.warmGold)
                    }
                    .glassCard()

                    // Chat button
                    Button {
                        showChat = true
                    } label: {
                        Label(L10n.t("Chat", "聊天"), systemImage: "bubble.left.and.bubble.right.fill")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, TreeholeTheme.spacingSmall)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(TreeholeTheme.warmGold)
                    .foregroundStyle(TreeholeTheme.buttonText)
                    .padding(.horizontal)

                    // Action buttons
                    HStack(spacing: TreeholeTheme.spacingSmall) {
                        Button {
                            let economy = economyVM.ensureEconomyExists(context: modelContext, economies: economies)
                            if economy.spendFood(5) {
                                pet.feed()
                                viewModel.showFeedingAnimation = true
                                showInsufficientFood = false
                                showFeedback(L10n.t("+30 Hunger, +10 XP", "+30 饥饿度, +10 经验"))
                                if let task = dailyTasks.first(where: { $0.type == .feedPet && !$0.isCompleted }) {
                                    economyVM.completeTask(task, economy: economy)
                                }
                                economyVM.incrementChallenge(type: .feedStreak, economy: economy, challenges: weeklyChallenges)
                                try? modelContext.save()
                                AnalyticsService.track("pet_fed")
                                NotificationService.scheduleFeedingReminder()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                    viewModel.showFeedingAnimation = false
                                }
                            } else {
                                showInsufficientFood = true
                                showFeedback(L10n.t("Not enough food!", "食物不足！"))
                            }
                        } label: {
                            VStack(spacing: 2) {
                                Label(L10n.t("Feed (5 🍖)", "喂食 (5 🍖)"), systemImage: "cup.and.saucer.fill")
                                    .font(.subheadline.bold())
                                if let economy = economies.first {
                                    Text("🍖 \(economy.food)")
                                        .font(.caption2)
                                        .foregroundStyle(TreeholeTheme.buttonText.opacity(0.75))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, TreeholeTheme.spacingSmall)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(TreeholeTheme.coral)
                        .foregroundStyle(TreeholeTheme.buttonText)
                        .disabled(pet.hungerLevel >= 100)

                        Button {
                            pet.pet()
                            showFeedback(L10n.t("+10 Energy", "+10 能量"))
                            try? modelContext.save()
                        } label: {
                            Label(L10n.t("Pet", "抚摸"), systemImage: "hand.raised.fill")
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, TreeholeTheme.spacingSmall)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(TreeholeTheme.softPurple)
                        .foregroundStyle(TreeholeTheme.buttonText)
                        .disabled(pet.energy >= 100)

                        Button {
                            pet.rest()
                            showFeedback(L10n.t("+40 Energy", "+40 能量"))
                            try? modelContext.save()
                        } label: {
                            Label(L10n.t("Rest", "休息"), systemImage: "moon.fill")
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, TreeholeTheme.spacingSmall)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(TreeholeTheme.skyBlue)
                        .foregroundStyle(TreeholeTheme.buttonText)
                        .disabled(pet.energy >= 100)
                    }
                    .padding(.horizontal)

                    // Theme picker
                    VStack(alignment: .leading, spacing: TreeholeTheme.spacingSmall) {
                        Text(L10n.t("Home Theme", "主题"))
                            .font(.caption)
                            .foregroundStyle(pet.homeTheme.secondaryTextColor)
                            .padding(.horizontal, 4)

                        HStack(spacing: TreeholeTheme.spacingSmall) {
                            ForEach(HomeTheme.allCases, id: \.rawValue) { theme in
                                Button {
                                    pet.homeTheme = theme
                                } label: {
                                    VStack(spacing: 4) {
                                        Circle()
                                            .fill(theme.gradient.0)
                                            .frame(width: 28, height: 28)
                                            .overlay {
                                                if pet.homeTheme == theme {
                                                    Circle().strokeBorder(TreeholeTheme.textPrimary, lineWidth: 2)
                                                }
                                            }
                                        Text(lang == "zh-Hans" ? theme.labelZH : theme.labelEN)
                                            .font(.caption2)
                                            .foregroundStyle(pet.homeTheme == theme ? TreeholeTheme.textPrimary : TreeholeTheme.textSecondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(lang == "zh-Hans" ? theme.labelZH : theme.labelEN)
                                .accessibilityAddTraits(pet.homeTheme == theme ? [.isSelected] : [])
                            }
                        }
                    }
                    .glassCard()
                }
                .padding()
            }
        }
        .navigationTitle(L10n.t("Pet", "宠物"))
        .sheet(isPresented: $showChat) {
            PetChatView()
        }
        .onAppear {
            pet.updateHunger()
            let economy = economyVM.ensureEconomyExists(context: modelContext, economies: economies)
            economyVM.resetDailyTasksIfNeeded(tasks: dailyTasks, context: modelContext)
            economyVM.createDailyTasks(context: modelContext, existingTasks: dailyTasks)
            appState.grantSubscriberDailyBonus(economy: economy)
            try? modelContext.save()
        }
    }

    private func hungerDescription(pet: Pet, lang: String) -> String {
        switch pet.hungerLevel {
        case 75...100: return L10n.t("Satisfied", "满足")
        case 50..<75: return L10n.t("Content", "还好")
        case 25..<50: return L10n.t("Hungry", "饥饿")
        default: return L10n.t("Starving", "极度饥饿")
        }
    }

    private func showFeedback(_ text: String) {
        // Reduce Motion: swap the spring/move transition for a plain state change
        if reduceMotion {
            feedbackText = text
        } else {
            withAnimation(.spring(response: 0.3)) { feedbackText = text }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if reduceMotion {
                feedbackText = nil; showInsufficientFood = false
            } else {
                withAnimation { feedbackText = nil; showInsufficientFood = false }
            }
        }
    }
}
