import SwiftUI
import AuthenticationServices

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
                .symbolEffect(.pulse)

            VStack(spacing: TreeholeTheme.spacingSmall) {
                Text(L10n.t("Welcome to Treehole", "欢迎来到树洞"))
                    .font(.largeTitle.bold())
                    .foregroundStyle(TreeholeTheme.textPrimary)

                Text(L10n.t("A safe space for your thoughts and feelings", "一个安全的空间，倾诉你的心声"))
                    .font(.title3)
                    .foregroundStyle(TreeholeTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Text(L10n.t("Swipe to learn more", "左滑了解更多"))
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

            Text(L10n.t("Your Sanctuary", "你的避风港"))
                .font(.title.bold())
                .foregroundStyle(TreeholeTheme.textPrimary)

            VStack(spacing: TreeholeTheme.spacingMedium) {
                FeatureRow(
                    icon: "cloud.fill",
                    color: TreeholeTheme.skyBlue,
                    title: L10n.t("Floating Clouds", "漂浮云朵"),
                    description: L10n.t("Share your thoughts anonymously", "匿名分享你的想法")
                )
                FeatureRow(
                    icon: "cat.fill",
                    color: TreeholeTheme.coral,
                    title: L10n.t("Pet Companion", "宠物伙伴"),
                    description: L10n.t("A caring friend who listens", "一个关心你的倾听者")
                )
                FeatureRow(
                    icon: "leaf.fill",
                    color: TreeholeTheme.mintCream,
                    title: L10n.t("Plant Garden", "植物花园"),
                    description: L10n.t("Grow something beautiful together", "一起种植美好")
                )
                FeatureRow(
                    icon: "book.fill",
                    color: TreeholeTheme.warmGold,
                    title: L10n.t("Journal", "日记"),
                    description: L10n.t("Reflect on your feelings", "记录你的感受")
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
                Text(L10n.t("You're Completely Anonymous", "完全匿名"))
                    .font(.title2.bold())
                    .foregroundStyle(TreeholeTheme.textPrimary)

                Text(L10n.t(
                    "Every user gets a random alias that changes every 7 days. No one can see your real identity.",
                    "每位用户都会获得一个随机别名，每7天更换一次。没有人能看到你的真实身份。"
                ))
                .font(.body)
                .foregroundStyle(TreeholeTheme.textSecondary)
                .multilineTextAlignment(.center)
            }

            VStack(spacing: TreeholeTheme.spacingSmall) {
                PrivacyBullet(icon: "person.fill.questionmark", text: L10n.t("Random alias, refreshed weekly", "随机别名，每周刷新"))
                PrivacyBullet(icon: "lock.shield.fill", text: L10n.t("Your real name stays private", "你的真实姓名保持私密"))
                PrivacyBullet(icon: "eye.slash.fill", text: L10n.t("Posts cannot be traced to you", "帖子无法追溯到你"))
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

            Text(L10n.t("Ready to Begin?", "准备好了吗？"))
                .font(.title.bold())
                .foregroundStyle(TreeholeTheme.textPrimary)

            Text(L10n.t(
                "Start your journey of self-care and emotional expression.",
                "开始你的自我关怀与情感表达之旅。"
            ))
            .font(.body)
            .foregroundStyle(TreeholeTheme.textSecondary)
            .multilineTextAlignment(.center)

            VStack(spacing: TreeholeTheme.spacingSmall) {
                // Guest
                Button {
                    appState.loginAsGuest()
                } label: {
                    Label(L10n.t("Continue as Guest", "以访客身份继续"), systemImage: "person.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, TreeholeTheme.spacingSmall)
                }
                .buttonStyle(.borderedProminent)
                .tint(TreeholeTheme.coral)

                // Apple Sign-In
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.email]
                } onCompletion: { result in
                    switch result {
                    case .success(let auth):
                        if let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                            appState.loginWithApple(userID: credential.user, email: credential.email)
                        }
                    case .failure:
                        break
                    }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .clipShape(RoundedRectangle(cornerRadius: TreeholeTheme.cornerLarge))
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.horizontal, TreeholeTheme.spacingXL)
    }
}
