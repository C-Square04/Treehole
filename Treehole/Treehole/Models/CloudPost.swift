import Foundation
import SwiftData

// MARK: - Shared Mood Tag (used by CloudPost and JournalEntry)

enum MoodTag: String, Codable, CaseIterable, Identifiable {
    // Original 8
    case happy, sad, angry, anxious, tired, confused, hopeful, calm
    // New 8
    case grateful, loved, excited, peaceful, lonely, melancholic, stressed, proud

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .happy: "😊"
        case .sad: "😢"
        case .angry: "😠"
        case .anxious: "😰"
        case .tired: "😴"
        case .confused: "😕"
        case .hopeful: "🌟"
        case .calm: "😌"
        case .grateful: "🥰"
        case .loved: "😍"
        case .excited: "🤩"
        case .peaceful: "☮️"
        case .lonely: "😞"
        case .melancholic: "💔"
        case .stressed: "😤"
        case .proud: "💪"
        }
    }

    var labelEN: String {
        switch self {
        case .happy: "Happy"
        case .sad: "Sad"
        case .angry: "Angry"
        case .anxious: "Anxious"
        case .tired: "Tired"
        case .confused: "Confused"
        case .hopeful: "Hopeful"
        case .calm: "Calm"
        case .grateful: "Grateful"
        case .loved: "Loved"
        case .excited: "Excited"
        case .peaceful: "Peaceful"
        case .lonely: "Lonely"
        case .melancholic: "Melancholic"
        case .stressed: "Stressed"
        case .proud: "Proud"
        }
    }

    var labelZH: String {
        switch self {
        case .happy: "开心"
        case .sad: "伤心"
        case .angry: "生气"
        case .anxious: "焦虑"
        case .tired: "疲惫"
        case .confused: "困惑"
        case .hopeful: "希望"
        case .calm: "平静"
        case .grateful: "感恩"
        case .loved: "被爱"
        case .excited: "兴奋"
        case .peaceful: "平和"
        case .lonely: "孤独"
        case .melancholic: "忧郁"
        case .stressed: "压力"
        case .proud: "自豪"
        }
    }
}

// MARK: - Mood Coordinates (Valence/Arousal model)

extension MoodTag {
    /// Valence: -1.0 (very negative) to +1.0 (very positive)
    var defaultValence: Double {
        switch self {
        case .happy:       0.7
        case .grateful:    0.6
        case .loved:       0.8
        case .excited:     0.8
        case .proud:       0.7
        case .peaceful:    0.5
        case .calm:        0.4
        case .hopeful:     0.5
        case .tired:      -0.2
        case .confused:   -0.3
        case .sad:        -0.7
        case .lonely:     -0.6
        case .melancholic: -0.5
        case .stressed:   -0.5
        case .anxious:    -0.5
        case .angry:      -0.7
        }
    }

    /// Arousal: 0.0 (very calm/low energy) to 1.0 (very energetic/high energy)
    var defaultArousal: Double {
        switch self {
        case .happy:       0.7
        case .grateful:    0.5
        case .loved:       0.5
        case .excited:     0.9
        case .proud:       0.6
        case .peaceful:    0.2
        case .calm:        0.25
        case .hopeful:     0.5
        case .tired:       0.1
        case .confused:    0.4
        case .sad:         0.3
        case .lonely:      0.25
        case .melancholic: 0.2
        case .stressed:    0.75
        case .anxious:     0.8
        case .angry:       0.85
        }
    }

    /// Find nearest MoodTag using Euclidean distance in valence/arousal space
    static func nearest(valence: Double, arousal: Double) -> MoodTag {
        MoodTag.allCases.min { a, b in
            let da = (a.defaultValence - valence) * (a.defaultValence - valence)
                   + (a.defaultArousal - arousal) * (a.defaultArousal - arousal)
            let db = (b.defaultValence - valence) * (b.defaultValence - valence)
                   + (b.defaultArousal - arousal) * (b.defaultArousal - arousal)
            return da < db
        } ?? .calm
    }
}

// MARK: - Cloud Post Model

@Model
final class CloudPost {
    var id: String = UUID().uuidString
    var authorAlias: String = ""
    var moodTagRaw: String = "calm"
    var text: String = ""
    var createdAt: Date = Date()
    var npcReplyText: String? = nil
    var sourceLanguage: String = "en"

    init() {}

    init(
        authorAlias: String,
        moodTag: MoodTag,
        text: String,
        npcReplyText: String? = nil,
        sourceLanguage: String = "en"
    ) {
        self.id = UUID().uuidString
        self.authorAlias = authorAlias
        self.moodTagRaw = moodTag.rawValue
        self.text = text
        self.createdAt = Date()
        self.npcReplyText = npcReplyText
        self.sourceLanguage = sourceLanguage
    }

    var moodTag: MoodTag {
        get { MoodTag(rawValue: moodTagRaw) ?? .calm }
        set { moodTagRaw = newValue.rawValue }
    }
}
