import Foundation

// Mirror of the app's WidgetSnapshot (Utilities/WidgetStateStore.swift) —
// the widget extension can't see app-target sources, so the model is
// duplicated here. KEEP FIELDS IN SYNC with the app side (v: 1).

struct WidgetSnapshot: Codable {
    var v: Int = 1
    var updatedAt: Date
    var petName: String
    var moodRaw: String
    var hungerLevel: Int
    var energy: Int
    var level: Int
    var lastFedAt: Date?
    var lastHungerUpdateAt: Date?
    var petCreatedAt: Date
    var plantCount: Int
    var plantTopStageRaw: String
    var plantTopName: String
    var tasksDone: Int
    var tasksTotal: Int
    var unreadCount: Int
    var language: String
}

extension WidgetSnapshot {
    /// Shown when the app hasn't pushed a snapshot yet (fresh install).
    static let fallback = WidgetSnapshot(
        updatedAt: Date(),
        petName: "Companion", moodRaw: "neutral",
        hungerLevel: 80, energy: 80, level: 1,
        lastFedAt: nil, lastHungerUpdateAt: nil, petCreatedAt: Date(),
        plantCount: 0, plantTopStageRaw: "seed", plantTopName: "",
        tasksDone: 0, tasksTotal: 4, unreadCount: 0, language: "en"
    )

    /// Hunger mirrors Pet.updateHunger: -1 point per whole hour since the
    /// last checkpoint — the widget looks alive between app launches.
    func hunger(at now: Date) -> Int {
        let reference = lastHungerUpdateAt ?? lastFedAt ?? petCreatedAt
        let decay = Int(now.timeIntervalSince(reference) / 3600)
        return max(0, hungerLevel - max(0, decay))
    }

    /// Displayed mood: asleep overnight (23:00–7:00), sad when the mirrored
    /// hunger fell below 25, otherwise the mood the app last reported.
    func mood(at now: Date) -> String {
        let hour = Calendar.current.component(.hour, from: now)
        if hour >= 23 || hour < 7 { return "tired" }
        if hunger(at: now) < 25 { return "sad" }
        return moodRaw
    }

    func moodEmoji(at now: Date) -> String {
        switch mood(at: now) {
        case "happy": return "😊"
        case "sad": return "😢"
        case "excited": return "🤩"
        case "tired": return "😴"
        default: return "😐"
        }
    }

    var stageEmoji: String {
        switch plantTopStageRaw {
        case "sprout": return "🌿"
        case "growing": return "🪴"
        case "blooming": return "🌸"
        case "mature": return "🌳"
        default: return "🌱"
        }
    }
}
