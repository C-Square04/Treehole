import SwiftUI
import SwiftData

// MARK: - Plant Garden View

struct PlantGardenView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(sort: \Plant.createdAt) private var plants: [Plant]
    @Query private var economies: [Economy]
    @Query private var dailyTasks: [DailyTask]
    @Query private var weeklyChallenges: [WeeklyChallenge]

    @State private var selectedPlantID: String?
    @State private var showAddSheet = false
    @State private var showWateringAnimation = false
    @State private var feedbackText: String?
    @State private var plantToDelete: Plant?
    @State private var showDeleteConfirm = false
    @State private var economyVM = EconomyViewModel()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let maxPlants = 5

    private var selectedPlant: Plant? {
        if let id = selectedPlantID, let match = plants.first(where: { $0.id == id }) {
            return match
        }
        return plants.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                TreeholeTheme.gardenBackground.ignoresSafeArea()

                if plants.isEmpty {
                    emptyStateContent
                } else {
                    ScrollView {
                        VStack(spacing: TreeholeTheme.spacingLarge) {
                            plantSelectorSection
                            if let plant = selectedPlant {
                                plantDetailSection(plant: plant)
                            }
                        }
                        .padding(.bottom, TreeholeTheme.spacingXL)
                    }
                }
            }
            .navigationTitle(L10n.t("Garden", "花园"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(plants.count >= maxPlants
                                ? TreeholeTheme.textSecondary
                                : TreeholeTheme.mintCream)
                            .font(.title3)
                    }
                    .disabled(plants.count >= maxPlants)
                    .accessibilityLabel(L10n.t("Add plant", "添加植物"))
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddPlantSheet { name, species in
                    let newPlant = Plant(name: name, species: species)
                    modelContext.insert(newPlant)
                    try? modelContext.save()
                    selectedPlantID = newPlant.id
                }
            }
            .confirmationDialog(
                L10n.t("Remove Plant", "移除植物"),
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button(L10n.t("Delete", "删除"), role: .destructive) {
                    if let plant = plantToDelete {
                        deletePlant(plant)
                    }
                }
                Button(L10n.t("Cancel", "取消"), role: .cancel) {}
            } message: {
                if let plant = plantToDelete {
                    Text(L10n.t(
                        "Are you sure you want to remove \"\(plant.name)\"? This cannot be undone.",
                        "确定要移除「\(plant.name)」吗？此操作无法撤销。"
                    ))
                }
            }
            .onAppear {
                plants.forEach { $0.updateHydration() }
                _ = economyVM.ensureEconomyExists(context: modelContext, economies: economies)
                try? modelContext.save()
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateContent: some View {
        VStack {
            Spacer()
            EmptyStateView(
                icon: "leaf.fill",
                title: L10n.t("No Plants Yet", "还没有植物"),
                message: L10n.t("Plant your first seed and watch it grow!", "种下你的第一颗种子吧！"),
                actionLabel: L10n.t("Plant a Seed", "播种")
            ) {
                showAddSheet = true
            }
            Spacer()
        }
    }

    // MARK: - Plant Selector

    private var plantSelectorSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: TreeholeTheme.spacingSmall) {
                ForEach(plants) { plant in
                    PlantThumbnailButton(
                        plant: plant,
                        isSelected: plant.id == (selectedPlant?.id ?? plants.first?.id)
                    ) {
                        if reduceMotion {
                            selectedPlantID = plant.id
                        } else {
                            withAnimation(.spring(response: 0.3)) {
                                selectedPlantID = plant.id
                            }
                        }
                    } onDelete: {
                        plantToDelete = plant
                        showDeleteConfirm = true
                    }
                }

                if plants.count < maxPlants {
                    Button {
                        showAddSheet = true
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(TreeholeTheme.mintCream.opacity(0.4))
                                    .frame(width: 52, height: 52)
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .foregroundStyle(TreeholeTheme.textSecondary)
                            }
                            Text(L10n.t("Add", "添加"))
                                .font(.caption2)
                                .foregroundStyle(TreeholeTheme.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, TreeholeTheme.spacingMedium)
            .padding(.vertical, TreeholeTheme.spacingSmall)
        }
    }

    // MARK: - Plant Detail

    @ViewBuilder
    private func plantDetailSection(plant: Plant) -> some View {
        let lang = appState.preferredLanguage

        // Plant visual
        PlantVisualView(
            growthStage: plant.growthStage,
            hydrationLevel: plant.hydrationLevel,
            experience: plant.experience
        )
        .frame(height: 280)
        .overlay(alignment: .top) {
            if let text = feedbackText {
                Text(text)
                    .font(.caption.bold())
                    .foregroundStyle(TreeholeTheme.skyBlue)
                    .padding(.horizontal, TreeholeTheme.spacingSmall)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.horizontal)

        // Species & name
        VStack(spacing: 4) {
            Text("\(plant.species.emoji) \(plant.name)")
                .font(.title2.bold())
                .foregroundStyle(TreeholeTheme.textPrimary)
            Text("\(L10n.t("Growing Stage:", "生长阶段：")) \(lang == "zh-Hans" ? plant.growthStage.labelZH : plant.growthStage.labelEN)")
                .font(.subheadline)
                .foregroundStyle(TreeholeTheme.textSecondary)
        }

        // Growth progress card
        VStack(spacing: TreeholeTheme.spacingSmall) {
            StatBadge(
                label: L10n.t("Growth Stage", "生长阶段"),
                value: "\(plant.growthStage.icon) \(lang == "zh-Hans" ? plant.growthStage.labelZH : plant.growthStage.labelEN) (\(plant.experience)/100 XP)",
                icon: "chart.bar.fill",
                color: TreeholeTheme.mintCream
            )
            ProgressBar(value: plant.experience, maxValue: 100, color: TreeholeTheme.mintCream)
            HStack(spacing: 6) {
                ForEach(GrowthStage.allCases, id: \.rawValue) { stage in
                    Circle()
                        .fill(stage.stageIndex <= plant.growthStage.stageIndex
                            ? TreeholeTheme.mintCream
                            : TreeholeTheme.mintCream.opacity(0.3))
                        .frame(width: 10, height: 10)
                }
            }
        }
        .glassCard()
        .padding(.horizontal)

        // Hydration card
        VStack(spacing: TreeholeTheme.spacingSmall) {
            StatBadge(
                label: L10n.t("Hydration", "水分"),
                value: "\(plant.hydrationLevel)% - \(hydrationDescription(plant: plant, lang: lang))",
                icon: "drop.fill",
                color: TreeholeTheme.skyBlue
            )
            ProgressBar(value: plant.hydrationLevel, maxValue: 100, color: TreeholeTheme.skyBlue)
        }
        .glassCard()
        .padding(.horizontal)

        // Water button
        Button {
            plant.water()
            let economy = economyVM.ensureEconomyExists(context: modelContext, economies: economies)
            economy.addFood(3)
            if let task = dailyTasks.first(where: { $0.type == .waterPlant && !$0.isCompleted }) {
                economyVM.completeTask(task, economy: economy)
            }
            economyVM.incrementChallenge(type: .waterStreak, economy: economy, challenges: weeklyChallenges)
            try? modelContext.save()
            AnalyticsService.track("plant_watered")
            NotificationService.scheduleWateringReminder()
            showFeedback(L10n.t("+40 Hydration, +5 XP, +3 🍖", "+40 水分, +5 经验, +3 🍖"))
        } label: {
            Label(L10n.t("Water Plant", "浇水"), systemImage: "drop.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, TreeholeTheme.spacingSmall)
        }
        .buttonStyle(.borderedProminent)
        .tint(TreeholeTheme.skyBlue)
        .disabled(plant.hydrationLevel >= 100)
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private func hydrationDescription(plant: Plant, lang: String) -> String {
        if lang == "zh-Hans" {
            switch plant.hydrationLevel {
            case 75...100: return "充足"
            case 50..<75: return "适中"
            case 25..<50: return "干燥"
            default: return "极度干旱"
            }
        } else {
            return plant.hydrationDescription
        }
    }

    private func deletePlant(_ plant: Plant) {
        let wasSelected = plant.id == selectedPlantID
        modelContext.delete(plant)
        if wasSelected {
            selectedPlantID = plants.first(where: { $0.id != plant.id })?.id
        }
    }

    private func showFeedback(_ text: String) {
        // Reduce Motion: swap the spring/move transition for a plain state change
        if reduceMotion {
            feedbackText = text
        } else {
            withAnimation(.spring(response: 0.3)) {
                feedbackText = text
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if reduceMotion {
                feedbackText = nil
            } else {
                withAnimation { feedbackText = nil }
            }
        }
    }
}

// MARK: - Plant Thumbnail Button

private struct PlantThumbnailButton: View {
    let plant: Plant
    let isSelected: Bool
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isSelected
                            ? TreeholeTheme.mintCream.opacity(0.7)
                            : TreeholeTheme.mintCream.opacity(0.25))
                        .frame(width: 52, height: 52)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    isSelected ? TreeholeTheme.mintCream : Color.clear,
                                    lineWidth: 2
                                )
                        )
                    Text(plant.species.emoji)
                        .font(.title2)
                }
                Text(plant.name)
                    .font(.caption2)
                    .foregroundStyle(isSelected
                        ? TreeholeTheme.textPrimary
                        : TreeholeTheme.textSecondary)
                    .lineLimit(1)
                    .frame(maxWidth: 60)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(plant.name)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label(L10n.t("Remove Plant", "移除植物"), systemImage: "trash")
            }
        }
    }
}

