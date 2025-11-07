//
//  Economy.swift
//  Treehole
//
//  Created by Kayli Cheung on 2025-11-06.
//

import Foundation

struct EconomyLedger: Codable {
    var food: Int = 0
    var decorationToken: Int = 0
    var gems: Int = 0 // Premium currency
    var lastUpdated: Date = Date()

    mutating func addFood(_ amount: Int) {
        food = max(0, food + amount)
        lastUpdated = Date()
    }

    mutating func addDecorToken(_ amount: Int) {
        decorationToken = max(0, decorationToken + amount)
        lastUpdated = Date()
    }

    mutating func removeFood(_ amount: Int) -> Bool {
        if food >= amount {
            food -= amount
            lastUpdated = Date()
            return true
        }
        return false
    }

    mutating func removeDecorToken(_ amount: Int) -> Bool {
        if decorationToken >= amount {
            decorationToken -= amount
            lastUpdated = Date()
            return true
        }
        return false
    }
}

struct InventoryItem: Codable, Identifiable {
    let id: String
    var type: ItemType
    var quantity: Int
    var rarity: Rarity
    var acquiredAt: Date

    enum ItemType: String, Codable {
        case food = "food"
        case decoration = "decoration"
        case clothing = "clothing"
        case consumable = "consumable"
    }

    enum Rarity: String, Codable {
        case common
        case uncommon
        case rare
        case legendary
    }
}

struct DailyTask: Codable, Identifiable {
    let id: String
    var title: String
    var description: String
    var taskType: TaskType
    var completed: Bool = false
    var completedAt: Date?
    var reward: TaskReward
    var dueDate: Date

    enum TaskType: String, Codable {
        case post = "post_cloud"
        case feed_pet = "feed_pet"
        case water_plant = "water_plant"
        case write_journal = "write_journal"
        case decorate = "decorate_home"
        case chat = "chat_with_pet"
    }

    var isExpired: Bool {
        Date() > dueDate
    }
}

struct TaskReward: Codable {
    var food: Int = 0
    var decorationToken: Int = 0
    var gems: Int = 0
    var petExperience: Int = 0
    var plantExperience: Int = 0
}

struct WeeklyChallenge: Codable, Identifiable {
    let id: String
    var title: String
    var description: String
    var targetCount: Int
    var currentCount: Int = 0
    var reward: TaskReward
    var startDate: Date
    var endDate: Date

    var progress: Double {
        Double(currentCount) / Double(targetCount)
    }

    var isCompleted: Bool {
        currentCount >= targetCount
    }
}
