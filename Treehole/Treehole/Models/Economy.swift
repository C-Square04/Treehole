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

    var titleZH: String {
        switch self {
        case .post: "分享一朵云"
        case .feedPet: "喂养宠物"
        case .waterPlant: "给植物浇水"
        case .writeJournal: "写日记"
        }
    }

    var localizedTitle: String {
        L10n.t(title, titleZH)
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
    var id: String = UUID().uuidString
    var food: Int = 50
    var decorationTokens: Int = 10
    var gems: Int = 0
    var loginStreak: Int = 0
    var lastLoginDate: Date? = nil
    var lastDailyResetDate: Date? = nil
    // CloudKit requires an inline default on new @Model properties
    var lastBonusClaimDate: Date? = nil

    init() {}

    func addFood(_ amount: Int) {
        guard amount > 0 else { return }
        food = min(9999, food + amount)
    }

    func spendFood(_ amount: Int) -> Bool {
        guard amount > 0, food >= amount else { return false }
        food -= amount
        return true
    }

    func addTokens(_ amount: Int) {
        guard amount > 0 else { return }
        decorationTokens = min(9999, decorationTokens + amount)
    }

    func spendTokens(_ amount: Int) -> Bool {
        guard amount > 0, decorationTokens >= amount else { return false }
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

    var hasClaimedLoginBonusToday: Bool {
        guard let claimed = lastBonusClaimDate else { return false }
        return Calendar.current.isDateInToday(claimed)
    }

    /// At most one grant per calendar day — the claim date is persisted so
    /// relaunching the app (or recreating the view) cannot re-grant it.
    @discardableResult
    func grantLoginBonus() -> Bool {
        guard !hasClaimedLoginBonusToday else { return false }
        let bonus = min(25, 5 + loginStreak * 2)
        addFood(bonus)
        lastBonusClaimDate = Date()
        return true
    }
}

// MARK: - DailyTask Model

@Model
final class DailyTask {
    var id: String = UUID().uuidString
    var title: String = ""
    var taskDescription: String = ""
    var typeRaw: String = "post"
    var isCompleted: Bool = false
    var foodReward: Int = 0
    var tokenReward: Int = 0
    var createdAt: Date = Date()

    init() {}

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

    /// Display title derived from the task type at render time — the persisted
    /// `title` is English-only and kept for identity/back-compat.
    var localizedTitle: String {
        type.localizedTitle
    }
}
