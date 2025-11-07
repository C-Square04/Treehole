//
//  Pet.swift
//  Treehole
//
//  Created by Kayli Cheung on 2025-11-06.
//

import Foundation

struct PetState: Codable, Identifiable {
    let id: String
    var name: String = "Companion"
    var hungerLevel: Int = 100 // 0-100
    var mood: PetMood = .neutral
    var energy: Int = 80 // 0-100
    var unlockedSkins: [String] = ["default"]
    var currentSkin: String = "default"
    var lastFedAt: Date?
    var chatQuota: Int = 3 // Daily limit for AI chat
    var chatQuotaResetDate: Date = Date()
    var decorations: [String] = [] // IDs of purchased decorations
    var homeTheme: HomeTheme = .daylight
    var level: Int = 1
    var experience: Int = 0
    var nextLevelExp: Int = 100
    var createdAt: Date

    enum PetMood: String, Codable {
        case happy
        case neutral
        case sad
        case excited
        case tired
    }

    var hungerStatus: HungerStatus {
        switch hungerLevel {
        case 75...100:
            return .satisfied
        case 50..<75:
            return .content
        case 25..<50:
            return .hungry
        default:
            return .starving
        }
    }

    enum HungerStatus: String {
        case satisfied
        case content
        case hungry
        case starving
    }

    enum HomeTheme: String, Codable, CaseIterable {
        case daylight = "daylight"
        case night = "night"
        case sunset = "sunset"
        case garden = "garden"
    }

    mutating func feed() {
        hungerLevel = min(100, hungerLevel + 30)
        lastFedAt = Date()
        mood = .happy
        energy = min(100, energy + 20)
    }

    mutating func addExperience(_ amount: Int) {
        experience += amount
        while experience >= nextLevelExp {
            experience -= nextLevelExp
            level += 1
            nextLevelExp = Int(Double(nextLevelExp) * 1.2)
            mood = .excited
        }
    }

    mutating func updateHunger() {
        // Decrease hunger over time (called periodically)
        if let lastFed = lastFedAt {
            let hoursSinceFeeding = Date().timeIntervalSince(lastFed) / 3600
            hungerLevel = max(0, hungerLevel - Int(hoursSinceFeeding))
        }
    }
}

struct HomeDecoration: Codable, Identifiable {
    let id: String
    var name: String
    var description: String
    var category: DecorCategory
    var price: Int // In decoration tokens
    var rarity: Rarity
    var isObtainable: Bool // Can be obtained without paying
    var isPaid: Bool // Requires real money

    enum DecorCategory: String, Codable, CaseIterable {
        case furniture = "furniture"
        case background = "background"
        case wall = "wall"
        case floor = "floor"
        case decoration = "decoration"
    }

    enum Rarity: String, Codable {
        case common
        case uncommon
        case rare
        case legendary
    }
}
