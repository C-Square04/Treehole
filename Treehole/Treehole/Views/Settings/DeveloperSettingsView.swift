import SwiftUI
import SwiftData

struct DeveloperSettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @Query private var pets: [Pet]
    @Query private var plants: [Plant]
    @Query private var economies: [Economy]
    @Query private var journalEntries: [JournalEntry]
    @Query private var dailyTasks: [DailyTask]

    // Pet control state
    @State private var petHunger: Double = 50
    @State private var petEnergy: Double = 50
    @State private var petLevel: Int = 1
    @State private var petXP: Int = 0

    // Plant control state
    @State private var plantHydration: Double = 50
    @State private var plantStage: GrowthStage = .seed
    @State private var plantXP: Int = 0

    // Economy control state
    @State private var foodAmount: Int = 50
    @State private var tokensAmount: Int = 10
    @State private var gemsAmount: Int = 0
    @State private var streakAmount: Int = 0

    // Alert state
    @State private var showResetConfirmation: Bool = false

    private var currentPet: Pet? { pets.first }
    private var currentPlant: Plant? { plants.first }
    private var currentEconomy: Economy? { economies.first }

    private var totalEntryCount: Int {
        pets.count + plants.count + economies.count + journalEntries.count + dailyTasks.count
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    var body: some View {
        List {
            // MARK: - Pet Controls
            Section(L10n.t("Pet Controls", "宠物控制")) {
                if let pet = currentPet {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(L10n.t("Hunger", "饥饿"))
                            Spacer()
                            Text("\(Int(petHunger))/100")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: $petHunger, in: 0...100, step: 1)
                            .tint(.orange)
                            .accessibilityLabel(L10n.t("Hunger", "饥饿"))
                            .onChange(of: petHunger) { _, newValue in
                                pet.hungerLevel = Int(newValue)
                                trySave()
                            }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(L10n.t("Energy", "能量"))
                            Spacer()
                            Text("\(Int(petEnergy))/100")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: $petEnergy, in: 0...100, step: 1)
                            .tint(.blue)
                            .accessibilityLabel(L10n.t("Energy", "能量"))
                            .onChange(of: petEnergy) { _, newValue in
                                pet.energy = Int(newValue)
                                trySave()
                            }
                    }

                    Stepper(
                        L10n.t("Level: \(petLevel)", "等级：\(petLevel)"),
                        value: $petLevel,
                        in: 1...100
                    )
                    .onChange(of: petLevel) { _, newValue in
                        pet.level = newValue
                        trySave()
                    }

                    Stepper(
                        L10n.t("XP: \(petXP)", "经验值：\(petXP)"),
                        value: $petXP,
                        in: 0...9999,
                        step: 5
                    )
                    .onChange(of: petXP) { _, newValue in
                        pet.experience = newValue
                        trySave()
                    }
                } else {
                    Text(L10n.t("No pet found", "未找到宠物"))
                        .foregroundStyle(.secondary)
                }
            }

            // MARK: - Plant Controls
            Section(L10n.t("Plant Controls", "植物控制")) {
                if let plant = currentPlant {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(L10n.t("Hydration", "水分"))
                            Spacer()
                            Text("\(Int(plantHydration))/100")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: $plantHydration, in: 0...100, step: 1)
                            .tint(.cyan)
                            .accessibilityLabel(L10n.t("Hydration", "水分"))
                            .onChange(of: plantHydration) { _, newValue in
                                plant.hydrationLevel = Int(newValue)
                                trySave()
                            }
                    }

                    Picker(L10n.t("Stage", "阶段"), selection: $plantStage) {
                        ForEach(GrowthStage.allCases, id: \.self) { stage in
                            Text("\(stage.icon) \(L10n.t(stage.labelEN, stage.labelZH))")
                                .tag(stage)
                        }
                    }
                    .onChange(of: plantStage) { _, newValue in
                        plant.growthStage = newValue
                        trySave()
                    }

                    Stepper(
                        L10n.t("XP: \(plantXP)", "经验值：\(plantXP)"),
                        value: $plantXP,
                        in: 0...99,
                        step: 5
                    )
                    .onChange(of: plantXP) { _, newValue in
                        plant.experience = newValue
                        trySave()
                    }
                } else {
                    Text(L10n.t("No plant found", "未找到植物"))
                        .foregroundStyle(.secondary)
                }
            }

            // MARK: - Economy Controls
            Section(L10n.t("Economy Controls", "经济控制")) {
                if let economy = currentEconomy {
                    Stepper(
                        L10n.t("Food: \(foodAmount)", "食物：\(foodAmount)"),
                        value: $foodAmount,
                        in: 0...9999,
                        step: 10
                    )
                    .onChange(of: foodAmount) { _, newValue in
                        economy.food = newValue
                        trySave()
                    }

                    Stepper(
                        L10n.t("Tokens: \(tokensAmount)", "代币：\(tokensAmount)"),
                        value: $tokensAmount,
                        in: 0...9999,
                        step: 5
                    )
                    .onChange(of: tokensAmount) { _, newValue in
                        economy.decorationTokens = newValue
                        trySave()
                    }

                    Stepper(
                        L10n.t("Gems: \(gemsAmount)", "宝石：\(gemsAmount)"),
                        value: $gemsAmount,
                        in: 0...9999
                    )
                    .onChange(of: gemsAmount) { _, newValue in
                        economy.gems = newValue
                        trySave()
                    }

                    Stepper(
                        L10n.t("Streak: \(streakAmount)", "连续登录：\(streakAmount)"),
                        value: $streakAmount,
                        in: 0...365
                    )
                    .onChange(of: streakAmount) { _, newValue in
                        economy.loginStreak = newValue
                        trySave()
                    }
                } else {
                    Text(L10n.t("No economy found", "未找到经济数据"))
                        .foregroundStyle(.secondary)
                }
            }

            // MARK: - Quick Actions
            Section(L10n.t("Quick Actions", "快速操作")) {
                Button {
                    maxOutPet()
                } label: {
                    Label(L10n.t("Max Out Pet", "宠物满状态"), systemImage: "heart.fill")
                        .foregroundStyle(.green)
                }

                Button {
                    growPlantToMature()
                } label: {
                    Label(L10n.t("Grow Plant to Mature", "植物长到成熟"), systemImage: "leaf.fill")
                        .foregroundStyle(.green)
                }

                Button {
                    grant100Food()
                } label: {
                    Label(L10n.t("Grant 100 Food", "获得100食物"), systemImage: "fork.knife")
                        .foregroundStyle(.orange)
                }

                Button(role: .destructive) {
                    showResetConfirmation = true
                } label: {
                    Label(L10n.t("Reset All Data", "重置所有数据"), systemImage: "trash.fill")
                }
            }

            // MARK: - Debug Info
            Section(L10n.t("Debug Info", "调试信息")) {
                HStack {
                    Text(L10n.t("Device ID", "设备 ID"))
                    Spacer()
                    Text(SupabaseConfig.deviceId.prefix(18) + "...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack {
                    Text(L10n.t("SwiftData Entries", "SwiftData 条目"))
                    Spacer()
                    Text("\(totalEntryCount)")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                HStack {
                    Text(L10n.t("App Version", "应用版本"))
                    Spacer()
                    Text(appVersion)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(L10n.t("Developer Settings", "开发者设置"))
        .onAppear {
            syncStateFromModels()
        }
        .confirmationDialog(
            L10n.t("Reset All Data?", "重置所有数据？"),
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.t("Reset All Data", "重置所有数据"), role: .destructive) {
                resetAllData()
            }
            Button(L10n.t("Cancel", "取消"), role: .cancel) {}
        } message: {
            Text(L10n.t(
                "This will delete all SwiftData entries and clear UserDefaults. This cannot be undone.",
                "这将删除所有 SwiftData 条目并清除 UserDefaults。此操作无法撤销。"
            ))
        }
    }

    // MARK: - Helpers

    private func syncStateFromModels() {
        if let pet = currentPet {
            petHunger = Double(pet.hungerLevel)
            petEnergy = Double(pet.energy)
            petLevel = pet.level
            petXP = pet.experience
        }
        if let plant = currentPlant {
            plantHydration = Double(plant.hydrationLevel)
            plantStage = plant.growthStage
            plantXP = plant.experience
        }
        if let economy = currentEconomy {
            foodAmount = economy.food
            tokensAmount = economy.decorationTokens
            gemsAmount = economy.gems
            streakAmount = economy.loginStreak
        }
    }

    private func trySave() {
        try? modelContext.save()
    }

    private func maxOutPet() {
        guard let pet = currentPet else { return }
        pet.hungerLevel = 100
        pet.energy = 100
        petHunger = 100
        petEnergy = 100
        trySave()
    }

    private func growPlantToMature() {
        guard let plant = currentPlant else { return }
        plant.growthStage = .mature
        plant.experience = 0
        plantStage = .mature
        plantXP = 0
        trySave()
    }

    private func grant100Food() {
        guard let economy = currentEconomy else { return }
        economy.addFood(100)
        foodAmount = economy.food
        trySave()
    }

    private func resetAllData() {
        // Delete all SwiftData entries
        for pet in pets { modelContext.delete(pet) }
        for plant in plants { modelContext.delete(plant) }
        for economy in economies { modelContext.delete(economy) }
        for entry in journalEntries { modelContext.delete(entry) }
        for task in dailyTasks { modelContext.delete(task) }
        trySave()

        // Clear UserDefaults
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
    }
}
