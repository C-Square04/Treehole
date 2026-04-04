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

                    // Title
                    VStack(spacing: TreeholeTheme.spacingTight) {
                        Text("Welcome to Treehole")
                            .font(.title2.bold())
                            .foregroundStyle(TreeholeTheme.textPrimary)
                        Text("Sign in to save your progress and sync across devices.")
                            .font(.subheadline)
                            .foregroundStyle(TreeholeTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    // Benefits comparison
                    VStack(alignment: .leading, spacing: TreeholeTheme.spacingSmall) {
                        BenefitRow(icon: "checkmark.circle.fill", color: .green, text: "Save your posts and journal entries")
                        BenefitRow(icon: "checkmark.circle.fill", color: .green, text: "Sync your pet and plant progress")
                        BenefitRow(icon: "checkmark.circle.fill", color: .green, text: "Keep your data safe")
                        BenefitRow(icon: "xmark.circle.fill", color: .red, text: "Guests can lose data if the app is deleted")
                    }
                    .glassCard()

                    // Auth buttons
                    VStack(spacing: TreeholeTheme.spacingSmall) {
                        // Apple Sign-In
                        SignInWithAppleButton(.signIn) { request in
                            request.requestedScopes = [.email]
                        } onCompletion: { result in
                            switch result {
                            case .success:
                                appState.loginWithApple()
                                dismiss()
                            case .failure:
                                break
                            }
                        }
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 50)
                        .cornerRadius(TreeholeTheme.cornerMedium)

                        // Guest
                        Button {
                            appState.loginAsGuest()
                            dismiss()
                        } label: {
                            Text("Continue as Guest")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, TreeholeTheme.spacingSmall)
                        }
                        .buttonStyle(.bordered)
                        .tint(TreeholeTheme.textSecondary)
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding(.horizontal, TreeholeTheme.spacingXL)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
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
            Text(text)
                .font(.subheadline)
                .foregroundStyle(TreeholeTheme.textPrimary)
        }
    }
}
