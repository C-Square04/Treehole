//
//  Plant.swift
//  Treehole
//
//  Created by Kayli Cheung on 2025-11-06.
//

import Foundation

struct PlantState: Codable, Identifiable {
    let id: String
    var name: String = "My Plant"
    var species: PlantSpecies = .sunflower
    var growthStage: GrowthStage = .seed
    var hydrationLevel: Int = 100 // 0-100
    var lastWateredAt: Date?
    var experience: Int = 0
    var createdAt: Date
    var decorations: [String] = []

    enum PlantSpecies: String, Codable, CaseIterable {
        case sunflower = "Sunflower"
        case rose = "Rose"
        case tulip = "Tulip"
        case cactus = "Cactus"
        case fern = "Fern"

        var emoji: String {
            switch self {
            case .sunflower:
                return "🌻"
            case .rose:
                return "🌹"
            case .tulip:
                return "🌷"
            case .cactus:
                return "🌵"
            case .fern:
                return "🌿"
            }
        }

        var description: String {
            switch self {
            case .sunflower:
                return "Sunflower"
            case .rose:
                return "Rose"
            case .tulip:
                return "Tulip"
            case .cactus:
                return "Cactus"
            case .fern:
                return "Fern"
            }
        }
    }

    enum GrowthStage: String, Codable {
        case seed = "Seed"
        case sprout = "Sprout"
        case growing = "Growing"
        case blooming = "Blooming"
        case mature = "Mature"

        var icon: String {
            switch self {
            case .seed:
                return "🌰"
            case .sprout:
                return "🌱"
            case .growing:
                return "🌿"
            case .blooming:
                return "🌸"
            case .mature:
                return "🌳"
            }
        }
    }

    var hydrationStatus: HydrationStatus {
        switch hydrationLevel {
        case 75...100:
            return .well_watered
        case 50..<75:
            return .adequate
        case 25..<50:
            return .dry
        default:
            return .dying
        }
    }

    enum HydrationStatus: String {
        case well_watered
        case adequate
        case dry
        case dying
    }

    mutating func water() {
        hydrationLevel = min(100, hydrationLevel + 40)
        lastWateredAt = Date()
        experience += 5

        // Update growth stage based on experience
        if experience >= 100 && growthStage == .seed {
            growthStage = .sprout
        } else if experience >= 250 && growthStage == .sprout {
            growthStage = .growing
        } else if experience >= 500 && growthStage == .growing {
            growthStage = .blooming
        } else if experience >= 1000 && growthStage == .blooming {
            growthStage = .mature
        }
    }

    mutating func updateHydration() {
        // Decrease hydration over time
        if let lastWatered = lastWateredAt {
            let daysSinceWatering = Date().timeIntervalSince(lastWatered) / 86400
            hydrationLevel = max(0, hydrationLevel - Int(daysSinceWatering * 20))
        }
    }
}
