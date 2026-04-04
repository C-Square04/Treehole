import Foundation
import SwiftData

// MARK: - ChallengeType

enum ChallengeType: String, Codable, CaseIterable {
    case postStreak
    case waterStreak
    case journalStreak
    case feedStreak

    var title: String {
        switch self {
        case .postStreak:   return "Post 5 Clouds This Week"
        case .waterStreak:  return "Water Plants Every Day"
        case .journalStreak: return "Write 3 Journal Entries"
        case .feedStreak:   return "Feed Your Pet 10 Times"
        }
    }

    var titleZH: String {
        switch self {
        case .postStreak:   return "本周发布5朵云"
        case .waterStreak:  return "每天浇水一次"
        case .journalStreak: return "写3篇日记"
        case .feedStreak:   return "喂食宠物10次"
        }
    }

    var targetCount: Int {
        switch self {
        case .postStreak:   return 5
        case .waterStreak:  return 7
        case .journalStreak: return 3
        case .feedStreak:   return 10
        }
    }

    var foodReward: Int {
        switch self {
        case .postStreak:   return 20
        case .waterStreak:  return 25
        case .journalStreak: return 15
        case .feedStreak:   return 30
        }
    }

    var tokenReward: Int {
        switch self {
        case .postStreak:   return 2
        case .waterStreak:  return 3
        case .journalStreak: return 2
        case .feedStreak:   return 3
        }
    }

    var icon: String {
        switch self {
        case .postStreak:   return "cloud.fill"
        case .waterStreak:  return "drop.fill"
        case .journalStreak: return "book.fill"
        case .feedStreak:   return "cup.and.saucer.fill"
        }
    }

    var color: String {
        switch self {
        case .postStreak:   return "skyBlue"
        case .waterStreak:  return "mintCream"
        case .journalStreak: return "gentleLavender"
        case .feedStreak:   return "warmPeach"
        }
    }
}

// MARK: - WeeklyChallenge Model

@Model
final class WeeklyChallenge {
    var id: String
    var typeRaw: String
    var currentCount: Int
    var isCompleted: Bool
    var weekStartDate: Date
    var createdAt: Date

    init(type: ChallengeType, weekStartDate: Date) {
        self.id = UUID().uuidString
        self.typeRaw = type.rawValue
        self.currentCount = 0
        self.isCompleted = false
        self.weekStartDate = weekStartDate
        self.createdAt = Date()
    }

    var type: ChallengeType {
        get { ChallengeType(rawValue: typeRaw) ?? .postStreak }
        set { typeRaw = newValue.rawValue }
    }

    var progress: Double {
        guard type.targetCount > 0 else { return 0 }
        return min(1.0, Double(currentCount) / Double(type.targetCount))
    }
}
