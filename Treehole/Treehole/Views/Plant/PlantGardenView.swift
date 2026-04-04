import SwiftUI
import SwiftData

struct PlantGardenView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var plants: [Plant]
    @State private var showWateringAnimation = false
    @State private var feedbackText: String?

    private var plant: Plant {
        if let existing = plants.first { return existing }
        let newPlant = Plant(name: "My Sunflower", species: .sunflower)
        modelContext.insert(newPlant)
        return newPlant
    }

    var body: some View {
        NavigationStack {
            ZStack {
                TreeholeTheme.gardenBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: TreeholeTheme.spacingLarge) {
                        // Plant visual
                        PlantVisualView(
                            growthStage: plant.growthStage,
                            hydrationLevel: plant.hydrationLevel,
                            experience: plant.experience
                        )
                        .frame(height: 300)
                        .overlay(alignment: .top) {
                            if let text = feedbackText {
                                Text(text)
                                    .font(.caption.bold())
                                    .foregroundStyle(TreeholeTheme.skyBlue)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }

                        // Species & name
                        VStack(spacing: 4) {
                            Text("\(plant.species.emoji) \(plant.name)")
                                .font(.title2.bold())
                                .foregroundStyle(TreeholeTheme.textPrimary)
                            Text(plant.growthStage.labelEN)
                                .font(.subheadline)
                                .foregroundStyle(TreeholeTheme.textSecondary)
                        }

                        // Growth progress
                        VStack(spacing: TreeholeTheme.spacingSmall) {
                            StatBadge(
                                label: "Growth Stage",
                                value: "\(plant.growthStage.icon) \(plant.growthStage.labelEN) (\(plant.experience)/100 XP)",
                                icon: "chart.bar.fill",
                                color: TreeholeTheme.mintCream
                            )
                            HStack(spacing: 4) {
                                ForEach(GrowthStage.allCases, id: \.rawValue) { stage in
                                    Circle()
                                        .fill(stage.stageIndex <= plant.growthStage.stageIndex
                                            ? TreeholeTheme.mintCream
                                            : TreeholeTheme.mintCream.opacity(0.3))
                                        .frame(width: 12, height: 12)
                                }
                            }
                        }
                        .glassCard()

                        // Hydration
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
                    .padding()
                }
            }
            .navigationTitle("Garden")
            .onAppear { plant.updateHydration() }
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