// MARK: - Add Plant Sheet

private struct AddPlantSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    var onAdd: (String, PlantSpecies) -> Void

    @State private var selectedSpecies: PlantSpecies = .sunflower
    @State private var plantName: String = PlantSpecies.sunflower.labelEN

    var body: some View {
        let lang = appState.preferredLanguage

        NavigationStack {
            ZStack {
                TreeholeTheme.gardenBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: TreeholeTheme.spacingLarge) {
                        // Species picker
                        VStack(alignment: .leading, spacing: TreeholeTheme.spacingSmall) {
                            Text(L10n.t("Choose a Species", "选择品种"))
                                .font(.headline)
                                .foregroundStyle(TreeholeTheme.textPrimary)
                                .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: TreeholeTheme.spacingSmall) {
                                    ForEach(PlantSpecies.allCases) { species in
                                        Button {
                                            selectedSpecies = species
                                            let allLabels = PlantSpecies.allCases.flatMap { [$0.labelEN, $0.labelZH] }
                                            if plantName.isEmpty || allLabels.contains(plantName) {
                                                plantName = lang == "zh-Hans" ? species.labelZH : species.labelEN
                                            }
                                        } label: {
                                            VStack(spacing: 8) {
                                                ZStack {
                                                    Circle()
                                                        .fill(selectedSpecies == species
                                                            ? TreeholeTheme.mintCream.opacity(0.8)
                                                            : TreeholeTheme.mintCream.opacity(0.25))
                                                        .frame(width: 60, height: 60)
                                                        .overlay(
                                                            Circle()
                                                                .strokeBorder(
                                                                    selectedSpecies == species
                                                                        ? TreeholeTheme.mintCream
                                                                        : Color.clear,
                                                                    lineWidth: 2
                                                                )
                                                        )
                                                    Text(species.emoji)
                                                        .font(.largeTitle)
                                                }
                                                Text(lang == "zh-Hans" ? species.labelZH : species.labelEN)
                                                    .font(.caption)
                                                    .foregroundStyle(selectedSpecies == species
                                                        ? TreeholeTheme.textPrimary
                                                        : TreeholeTheme.textSecondary)
                                            }
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityLabel(lang == "zh-Hans" ? species.labelZH : species.labelEN)
                                        .accessibilityAddTraits(selectedSpecies == species ? [.isSelected] : [])
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }

                        // Name field
                        VStack(alignment: .leading, spacing: TreeholeTheme.spacingSmall) {
                            Text(L10n.t("Plant Name", "植物名称"))
                                .font(.headline)
                                .foregroundStyle(TreeholeTheme.textPrimary)
                            TextField(L10n.t("Enter a name", "输入名称"), text: $plantName)
                                .textFieldStyle(.roundedBorder)
                                .padding(.vertical, 4)
                        }
                        .padding(.horizontal)

                        // Preview
                        VStack(spacing: 8) {
                            Text(selectedSpecies.emoji)
                                .font(.system(size: 64))
                            Text(plantName.isEmpty ? (lang == "zh-Hans" ? selectedSpecies.labelZH : selectedSpecies.labelEN) : plantName)
                                .font(.title3.bold())
                                .foregroundStyle(TreeholeTheme.textPrimary)
                            Text(L10n.t("Starting as a Seed", "从种子开始"))
                                .font(.caption)
                                .foregroundStyle(TreeholeTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(TreeholeTheme.spacingLarge)
                        .glassCard()
                        .padding(.horizontal)

                        // Plant button
                        Button {
                            let finalName = plantName.trimmingCharacters(in: .whitespaces)
                            onAdd(finalName.isEmpty ? (lang == "zh-Hans" ? selectedSpecies.labelZH : selectedSpecies.labelEN) : finalName, selectedSpecies)
                            dismiss()
                        } label: {
                            Label(L10n.t("Plant Seed", "播种"), systemImage: "leaf.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, TreeholeTheme.spacingSmall)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(TreeholeTheme.mintCream)
                        .padding(.horizontal)
                    }
                    .padding(.vertical, TreeholeTheme.spacingLarge)
                }
            }
            .navigationTitle(L10n.t("New Plant", "新植物"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.t("Cancel", "取消")) { dismiss() }
                }
            }
        }
    }
}
