//
//  CloudPost.swift
//  Treehole
//
//  Created by Kayli Cheung on 2025-11-06.
//

import Foundation

struct CloudPost: Codable, Identifiable {
    let id: String
    var authorAlias: String
    var moodTag: MoodTag
    var text: String
    var createdAt: Date
    var npcReplyId: String?
    var npcReplyText: String?
    var visibilityState: VisibilityState
    var sourceLanguage: Language
    var translations: [Language: TranslationData] = [:]
    var isPublic: Bool = false

    enum MoodTag: String, Codable, CaseIterable {
        case happy = "😊"
        case sad = "😢"
        case angry = "😠"
        case anxious = "😰"
        case tired = "😴"
        case confused = "😕"
        case hopeful = "🌟"
        case calm = "😌"

        var description: String {
            switch self {
            case .happy:
                return "Happy"
            case .sad:
                return "Sad"
            case .angry:
                return "Angry"
            case .anxious:
                return "Anxious"
            case .tired:
                return "Tired"
            case .confused:
                return "Confused"
            case .hopeful:
                return "Hopeful"
            case .calm:
                return "Calm"
            }
        }

        var localizedDescription: String {
            switch self {
            case .happy:
                return "开心"
            case .sad:
                return "伤心"
            case .angry:
                return "生气"
            case .anxious:
                return "焦虑"
            case .tired:
                return "疲惫"
            case .confused:
                return "困惑"
            case .hopeful:
                return "希望"
            case .calm:
                return "平静"
            }
        }
    }

    enum VisibilityState: String, Codable {
        case onlyMe = "private"
        case friendsOnly = "friends_only"
        case visible = "public"
    }

    enum Language: String, Codable {
        case simplifiedChinese = "zh-Hans"
        case english = "en"
    }
}

struct TranslationData: Codable {
    var text: String
    var updatedAt: Date
}

struct NPCReply: Codable, Identifiable {
    let id: String
    var moodCategory: String
    var replyTemplate: String
    var emotionalMirror: String
    var suggestion: String
    var createdAt: Date
}
