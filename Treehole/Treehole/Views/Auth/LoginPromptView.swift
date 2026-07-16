import SwiftUI
import AuthenticationServices

struct LoginPromptView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                TreeholeTheme.warmBackground.ignoresSafeArea()

                VStack(spacing: TreeholeTheme.spacingXL) {
                    Spacer()

                    // Icon
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 64))
                        .foregroundStyle(TreeholeTheme.coral)
                        .accessibilityHidden(true)

                    // Title
                    VStack(spacing: TreeholeTheme.spacingTight) {
                        Text(L10n.t("Welcome to Treehole", "欢迎来到树洞"))
                            .font(.title2.bold())
                            .foregroundStyle(TreeholeTheme.textPrimary)
                        Text(L10n.t("Sign in to save your progress and sync across devices.", "登录以保存你的进度..."))
                            .font(.subheadline)
                            .foregroundStyle(TreeholeTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    // Benefits comparison
                    VStack(alignment: .leading, spacing: TreeholeTheme.spacingSmall) {
                        BenefitRow(icon: "checkmark.circle.fill", color: .green, text: L10n.t("Save your posts and journal entries", "保存你的帖子和日记"))
                        BenefitRow(icon: "checkmark.circle.fill", color: .green, text: L10n.t("Sync your pet and plant progress", "同步你的宠物和植物进度"))
                        BenefitRow(icon: "checkmark.circle.fill", color: .green, text: L10n.t("Keep your data safe", "保护你的数据安全"))
                        BenefitRow(icon: "xmark.circle.fill", color: .red, text: L10n.t("Guests can lose data if the app is deleted", "访客在删除应用后可能丢失数据"))
                    }
                    .glassCard()

                    // Auth buttons
                    VStack(spacing: TreeholeTheme.spacingSmall) {
                        // Apple Sign-In
                        SignInWithAppleButton(.signIn) { request in
                            request.requestedScopes = [.email]
                        } onCompletion: { result in
                            switch result {
                            case .success(let auth):
                                if let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                                    let userID = credential.user
                                    let email = credential.email
                                    appState.loginWithApple(userID: userID, email: email)
                                    dismiss()
                                }
                            case .failure(let error):
                                print("Apple Sign-In failed: \(error)")
                            }
                        }
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: TreeholeTheme.cornerLarge))

                        // Guest
                        Button {
                            appState.loginAsGuest()
                            dismiss()
                        } label: {
                            Text(L10n.t("Continue as Guest", "以访客身份继续"))
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        }
                        .background(TreeholeTheme.textSecondary.opacity(0.12), in: RoundedRectangle(cornerRadius: TreeholeTheme.cornerLarge))
                        .foregroundStyle(TreeholeTheme.textSecondary)
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding(.horizontal, TreeholeTheme.spacingXL)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.t("Cancel", "取消")) { dismiss() }
                }
            }
        }
    }
}

private struct BenefitRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: TreeholeTheme.spacingSmall) {
            Image(systemName: icon)
                .foregroundStyle(color)
                // The icon carries meaning (benefit vs. warning) — voice it
                .accessibilityLabel(icon.contains("xmark")
                    ? L10n.t("Warning", "注意")
                    : L10n.t("Benefit", "优势"))
            Text(text)
                .font(.subheadline)
                .foregroundStyle(TreeholeTheme.textPrimary)
        }
        .accessibilityElement(children: .combine)
    }
}
