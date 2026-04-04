import Foundation
import SwiftData

// MARK: - Pet Mood

enum PetMood: String, Codable, CaseIterable {
    case happy, neutral, sad, excited, tired

    var emoji: String {
        switch self {
        case .happy: "😊"
        case .neutral: "😐"
        case .sad: "😢"
        case .excited: "🤩"
        case .tired: "😴"
        }
    }

    var labelEN: String {
        switch self {
        case .happy: "Happy"
        case .neutral: "Neutral"
        case .sad: "Sad"
        case .excited: "Excited"
        case .tired: "Tired"
        }
    }

    var labelZH: String {
        switch self {
        case .happy: "开心"
        case .neutral: "平静"
        case .sad: "伤心"
        case .excited: "兴奋"
        case .tired: "疲惫"
        }
    }
}

// MARK: - Pet Model (MVP: hunger + mood only)

@Model
final class Pet {
    var id: String
    var name: String
    var hungerLevel: Int
    var moodRaw: String
    var lastFedAt: Date?
    var createdAt: Date

    init(name: String = "Companion") {
        self.id = UUID().uuidString
        self.name = name
        self.hungerLevel = 80
        self.moodRaw = PetMood.neutral.rawValue
        self.lastFedAt = nil
        self.createdAt = Date()
    }

    var mood: PetMood {
        get { PetMood(rawValue: moodRaw) ?? .neutral }
        set { moodRaw = newValue.rawValue }
    }

    var hungerDescription: String {
        switch hungerLevel {
        case 75...100: "Satisfied"
        case 50..<75: "Content"
        case 25..<50: "Hungry"
        default: "Starving"
        }
    }

    func feed() {
        hungerLevel = min(100, hungerLevel + 30)
        lastFedAt = Date()
        mood = .happy
    }

    func updateHunger() {
        guard let lastFed = lastFedAt else { return }
        let hoursSinceFeeding = Date().timeIntervalSince(lastFed) / 3600
        hungerLevel = max(0, hungerLevel - Int(hoursSinceFeeding))
        if hungerLevel < 25 {
            mood = .sad
        }
    }
}
