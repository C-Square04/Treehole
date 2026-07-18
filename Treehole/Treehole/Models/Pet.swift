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

    private static func themed(_ light: (Double, Double, Double), _ dark: (Double, Double, Double)) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: dark.0, green: dark.1, blue: dark.2, alpha: 1)
                : UIColor(red: light.0, green: light.1, blue: light.2, alpha: 1)
        })
    }

    /// Theme gradient — adaptive dark variants so the pet's name and stats
    /// stay readable when the system is in dark mode.
    var gradient: (Color, Color) {
        switch self {
        case .daylight:
            return (Self.themed((0.85, 0.92, 0.98), (0.11, 0.17, 0.25)),
                    Self.themed((1.0, 0.97, 0.93), (0.13, 0.11, 0.09)))
        case .night:
            return (Self.themed((0.15, 0.18, 0.35), (0.09, 0.11, 0.24)),
                    Self.themed((0.22, 0.25, 0.45), (0.14, 0.16, 0.32)))
        case .sunset:
            return (Self.themed((1.0, 0.75, 0.55), (0.35, 0.20, 0.14)),
                    Self.themed((0.95, 0.60, 0.65), (0.30, 0.16, 0.20)))
        case .garden:
            return (Self.themed((0.75, 0.92, 0.78), (0.12, 0.22, 0.15)),
                    Self.themed((0.90, 0.96, 0.92), (0.13, 0.15, 0.11)))
        }
    }

    /// Primary text color on this theme's gradient. Night is dark in BOTH
    /// schemes, so it always takes a light color; the others take dark brown.
    var textColor: Color {
        switch self {
        case .night: Color(red: 0.93, green: 0.91, blue: 0.89)
        default: Color(red: 0.25, green: 0.22, blue: 0.20)
        }
    }

    /// Secondary text color on this theme's gradient.
    var secondaryTextColor: Color {
        switch self {
        case .night: Color(red: 0.72, green: 0.70, blue: 0.76)
        default: Color(red: 0.45, green: 0.40, blue: 0.37)
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
