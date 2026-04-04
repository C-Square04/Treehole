import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState

        NavigationStack {
            List {
                // Account section
                Section("Account") {
                    HStack(spacing: TreeholeTheme.spacingSmall) {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundStyle(TreeholeTheme.softPurple)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(appState.currentAlias)
                                .font(.headline)
                            Text(appState.isGuest ? "Guest" : "Signed In")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if appState.daysUntilAliasExpiry > 0 {
                            Text("\(appState.daysUntilAliasExpiry)d")
                                .font(.caption)
                                .foregroundStyle(TreeholeTheme.textLight)
                        }
                    }

                    if appState.isGuest {
                        Button {
                            appState.showLoginPrompt = true
                        } label: {
                            Label("Sign In", systemImage: "person.badge.plus")
                        }
                    }
                }

                // Alias explanation
                Section {
                    NavigationLink {
                        AliasExplanationView()
                    } label: {
                        Label("About Aliases", systemImage: "theatermasks")
                    }
                } footer: {
                    Text("Your alias changes every 7 days to protect your privacy. No one can see your real identity.")
                }

                // Appearance
                Section("Appearance") {
                    Picker("Language", selection: $state.preferredLanguage) {
                        Text("English").tag("en")
                        Text("中文").tag("zh-Hans")
                    }

                    Toggle("Dark Mode", isOn: $state.isDarkMode)
                }

                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Treehole")
                        Spacer()
                        Text("A safe space for your thoughts")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Logout
                if !appState.isGuest {
                    Section {
                        Button("Sign Out", role: .destructive) {
                            appState.logout()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $state.showLoginPrompt) {
                LoginPromptView()
            }
        }
    }
}

// MARK: - Alias Explanation View

struct AliasExplanationView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView {
            VStack(spacing: TreeholeTheme.spacingLarge) {
                // Current alias card
                VStack(spacing: TreeholeTheme.spacingSmall) {
                    Image(systemName: "theatermasks.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(TreeholeTheme.softPurple)

                    Text("Your Current Alias")
                        .font(.headline)
                        .foregroundStyle(TreeholeTheme.textSecondary)

                    Text(appState.currentAlias)
                        .font(.title.bold())
                        .foregroundStyle(TreeholeTheme.textPrimary)

                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                        Text("Changes in \(appState.daysUntilAliasExpiry) days")
                    }
                    .font(.caption)
                    .foregroundStyle(TreeholeTheme.textLight)
                }
                .frame(maxWidth: .infinity)
                .glassCard()

                // Explanation cards
                VStack(alignment: .leading, spacing: TreeholeTheme.spacingMedium) {
                    ExplanationRow(
                        icon: "theatermasks",
                        color: TreeholeTheme.softPurple,
                        title: "What are aliases?",
                        text: "Everyone on Treehole gets a random display name. This keeps you completely anonymous when sharing your thoughts."
                    )
                    Divider()
                    ExplanationRow(
                        icon: "arrow.triangle.2.circlepath",
                        color: TreeholeTheme.skyBlue,
                        title: "Automatic rotation",
                        text: "Your alias changes every 7 days automatically. You'll receive a notification when it changes so you know your new name."
                    )
                    Divider()
                    ExplanationRow(
                        icon: "lock.shield",
                        color: TreeholeTheme.mintCream,
                        title: "Your privacy matters",
                        text: "No one — not even other users — can see your real name or connect your posts to your identity. Your real name stays on your device only."
                    )
                    Divider()
                    ExplanationRow(
                        icon: "link.badge.plus",
                        color: TreeholeTheme.coral,
                        title: "Posts are disconnected",
                        text: "When your alias changes, your old posts still show the old alias. This makes it even harder for anyone to track your activity."
                    )
                }
                .glassCard()
            }
            .padding()
        }
        .navigationTitle("About Aliases")
        .treeholeBackground()
    }
}

private struct ExplanationRow: View {
    let icon: String
    let color: Color
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: TreeholeTheme.spacingSmall) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(TreeholeTheme.textPrimary)
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(TreeholeTheme.textSecondary)
            }
        }
    }
}
