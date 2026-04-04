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

    var body: some View {
        NavigationStack {
            ZStack {
                TreeholeTheme.softSunset.ignoresSafeArea()

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
                            StatBadge(
                                label: "Hunger",
                                value: "\(pet.hungerLevel)/100 - \(pet.hungerDescription)",
                                icon: "fork.knife",
                                color: TreeholeTheme.coral
                            )
                            ProgressBar(value: pet.hungerLevel, maxValue: 100, color: TreeholeTheme.coral)
                        }
                        .glassCard()

                        // Feed button
                        Button {
                            viewModel.feed(pet: pet)
                            showFeedback("+30 Hunger")
                        } label: {
                            Label("Feed", systemImage: "cup.and.saucer.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, TreeholeTheme.spacingSmall)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(TreeholeTheme.coral)
                        .disabled(pet.hungerLevel >= 100)
                        .padding(.horizontal)
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
