import Foundation
import SwiftData

// MARK: - Shared Mood Tag (used by CloudPost and JournalEntry)

enum MoodTag: String, Codable, CaseIterable, Identifiable {
    case happy, sad, angry, anxious, tired, confused, hopeful, calm

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
        }
    }
}

// MARK: - Cloud Post Model

@Model
final class CloudPost {
    var id: String
    var authorAlias: String
    var moodTagRaw: String
    var text: String
    var createdAt: Date
    var npcReplyText: String?
    var sourceLanguage: String

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
