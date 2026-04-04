import SwiftUI
import SwiftData

struct PetHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var pets: [Pet]
    @State private var viewModel = PetViewModel()
    @State private var feedbackText: String?

    private var pet: Pet {
        viewModel.ensurePetExists(context: modelContext, pets: pets)
    }

    private var themeGradient: LinearGradient {
        let (top, bottom) = pet.homeTheme.gradient
        return LinearGradient(
            colors: [top, bottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                themeGradient.ignoresSafeArea()

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
                            // Hunger
                            StatBadge(
                                label: "Hunger",
                                value: "\(pet.hungerLevel)/100 - \(pet.hungerDescription)",
                                icon: "fork.knife",
                                color: TreeholeTheme.coral
                            )
                            ProgressBar(value: pet.hungerLevel, maxValue: 100, color: TreeholeTheme.coral)

                            // Energy
                            StatBadge(
                                label: "Energy",
                                value: "\(pet.energy)/100",
                                icon: "bolt.fill",
                                color: TreeholeTheme.skyBlue
                            )
                            ProgressBar(value: pet.energy, maxValue: 100, color: TreeholeTheme.skyBlue)

                            // Level & XP
                            StatBadge(
                                label: "Level",
                                value: "Level \(pet.level) • \(pet.experience)/\(pet.nextLevelExp) XP",
                                icon: "star.fill",
                                color: TreeholeTheme.warmGold
                            )
                            ProgressBar(value: pet.experience, maxValue: pet.nextLevelExp, color: TreeholeTheme.warmGold)
                        }
                        .glassCard()

                        // Action buttons
                        HStack(spacing: TreeholeTheme.spacingSmall) {
                            // Feed
                            Button {
                                viewModel.feed(pet: pet)
                                showFeedback("+30 Hunger")
                            } label: {
                                Label("Feed", systemImage: "cup.and.saucer.fill")
                                    .font(.subheadline.bold())
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, TreeholeTheme.spacingSmall)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(TreeholeTheme.coral)
                            .disabled(pet.hungerLevel >= 100)

                            // Pet
                            Button {
                                viewModel.pet(pet: pet)
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

                            // Rest
                            Button {
                                viewModel.rest(pet: pet)
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
                                        viewModel.changeTheme(pet: pet, theme: theme)
                                    } label: {
                                        let (topColor, _) = theme.gradient
                                        VStack(spacing: 4) {
                                            Circle()
                                                .fill(topColor)
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
            .onAppear {
                viewModel.updateHunger(pet: pet)
            }
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
