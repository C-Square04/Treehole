//
//  SettingsView.swift
//  Treehole
//
//  Created by Kayli Cheung & Jimmy Chen on 2025-11-06.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var appState: AppState
    @State private var selectedTab: SettingsTab = .account

    enum SettingsTab {
        case account
        case security
        case privacy
        case appearance
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.95, green: 0.97, blue: 1.0),
                        Color(red: 0.98, green: 0.95, blue: 0.97)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    VStack {
                        Text("Settings")
                            .font(.title2)
                            .fontWeight(.bold)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                SettingsTabButton(
                                    title: "Account",
                                    icon: "person.crop.circle",
                                    isSelected: selectedTab == .account,
                                    action: { selectedTab = .account }
                                )
                                SettingsTabButton(
                                    title: "Security",
                                    icon: "shield.fill",
                                    isSelected: selectedTab == .security,
                                    action: { selectedTab = .security }
                                )
                                SettingsTabButton(
                                    title: "Privacy",
                                    icon: "lock.fill",
                                    isSelected: selectedTab == .privacy,
                                    action: { selectedTab = .privacy }
                                )
                                SettingsTabButton(
                                    title: "Appearance",
                                    icon: "paintpalette.fill",
                                    isSelected: selectedTab == .appearance,
                                    action: { selectedTab = .appearance }
                                )
                                Spacer()
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)

                    ScrollView {
                        Group {
                            switch selectedTab {
                            case .account:
                                AccountSettingsView(appState: appState)
                            case .security:
                                SecuritySettingsView(appState: appState)
                            case .privacy:
                                PrivacySettingsView(appState: appState)
                            case .appearance:
                                AppearanceSettingsView(appState: appState)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
    }
}

struct SettingsTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.headline)
                Text(title)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue.opacity(0.2) : Color(UIColor.systemGray6))
            .foregroundColor(isSelected ? .blue : .gray)
            .cornerRadius(8)
        }
    }
}

