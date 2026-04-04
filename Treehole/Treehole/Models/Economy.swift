import Foundation
import SwiftData

// MARK: - TaskType

enum TaskType: String, Codable, CaseIterable {
    case post
    case feedPet
    case waterPlant
    case writeJournal

    var title: String {
        switch self {
        case .post: "Share a Cloud"
        case .feedPet: "Feed Your Pet"
        case .waterPlant: "Water Your Plant"
        case .writeJournal: "Write in Journal"
        }
    }

    var foodReward: Int {
        switch self {
        case .post: 5
        case .feedPet: 3
        case .waterPlant: 3
        case .writeJournal: 5
        }
    }

    var tokenReward: Int {
        switch self {
        case .post: 0
        case .feedPet: 0
        case .waterPlant: 1
        case .writeJournal: 2
        }
    }
}

// MARK: - Economy Model

@Model
final class Economy {
    var id: String
    var food: Int
    var decorationTokens: Int
    var gems: Int
    var loginStreak: Int
    var lastLoginDate: Date?
    var lastDailyResetDate: Date?

    init() {
        self.id = UUID().uuidString
        self.food = 50
        self.decorationTokens = 10
        self.gems = 0
        self.loginStreak = 0
        self.lastLoginDate = nil
        self.lastDailyResetDate = nil
    }

    func addFood(_ amount: Int) {
        food = min(9999, max(0, food + amount))
    }

    func spendFood(_ amount: Int) -> Bool {
        guard food >= amount else { return false }
        food -= amount
        return true
    }

    func addTokens(_ amount: Int) {
        decorationTokens += amount
    }

    func spendTokens(_ amount: Int) -> Bool {
        guard decorationTokens >= amount else { return false }
        decorationTokens -= amount
        return true
    }

    func checkLoginStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        guard let lastLogin = lastLoginDate else {
            // First login
            loginStreak = 1
            lastLoginDate = today
            return
        }

        let lastLoginDay = calendar.startOfDay(for: lastLogin)

        if calendar.isDate(lastLoginDay, inSameDayAs: today) {
            // Already logged in today — do nothing
            return
        }

        if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
           calendar.isDate(lastLoginDay, inSameDayAs: yesterday) {
            // Last login was yesterday — increment streak
            loginStreak += 1
        } else {
            // Streak broken — reset to 1
            loginStreak = 1
        }

        lastLoginDate = today
    }

    func grantLoginBonus() {
        let bonus = min(25, 5 + loginStreak * 2)
        addFood(bonus)
    }
}

// MARK: - DailyTask Model

@Model
final class DailyTask {
    var id: String
    var title: String
    var taskDescription: String
    var typeRaw: String
    var isCompleted: Bool
    var foodReward: Int
    var tokenReward: Int
    var createdAt: Date

    init(type: TaskType) {
        self.id = UUID().uuidString
        self.title = type.title
        self.taskDescription = type.title
        self.typeRaw = type.rawValue
        self.isCompleted = false
        self.foodReward = type.foodReward
        self.tokenReward = type.tokenReward
        self.createdAt = Date()
    }

    var type: TaskType {
        get { TaskType(rawValue: typeRaw) ?? .post }
        set { typeRaw = newValue.rawValue }
    }
}
