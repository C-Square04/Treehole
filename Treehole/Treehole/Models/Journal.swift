//
//  Journal.swift
//  Treehole
//
//  Created by Kayli Cheung on 2025-11-06.
//

import Foundation

struct JournalEntry: Codable, Identifiable {
    let id: String
    var createdAt: Date
    var mood: CloudPost.MoodTag
    var text: String
    var rewardGranted: Bool = false
    var foodReward: Int = 10
    var decorTokenReward: Int = 5
    var expReward: Int = 20

    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: createdAt)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
}

struct JournalPrompt: Codable, Identifiable {
    let id: String
    var text: String
    var category: String
    var language: CloudPost.Language

    static let defaultPrompts = [
        JournalPrompt(id: "1", text: "今天最开心的时刻是什么?", category: "reflection", language: .simplifiedChinese),
        JournalPrompt(id: "2", text: "你今天学到了什么?", category: "learning", language: .simplifiedChinese),
        JournalPrompt(id: "3", text: "What was your proudest moment today?", category: "reflection", language: .english),
        JournalPrompt(id: "4", text: "What are you grateful for today?", category: "gratitude", language: .english),
    ]
}