struct AccountSettingsView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(spacing: 16) {
            // Profile info
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Account")
                            .font(.headline)
                        if !appState.isGuest {
                            Text(appState.currentUser?.privateName ?? "Unknown")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        } else {
                            Text("Guest User")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    Spacer()
                    if let user = appState.currentUser {
                        VStack(alignment: .trailing, spacing: 4) {
                            Label(user.authProvider.rawValue.uppercased(), systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }

            // Subscription status
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Subscription")
                            .font(.headline)
                        Text(appState.currentUser?.subscriptionStatus.rawValue.uppercased() ?? "FREE")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    if appState.currentUser?.subscriptionStatus != .pro {
                        Button(action: {}) {
                            Text("Upgrade")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue)
                                .cornerRadius(6)
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }

            // Language
            VStack(spacing: 12) {
                HStack {
                    Label("Language", systemImage: "globe")
                        .font(.headline)
                    Spacer()
                    Button(action: { appState.toggleLanguage() }) {
                        HStack(spacing: 4) {
                            let lang = appState.currentUser?.themePrefs.preferredLanguage == .english ? "English" : "中文"
                            Text(lang)
                                .font(.subheadline)
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }

            // Logout
            if !appState.isGuest {
                Button(action: { appState.logout() }) {
                    HStack {
                        Image(systemName: "arrow.backward.circle.fill")
                        Text("Logout")
                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.red)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
    }
}

struct PrivacySettingsView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(spacing: 16) {
            // Anonymity explanation
            VStack(spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Anonymous Design", systemImage: "eye.slash.fill")
                            .font(.headline)
                        Text("Your real name is only visible to you. Others see a random alias that changes regularly.")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }

            // Content moderation
            VStack(spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Content Safety", systemImage: "shield.fill")
                            .font(.headline)
                        Text("We use AI and community guidelines to keep the app safe, kind, and supportive.")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }

            // Data export
            VStack(spacing: 12) {
                Button(action: {}) {
                    HStack {
                        Image(systemName: "arrow.down.doc.fill")
                        Text("Export My Data")
                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .foregroundColor(.blue)
                    .cornerRadius(12)
                }

                Button(action: {}) {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text("Delete My Account")
                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(12)
                }
            }

            // Legal
            VStack(spacing: 8) {
                Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(8)

                Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(8)
            }
            .foregroundColor(.blue)
            .font(.subheadline)
        }
    }
}

struct AppearanceSettingsView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(spacing: 16) {
            // Theme
            VStack(spacing: 12) {
                HStack {
                    Label("Dark Mode", systemImage: "moon.fill")
                        .font(.headline)
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { appState.currentUser?.themePrefs.isDarkMode ?? false },
                        set: { isDark in
                            var prefs = appState.currentUser?.themePrefs ?? ThemePreferences()
                            prefs.isDarkMode = isDark
                            appState.updateThemePreference(prefs)
                        }
                    ))
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }

            // Reduce motion
            VStack(spacing: 12) {
                HStack {
                    Label("Reduce Motion", systemImage: "hare.fill")
                        .font(.headline)
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { appState.currentUser?.themePrefs.reduceMotion ?? false },
                        set: { reduce in
                            var prefs = appState.currentUser?.themePrefs ?? ThemePreferences()
                            prefs.reduceMotion = reduce
                            appState.updateThemePreference(prefs)
                        }
                    ))
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }

            // Font size
            VStack(spacing: 12) {
                HStack {
                    Label("Font Size", systemImage: "textformat.size")
                        .font(.headline)
                    Spacer()
                    Picker("", selection: Binding(
                        get: { appState.currentUser?.themePrefs.fontSize ?? .medium },
                        set: { size in
                            var prefs = appState.currentUser?.themePrefs ?? ThemePreferences()
                            prefs.fontSize = size
                            appState.updateThemePreference(prefs)
                        }
                    )) {
                        ForEach([ThemePreferences.FontSize.small, .medium, .large], id: \.self) { size in
                            Text(size.rawValue.capitalized).tag(size)
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }

            // Language
            VStack(spacing: 12) {
                HStack {
                    Label("Language", systemImage: "globe")
                        .font(.headline)
                    Spacer()
                    Picker("", selection: Binding(
                        get: { appState.currentUser?.themePrefs.preferredLanguage ?? .simplifiedChinese },
                        set: { lang in
                            var prefs = appState.currentUser?.themePrefs ?? ThemePreferences()
                            prefs.preferredLanguage = lang
                            appState.updateThemePreference(prefs)
                        }
                    )) {
                        Text("English").tag(ThemePreferences.Language.english)
                        Text("中文").tag(ThemePreferences.Language.simplifiedChinese)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }
        }
    }
}

struct SecuritySettingsView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(spacing: 16) {
            // Session Management
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Active Sessions", systemImage: "iphone.and.arrow.forward")
                            .font(.headline)
                        Text("Manage devices with access to your account")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }

            // Two-Factor Authentication
            VStack(spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Two-Factor Authentication", systemImage: "checkmark.shield.fill")
                            .font(.headline)
                        Text("Add an extra layer of security to your account")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Button(action: {}) {
                        Text("Enable")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }

            // Password Management
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Password", systemImage: "key.fill")
                            .font(.headline)
                        if !appState.isGuest {
                            Text("Last changed 2 months ago")
                                .font(.caption)
                                .foregroundColor(.gray)
                        } else {
                            Text("Sign in to manage password")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    Spacer()
                    if !appState.isGuest {
                        Button(action: {}) {
                            Text("Change")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }

            // Connected Apps
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Connected Apps", systemImage: "link.badge.plus")
                            .font(.headline)
                        Text("Manage third-party app permissions")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }

            // Account Activity
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Account Activity", systemImage: "clock.fill")
                            .font(.headline)
                        Text("View recent account activity and logins")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }
        }
    }
}

#Preview {
    SettingsView(appState: AppState())
}
