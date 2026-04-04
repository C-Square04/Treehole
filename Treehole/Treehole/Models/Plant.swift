import Foundation
import SwiftData

// MARK: - Plant Species

enum PlantSpecies: String, Codable, CaseIterable, Identifiable {
    case sunflower, rose, tulip, cactus, fern

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .sunflower: "🌻"
        case .rose: "🌹"
        case .tulip: "🌷"
        case .cactus: "🌵"
        case .fern: "🌿"
        }
    }

    var labelEN: String {
        switch self {
        case .sunflower: "Sunflower"
        case .rose: "Rose"
        case .tulip: "Tulip"
        case .cactus: "Cactus"
        case .fern: "Fern"
        }
    }

    var labelZH: String {
        switch self {
        case .sunflower: "向日葵"
        case .rose: "玫瑰"
        case .tulip: "郁金香"
        case .cactus: "仙人掌"
        case .fern: "蕨类"
        }
    }
}

// MARK: - Growth Stage

enum GrowthStage: String, Codable, CaseIterable {
    case seed, sprout, growing, blooming, mature

    var icon: String {
        switch self {
        case .seed: "🌰"
        case .sprout: "🌱"
        case .growing: "🌿"
        case .blooming: "🌸"
        case .mature: "🌳"
        }
    }

    var labelEN: String {
        switch self {
        case .seed: "Seed"
        case .sprout: "Sprout"
        case .growing: "Growing"
        case .blooming: "Blooming"
        case .mature: "Mature"
        }
    }

    var stageIndex: Int {
        switch self {
        case .seed: 0
        case .sprout: 1
        case .growing: 2
        case .blooming: 3
        case .mature: 4
        }
    }
}

// MARK: - Plant Model

@Model
final class Plant {
    var id: String
    var name: String
    var speciesRaw: String
    var growthStageRaw: String
    var hydrationLevel: Int
    var experience: Int
    var lastWateredAt: Date?
    var createdAt: Date

    init(name: String = "My Plant", species: PlantSpecies = .sunflower) {
        self.id = UUID().uuidString
        self.name = name
        self.speciesRaw = species.rawValue
        self.growthStageRaw = GrowthStage.seed.rawValue
        self.hydrationLevel = 100
        self.experience = 0
        self.lastWateredAt = nil
        self.createdAt = Date()
    }

    var species: PlantSpecies {
        get { PlantSpecies(rawValue: speciesRaw) ?? .sunflower }
        set { speciesRaw = newValue.rawValue }
    }

    var growthStage: GrowthStage {
        get { GrowthStage(rawValue: growthStageRaw) ?? .seed }
        set { growthStageRaw = newValue.rawValue }
    }

    var hydrationDescription: String {
        switch hydrationLevel {
        case 75...100: "Well Watered"
        case 50..<75: "Adequate"
        case 25..<50: "Dry"
        default: "Critical"
        }
    }

    func water() {
        hydrationLevel = min(100, hydrationLevel + 40)
        lastWateredAt = Date()
        experience += 5

        // Stage advancement at 100 XP
        if experience >= 100 {
            experience = experience - 100
            switch growthStage {
            case .seed: growthStage = .sprout
            case .sprout: growthStage = .growing
            case .growing: growthStage = .blooming
            case .blooming: growthStage = .mature
            case .mature: break
            }
        }
    }

    func updateHydration() {
        guard let lastWatered = lastWateredAt else { return }
        let daysSinceWatering = Date().timeIntervalSince(lastWatered) / 86400
        hydrationLevel = max(0, hydrationLevel - Int(daysSinceWatering * 20))
    }
}
