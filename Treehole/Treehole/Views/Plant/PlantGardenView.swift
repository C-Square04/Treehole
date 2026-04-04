import SwiftUI
import SwiftData

// MARK: - Plant Garden View

struct PlantGardenView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Plant.createdAt) private var plants: [Plant]

    @State private var selectedPlantID: String?
    @State private var showAddSheet = false
    @State private var showWateringAnimation = false
    @State private var feedbackText: String?
    @State private var plantToDelete: Plant?
    @State private var showDeleteConfirm = false

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
            .navigationTitle("Garden")
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
                "Remove Plant",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let plant = plantToDelete {
                        deletePlant(plant)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                if let plant = plantToDelete {
                    Text("Are you sure you want to remove \"\(plant.name)\"? This cannot be undone.")
                }
            }
            .onAppear {
                plants.forEach { $0.updateHydration() }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateContent: some View {
        VStack {
            Spacer()
            EmptyStateView(
                icon: "leaf.fill",
                title: "No Plants Yet",
                message: "Plant your first seed and watch it grow!",
                actionLabel: "Plant a Seed"
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
                        withAnimation(.spring(response: 0.3)) {
                            selectedPlantID = plant.id
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
                            Text("Add")
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
            Text("Growing Stage: \(plant.growthStage.labelEN)")
                .font(.subheadline)
                .foregroundStyle(TreeholeTheme.textSecondary)
        }

        // Growth progress card
        VStack(spacing: TreeholeTheme.spacingSmall) {
            StatBadge(
                label: "Growth Stage",
                value: "\(plant.growthStage.icon) \(plant.growthStage.labelEN) (\(plant.experience)/100 XP)",
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
                label: "Hydration",
                value: "\(plant.hydrationLevel)% - \(plant.hydrationDescription)",
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
            showFeedback("+40 Hydration, +5 XP")
        } label: {
            Label("Water Plant", systemImage: "drop.fill")
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

    private func deletePlant(_ plant: Plant) {
        let wasSelected = plant.id == selectedPlantID
        modelContext.delete(plant)
        if wasSelected {
            selectedPlantID = plants.first(where: { $0.id != plant.id })?.id
        }
    }

    private func showFeedback(_ text: String) {
        withAnimation(.spring(response: 0.3)) {
            feedbackText = text
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { feedbackText = nil }
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
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Remove Plant", systemImage: "trash")
            }
        }
    }
}

// MARK: - Add Plant Sheet

private struct AddPlantSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onAdd: (String, PlantSpecies) -> Void

    @State private var selectedSpecies: PlantSpecies = .sunflower
    @State private var plantName: String = PlantSpecies.sunflower.labelEN

    var body: some View {
        NavigationStack {
            ZStack {
                TreeholeTheme.gardenBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: TreeholeTheme.spacingLarge) {
                        // Species picker
                        VStack(alignment: .leading, spacing: TreeholeTheme.spacingSmall) {
                            Text("Choose a Species")
                                .font(.headline)
                                .foregroundStyle(TreeholeTheme.textPrimary)
                                .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: TreeholeTheme.spacingSmall) {
                                    ForEach(PlantSpecies.allCases) { species in
                                        Button {
                                            selectedSpecies = species
                                            if plantName.isEmpty || PlantSpecies.allCases.map(\.labelEN).contains(plantName) {
                                                plantName = species.labelEN
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
                                                Text(species.labelEN)
                                                    .font(.caption)
                                                    .foregroundStyle(selectedSpecies == species
                                                        ? TreeholeTheme.textPrimary
                                                        : TreeholeTheme.textSecondary)
                                            }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }

                        // Name field
                        VStack(alignment: .leading, spacing: TreeholeTheme.spacingSmall) {
                            Text("Plant Name")
                                .font(.headline)
                                .foregroundStyle(TreeholeTheme.textPrimary)
                            TextField("Enter a name", text: $plantName)
                                .textFieldStyle(.roundedBorder)
                                .padding(.vertical, 4)
                        }
                        .padding(.horizontal)

                        // Preview
                        VStack(spacing: 8) {
                            Text(selectedSpecies.emoji)
                                .font(.system(size: 64))
                            Text(plantName.isEmpty ? selectedSpecies.labelEN : plantName)
                                .font(.title3.bold())
                                .foregroundStyle(TreeholeTheme.textPrimary)
                            Text("Starting as a Seed")
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
                            onAdd(finalName.isEmpty ? selectedSpecies.labelEN : finalName, selectedSpecies)
                            dismiss()
                        } label: {
                            Label("Plant Seed", systemImage: "leaf.fill")
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
            .navigationTitle("New Plant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
