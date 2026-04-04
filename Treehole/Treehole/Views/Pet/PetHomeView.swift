import SwiftUI
import SwiftData

struct PetHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var pets: [Pet]
    @State private var viewModel = PetViewModel()
    @State private var feedbackText: String?

    var body: some View {
        NavigationStack {
            if let pet = pets.first {
                petContentView(pet: pet)
            } else {
                ProgressView("Loading...")
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

        ZStack {
            LinearGradient(colors: [themeColors.0, themeColors.1], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: TreeholeTheme.spacingLarge) {
                    // Pet display
                    CartoonCatView(mood: pet.mood, showFeedingAnimation: viewModel.showFeedingAnimation)
                        .frame(height: 280)
                        .overlay(alignment: .top) {
                            if let text = feedbackText {
                                Text(text)
                                    .font(.caption.bold())
                                    .foregroundStyle(TreeholeTheme.warmGold)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                                    .offset(y: -10)
                            }
                        }

                    // Pet name & mood
                    VStack(spacing: 4) {
                        Text(pet.name)
                            .font(.title2.bold())
                            .foregroundStyle(TreeholeTheme.textPrimary)
                        Text("\(pet.mood.emoji) \(pet.mood.labelEN)")
                            .font(.subheadline)
                            .foregroundStyle(TreeholeTheme.textSecondary)
                    }

                    // Status card
                    VStack(spacing: TreeholeTheme.spacingSmall) {
                        StatBadge(label: "Hunger", value: "\(pet.hungerLevel)/100 - \(pet.hungerDescription)", icon: "fork.knife", color: TreeholeTheme.coral)
                        ProgressBar(value: pet.hungerLevel, maxValue: 100, color: TreeholeTheme.coral)

                        StatBadge(label: "Energy", value: "\(pet.energy)/100", icon: "bolt.fill", color: TreeholeTheme.skyBlue)
                        ProgressBar(value: pet.energy, maxValue: 100, color: TreeholeTheme.skyBlue)

                        StatBadge(label: "Level", value: "Level \(pet.level) • \(pet.experience)/\(pet.nextLevelExp) XP", icon: "star.fill", color: TreeholeTheme.warmGold)
                        ProgressBar(value: pet.experience, maxValue: pet.nextLevelExp, color: TreeholeTheme.warmGold)
                    }
                    .glassCard()

                    // Action buttons
                    HStack(spacing: TreeholeTheme.spacingSmall) {
                        Button {
                            pet.feed()
                            viewModel.showFeedingAnimation = true
                            showFeedback("+30 Hunger, +10 XP")
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                viewModel.showFeedingAnimation = false
                            }
                        } label: {
                            Label("Feed", systemImage: "cup.and.saucer.fill")
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, TreeholeTheme.spacingSmall)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(TreeholeTheme.coral)
                        .disabled(pet.hungerLevel >= 100)

                        Button {
                            pet.pet()
                            showFeedback("+10 Energy")
                        } label: {
                            Label("Pet", systemImage: "hand.raised.fill")
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, TreeholeTheme.spacingSmall)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(TreeholeTheme.softPurple)
                        .disabled(pet.energy >= 100)

                        Button {
                            pet.rest()
                            showFeedback("+40 Energy")
                        } label: {
                            Label("Rest", systemImage: "moon.fill")
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, TreeholeTheme.spacingSmall)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(TreeholeTheme.skyBlue)
                        .disabled(pet.energy >= 100)
                    }
                    .padding(.horizontal)

                    // Theme picker
                    VStack(alignment: .leading, spacing: TreeholeTheme.spacingSmall) {
                        Text("Home Theme")
                            .font(.caption)
                            .foregroundStyle(TreeholeTheme.textSecondary)
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
                                                    Circle()
                                                        .strokeBorder(TreeholeTheme.textPrimary, lineWidth: 2)
                                                }
                                            }
                                        Text(theme.labelEN)
                                            .font(.caption2)
                                            .foregroundStyle(
                                                pet.homeTheme == theme
                                                    ? TreeholeTheme.textPrimary
                                                    : TreeholeTheme.textSecondary
                                            )
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .glassCard()
                }
                .padding()
            }
        }
        .navigationTitle("Pet")
        .onAppear { pet.updateHunger() }
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
