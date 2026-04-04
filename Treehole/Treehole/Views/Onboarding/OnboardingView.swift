import SwiftUI

struct OnboardingFlowView: View {
    @Environment(AppState.self) private var appState
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            // Background gradient shifts with page
            backgroundForPage(currentPage)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: currentPage)

            VStack {
                TabView(selection: $currentPage) {
                    WelcomePage().tag(0)
                    FeaturesPage().tag(1)
                    PrivacyPage().tag(2)
                    GetStartedPage().tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
            }
        }
    }

    private func backgroundForPage(_ page: Int) -> LinearGradient {
        switch page {
        case 0: TreeholeTheme.softSunset
        case 1: TreeholeTheme.cloudyBackground
        case 2: TreeholeTheme.gardenBackground
        default: TreeholeTheme.warmBackground
        }
    }
}

// MARK: - Page 1: Welcome

private struct WelcomePage: View {
    var body: some View {
        VStack(spacing: TreeholeTheme.spacingXL) {
            Spacer()

            Image(systemName: "cloud.sun.fill")
                .font(.system(size: 80))
                .foregroundStyle(TreeholeTheme.warmGold, TreeholeTheme.skyBlue)
                .symbolEffect(.breathe)

            VStack(spacing: TreeholeTheme.spacingSmall) {
                Text("Welcome to Treehole")
                    .font(.largeTitle.bold())
                    .foregroundStyle(TreeholeTheme.textPrimary)

                Text("A safe space for your thoughts and feelings")
                    .font(.title3)
                    .foregroundStyle(TreeholeTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Text("Swipe to learn more")
                .font(.caption)
                .foregroundStyle(TreeholeTheme.textLight)
                .padding(.top, TreeholeTheme.spacingLarge)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, TreeholeTheme.spacingXL)
    }
}

// MARK: - Page 2: Features

private struct FeaturesPage: View {
    var body: some View {
        VStack(spacing: TreeholeTheme.spacingXL) {
            Spacer()

            Text("Your Sanctuary")
                .font(.title.bold())
                .foregroundStyle(TreeholeTheme.textPrimary)

            VStack(spacing: TreeholeTheme.spacingMedium) {
                FeatureRow(
                    icon: "cloud.fill",
                    color: TreeholeTheme.skyBlue,
                    title: "Floating Clouds",
                    description: "Share your thoughts anonymously"
                )
                FeatureRow(
                    icon: "cat.fill",
                    color: TreeholeTheme.coral,
                    title: "Pet Companion",
                    description: "A caring friend who listens"
                )
                FeatureRow(
                    icon: "leaf.fill",
                    color: TreeholeTheme.mintCream,
                    title: "Plant Garden",
                    description: "Grow something beautiful together"
                )
                FeatureRow(
                    icon: "book.fill",
                    color: TreeholeTheme.warmGold,
                    title: "Journal",
                    description: "Reflect on your feelings"
                )
            }
            .glassCard()

            Spacer()
            Spacer()
        }
        .padding(.horizontal, TreeholeTheme.spacingXL)
    }
}

private struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: TreeholeTheme.spacingMedium) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(TreeholeTheme.textPrimary)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(TreeholeTheme.textSecondary)
            }
            Spacer()
        }
    }
}

// MARK: - Page 3: Privacy & Aliases

private struct PrivacyPage: View {
    var body: some View {
        VStack(spacing: TreeholeTheme.spacingXL) {
            Spacer()

            Image(systemName: "theatermasks.fill")
                .font(.system(size: 64))
                .foregroundStyle(TreeholeTheme.softPurple)

            VStack(spacing: TreeholeTheme.spacingSmall) {
                Text("You're Completely Anonymous")
                    .font(.title2.bold())
                    .foregroundStyle(TreeholeTheme.textPrimary)

                Text("Every user gets a random alias that changes every 7 days. No one can see your real identity.")
                    .font(.body)
                    .foregroundStyle(TreeholeTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: TreeholeTheme.spacingSmall) {
                PrivacyBullet(icon: "person.fill.questionmark", text: "Random alias, refreshed weekly")
                PrivacyBullet(icon: "lock.shield.fill", text: "Your real name stays private")
                PrivacyBullet(icon: "eye.slash.fill", text: "Posts cannot be traced to you")
            }
            .glassCard()

            Spacer()
            Spacer()
        }
        .padding(.horizontal, TreeholeTheme.spacingXL)
    }
}

private struct PrivacyBullet: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: TreeholeTheme.spacingSmall) {
            Image(systemName: icon)
                .foregroundStyle(TreeholeTheme.softPurple)
                .frame(width: 28)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(TreeholeTheme.textPrimary)
            Spacer()
        }
    }
}

// MARK: - Page 4: Get Started

private struct GetStartedPage: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: TreeholeTheme.spacingXL) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 64))
                .foregroundStyle(TreeholeTheme.warmGold)

            Text("Ready to Begin?")
                .font(.title.bold())
                .foregroundStyle(TreeholeTheme.textPrimary)

            Text("Start your journey of self-care and emotional expression.")
                .font(.body)
                .foregroundStyle(TreeholeTheme.textSecondary)
                .multilineTextAlignment(.center)

            VStack(spacing: TreeholeTheme.spacingSmall) {
                // Guest
                Button {
                    appState.loginAsGuest()
                } label: {
                    Label("Continue as Guest", systemImage: "person.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, TreeholeTheme.spacingSmall)
                }
                .buttonStyle(.borderedProminent)
                .tint(TreeholeTheme.coral)

                // Apple Sign-In placeholder
                Button {
                    appState.loginWithApple()
                } label: {
                    Label("Sign in with Apple", systemImage: "apple.logo")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, TreeholeTheme.spacingSmall)
                }
                .buttonStyle(.bordered)
                .tint(TreeholeTheme.textPrimary)
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.horizontal, TreeholeTheme.spacingXL)
    }
}
