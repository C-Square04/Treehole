//
//  User.swift
//  Treehole
//
//  Created by Kayli Cheung on 2025-11-06.
//

import Foundation

struct User: Codable, Identifiable {
    let id: String
    var privateName: String
    var authProvider: AuthProvider
    var isGuest: Bool
    var subscriptionStatus: SubscriptionStatus
    var themePrefs: ThemePreferences
    var createdAt: Date
    var lastLoginAt: Date?

    enum AuthProvider: String, Codable {
        case appleid
        case google
        case email
        case guest
    }

    enum SubscriptionStatus: String, Codable {
        case free
        case pro
        case trial
    }
}

struct ThemePreferences: Codable {
    var isDarkMode: Bool = false
    var preferredLanguage: Language = .simplifiedChinese
    var reduceMotion: Bool = false
    var fontSize: FontSize = .medium

    enum Language: String, Codable {
        case simplifiedChinese = "zh-Hans"
        case english = "en"
    }

    enum FontSize: String, Codable {
        case small
        case medium
        case large
    }
}

struct AliasSession: Codable, Identifiable {
    let id: String
    var generatedName: String
    var expiryTimestamp: Date
    var isExpired: Bool {
        Date() > expiryTimestamp
    }
}
