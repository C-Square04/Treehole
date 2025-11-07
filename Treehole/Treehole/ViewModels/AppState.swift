//
//  AppState.swift
//  Treehole
//
//  Created by Kayli Cheung & Jimmy Chen on 2025-11-06.
//

import Foundation
import Combine

class AppState: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    @Published var isGuest: Bool = true
    @Published var currentAlias: AliasSession?
    @Published var showLoginSheet: Bool = false
    @Published var authError: String?

    private var cancellables = Set<AnyCancellable>()

    init() {
        loadUserFromKeychain()
    }

    // MARK: - Authentication Methods

    func loginAsGuest() {
        let guestUser = User(
            id: UUID().uuidString,
            privateName: "Guest",
            authProvider: .guest,
            isGuest: true,
            subscriptionStatus: .free,
            themePrefs: ThemePreferences(),
            createdAt: Date()
        )
        currentUser = guestUser
        isGuest = true
        isAuthenticated = false
        generateNewAlias()
    }

    func loginWithAppleID(userId: String, email: String?) {
        let user = User(
            id: userId,
            privateName: email ?? "Apple User",
            authProvider: .appleid,
            isGuest: false,
            subscriptionStatus: .free,
            themePrefs: ThemePreferences(),
            createdAt: Date()
        )
        currentUser = user
        isGuest = false
        isAuthenticated = true
        saveUserToKeychain(user)
        generateNewAlias()
    }

    func loginWithEmail(email: String, password: String) {
        // In a real app, this would validate against a backend
        let user = User(
            id: UUID().uuidString,
            privateName: email,
            authProvider: .email,
            isGuest: false,
            subscriptionStatus: .free,
            themePrefs: ThemePreferences(),
            createdAt: Date()
        )
        currentUser = user
        isGuest = false
        isAuthenticated = true
        saveUserToKeychain(user)
        generateNewAlias()
    }

    func loginWithGoogle(userId: String, email: String?, displayName: String?) {
        let user = User(
            id: userId,
            privateName: email ?? displayName ?? "Google User",
            authProvider: .google,
            isGuest: false,
            subscriptionStatus: .free,
            themePrefs: ThemePreferences(),
            createdAt: Date()
        )
        currentUser = user
        isGuest = false
        isAuthenticated = true
        saveUserToKeychain(user)
        generateNewAlias()
    }

    func logout() {
        currentUser = nil
        isAuthenticated = false
        isGuest = true
        currentAlias = nil
        removeUserFromKeychain()
        loginAsGuest()
    }

    // MARK: - Alias Management

    func generateNewAlias() {
        let aliases = [
            "CloudWhisperer", "DreamWeaver", "SilentMoon", "NightOwl",
            "QuietSoul", "WhisperingWind", "MoonLight", "StarDust",
            "SoftCloud", "EchoHeart", "TranquilMind", "GentleSpirit",
            "云语者", "梦织者", "月影", "夜猫子",
            "静心", "低语风", "月光", "星尘"
        ]

        let randomAlias = aliases.randomElement() ?? "Anonymous"
        let expiryDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

        currentAlias = AliasSession(
            id: UUID().uuidString,
            generatedName: randomAlias,
            expiryTimestamp: expiryDate
        )
    }

    // MARK: - Keychain Storage

    private func saveUserToKeychain(_ user: User) {
        // In a real app, use Security framework to save to keychain
        do {
            let encoded = try JSONEncoder().encode(user)
            UserDefaults.standard.set(encoded, forKey: "savedUser")
        } catch {
            print("ERROR: Failed to encode user for keychain: \(error)")
        }
    }

    private func loadUserFromKeychain() {
        if let data = UserDefaults.standard.data(forKey: "savedUser") {
            do {
                let user = try JSONDecoder().decode(User.self, from: data)
                currentUser = user
                isAuthenticated = !user.isGuest
                isGuest = user.isGuest
                generateNewAlias()
            } catch {
                print("ERROR: Failed to decode user from keychain: \(error)")
                loginAsGuest()
            }
        } else {
            loginAsGuest()
        }
    }

    private func removeUserFromKeychain() {
        UserDefaults.standard.removeObject(forKey: "savedUser")
    }

    // MARK: - Theme Preferences

    func updateThemePreference(_ prefs: ThemePreferences) {
        if var user = currentUser {
            user.themePrefs = prefs
            currentUser = user  // Reassign to trigger @Published
            saveUserToKeychain(user)
        }
    }

    func toggleLanguage() {
        var newPrefs = currentUser?.themePrefs ?? ThemePreferences()
        newPrefs.preferredLanguage = newPrefs.preferredLanguage == .simplifiedChinese ? .english : .simplifiedChinese
        updateThemePreference(newPrefs)
    }
}
