import Foundation
import SwiftData
import SwiftUI

// MARK: - Home Theme

enum HomeTheme: String, Codable, CaseIterable {
    case daylight, night, sunset, garden

    var labelEN: String {
        switch self {
        case .daylight: "Daylight"
        case .night: "Night"
        case .sunset: "Sunset"
        case .garden: "Garden"
        }
    }

    var labelZH: String {
        switch self {
        case .daylight: "白天"
        case .night: "夜晚"
        case .sunset: "日落"
        case .garden: "花园"
        }
    }

    var gradient: (Color, Color) {
        switch self {
        case .daylight:
            return (Color(red: 0.85, green: 0.92, blue: 0.98), Color(red: 1.0, green: 0.97, blue: 0.93))
        case .night:
            return (Color(red: 0.15, green: 0.18, blue: 0.35), Color(red: 0.22, green: 0.25, blue: 0.45))
        case .sunset:
            return (Color(red: 1.0, green: 0.75, blue: 0.55), Color(red: 0.95, green: 0.60, blue: 0.65))
        case .garden:
            return (Color(red: 0.75, green: 0.92, blue: 0.78), Color(red: 0.90, green: 0.96, blue: 0.92))
        }
    }
}

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

// MARK: - Pet Model

@Model
final class Pet {
    var id: String = UUID().uuidString
    var name: String = "Companion"
    var hungerLevel: Int = 80
    var moodRaw: String = "neutral"
    var lastFedAt: Date? = nil
    var lastHungerUpdateAt: Date? = nil
    var createdAt: Date = Date()

    // Phase 2: energy, level, XP, theme
    var energy: Int = 80
    var level: Int = 1
    var experience: Int = 0
    var nextLevelExp: Int = 100
    var homeThemeRaw: String = "daylight"

    init() {}

    init(name: String) {
        self.id = UUID().uuidString
        self.name = name
        self.hungerLevel = 80
        self.moodRaw = PetMood.neutral.rawValue
        self.lastFedAt = nil
        self.createdAt = Date()
        self.energy = 80
        self.level = 1
        self.experience = 0
        self.nextLevelExp = 100
        self.homeThemeRaw = HomeTheme.daylight.rawValue
    }

    var mood: PetMood {
        get { PetMood(rawValue: moodRaw) ?? .neutral }
        set { moodRaw = newValue.rawValue }
    }

    var homeTheme: HomeTheme {
        get { HomeTheme(rawValue: homeThemeRaw) ?? .daylight }
        set { homeThemeRaw = newValue.rawValue }
    }

    var hungerDescription: String {
        switch hungerLevel {
        case 75...100: L10n.t("Satisfied", "吃饱了")
        case 50..<75: L10n.t("Content", "还不错")
        case 25..<50: L10n.t("Hungry", "饿了")
        default: L10n.t("Starving", "饿坏了")
        }
    }

    func feed() {
        hungerLevel = min(100, hungerLevel + 30)
        energy = min(100, energy + 20)
        lastFedAt = Date()
        mood = .happy
        addExperience(10)
    }

    func updateHunger(now: Date = Date()) {
        // Hunger decays 1 point per whole hour since the last checkpoint
        let referenceDate = lastHungerUpdateAt ?? lastFedAt ?? createdAt
        let decay = Int(now.timeIntervalSince(referenceDate) / 3600)
        guard decay >= 1 else { return }  // Sub-hour remainder keeps accruing toward the next point
        hungerLevel = max(0, hungerLevel - decay)
        // Advance the checkpoint only by the hours consumed so frequent checks don't drop decay
        lastHungerUpdateAt = referenceDate.addingTimeInterval(Double(decay) * 3600)
        if hungerLevel < 25 { mood = .sad }
    }

    func rest() {
        energy = min(100, energy + 40)
        mood = .happy
    }

    func pet() {
        energy = min(100, energy + 10)
        mood = .happy
    }

    func addExperience(_ amount: Int) {
        experience += amount
        if experience >= nextLevelExp {
            experience -= nextLevelExp
            level += 1
            nextLevelExp = Int(Double(nextLevelExp) * 1.2)
            mood = .excited
        }
    }
}
