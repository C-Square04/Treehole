//
//  EconomyViewModel.swift
//  Treehole
//
//  Created by Kayli Cheung & Jimmy Chen on 2025-11-06.
//

import Foundation
import Combine

class EconomyViewModel: ObservableObject {
    @Published var economy: EconomyLedger = EconomyLedger()
    @Published var dailyTasks: [DailyTask] = []
    @Published var weeklyChallenges: [WeeklyChallenge] = []
    @Published var inventory: [InventoryItem] = []
    @Published var loginStreak: Int = 0
    @Published var lastLoginDate: Date?
    @Published var achievements: [String: Bool] = [:]

    init() {
        loadEconomy()
        loadDailyTasks()
        loadWeeklyChallenges()
        loadInventory()
        loadAchievements()
        loadLoginStreak()
        checkLoginStreak()
    }

    // MARK: - Economy Management

    func addFood(_ amount: Int) {
        economy.addFood(amount)
        saveEconomy()
    }

    func addDecorToken(_ amount: Int) {
        economy.addDecorToken(amount)
        saveEconomy()
        objectWillChange.send()
    }

    func spendFood(_ amount: Int) -> Bool {
        if economy.removeFood(amount) {
            saveEconomy()
            return true
        }
        return false
    }

    func spendDecorToken(_ amount: Int) -> Bool {
        if economy.removeDecorToken(amount) {
            saveEconomy()
            return true
        }
        return false
    }

    // MARK: - Task Management

    func createDailyTask(title: String, description: String, type: DailyTask.TaskType, reward: TaskReward) {
        let dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let task = DailyTask(
            id: UUID().uuidString,
            title: title,
            description: description,
            taskType: type,
            reward: reward,
            dueDate: dueDate
        )
        dailyTasks.append(task)
        saveDailyTasks()
    }

    func completeDailyTask(_ taskId: String) {
        guard let index = dailyTasks.firstIndex(where: { $0.id == taskId }) else {
            return
        }

        if !dailyTasks[index].completed {
            dailyTasks[index].completed = true
            dailyTasks[index].completedAt = Date()

            let reward = dailyTasks[index].reward
            if reward.food > 0 {
                addFood(reward.food)
            }
            if reward.decorationToken > 0 {
                addDecorToken(reward.decorationToken)
            }

            saveDailyTasks()
            objectWillChange.send()
        }
    }

    func resetDailyTasks() {
        dailyTasks = dailyTasks.filter { !$0.isExpired }
        saveDailyTasks()
    }

    // MARK: - Challenge Management

    func createWeeklyChallenge(title: String, description: String, targetCount: Int, reward: TaskReward) {
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        let challenge = WeeklyChallenge(
            id: UUID().uuidString,
            title: title,
            description: description,
            targetCount: targetCount,
            reward: reward,
            startDate: Date(),
            endDate: endDate
        )
        weeklyChallenges.append(challenge)
        saveWeeklyChallenges()
    }

    func incrementChallengeProgress(_ challengeId: String) {
        guard let index = weeklyChallenges.firstIndex(where: { $0.id == challengeId }) else {
            return
        }

        if !weeklyChallenges[index].isCompleted {
            weeklyChallenges[index].currentCount += 1

            if weeklyChallenges[index].isCompleted {
                let reward = weeklyChallenges[index].reward
                if reward.food > 0 {
                    addFood(reward.food)
                }
                if reward.decorationToken > 0 {
                    addDecorToken(reward.decorationToken)
                }
            }

            saveWeeklyChallenges()
            objectWillChange.send()
        }
    }

    // MARK: - Streak & Bonus Management

    func checkLoginStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastLogin = lastLoginDate {
            let lastLoginDay = calendar.startOfDay(for: lastLogin)
            let dayDifference = calendar.dateComponents([.day], from: lastLoginDay, to: today).day ?? 0

            if dayDifference == 1 {
                // Consecutive day - increment streak
                loginStreak += 1
            } else if dayDifference > 1 {
                // Streak broken - reset
                loginStreak = 1
            }
            // If dayDifference == 0, it's the same day, no change
        } else {
            loginStreak = 1
        }

        lastLoginDate = Date()
        saveLoginStreak()

        // Give login bonus
        grantLoginBonus()
    }

    private func grantLoginBonus() {
        let baseBonus = 5
        let streakBonus = min(loginStreak * 2, 25) // Max 25 bonus stars for 7+ day streak
        let totalBonus = baseBonus + streakBonus

        addDecorToken(totalBonus)
    }

    // MARK: - Achievement & Action Rewards

    func grantPostSupportReward(_ supportCount: Int) {
        // Reward users for getting support (likes/comments) on posts
        let reward = min(supportCount * 3, 50) // Max 50 stars per post
        if reward > 0 {
            addDecorToken(reward)
            if !achievements.keys.contains("cloud_popular") && supportCount >= 5 {
                unlockAchievement("cloud_popular", stars: 25)
            }
        }
    }

    func grantMilestoneReward(_ milestone: String) {
        // Reward for reaching milestones
        let rewards = [
            "cloud_posts_10": 20,
            "cloud_posts_25": 50,
            "cloud_posts_50": 100,
            "journal_entries_5": 20,
            "journal_entries_10": 40,
            "plant_level_5": 30,
            "pet_level_10": 40,
            "decorations_5": 25,
            "decorations_10": 50,
        ]

        if let starReward = rewards[milestone] {
            addDecorToken(starReward)
        }
    }

    func grantPetInteractionReward() {
        // Reward for petting, playing with pet
        addDecorToken(2)
    }

    func grantConsecutiveActionReward(_ action: String, count: Int) {
        // Reward for consecutive actions (e.g., water plant 3 days in a row)
        if count % 3 == 0 && count > 0 {
            let reward = min(count / 3 * 5, 25)
            addDecorToken(reward)
        }
    }

    func grantCollectionBonus(_ collectionType: String) {
        // Bonus for collecting multiple items
        let bonuses = [
            "plant_species_all": 50,
            "pet_skin_5": 40,
            "decoration_set_complete": 60,
        ]

        if let bonus = bonuses[collectionType] {
            addDecorToken(bonus)
        }
    }

    func unlockAchievement(_ achievementId: String, stars: Int) {
        guard achievements[achievementId] != true else { return }

        achievements[achievementId] = true
        addDecorToken(stars)
        saveAchievements()
        objectWillChange.send()
    }

    var totalStarsEarned: Int {
        economy.decorationToken
    }

    var statsThisWeek: (posts: Int, plants: Int, journals: Int) {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let postsThisWeek = dailyTasks.filter { $0.taskType == .post && $0.completed && ($0.completedAt ?? Date()) > weekAgo }.count
        let plantsThisWeek = dailyTasks.filter { $0.taskType == .water_plant && $0.completed && ($0.completedAt ?? Date()) > weekAgo }.count
        let journalsThisWeek = dailyTasks.filter { $0.taskType == .write_journal && $0.completed && ($0.completedAt ?? Date()) > weekAgo }.count
        return (postsThisWeek, plantsThisWeek, journalsThisWeek)
    }

    // MARK: - Inventory Management

    func addInventoryItem(_ item: InventoryItem) {
        if let index = inventory.firstIndex(where: { $0.id == item.id }) {
            inventory[index].quantity += item.quantity
        } else {
            inventory.append(item)
        }
        saveInventory()
    }

    func removeInventoryItem(_ itemId: String, quantity: Int = 1) -> Bool {
        guard let index = inventory.firstIndex(where: { $0.id == itemId }) else {
            return false
        }

        if inventory[index].quantity >= quantity {
            inventory[index].quantity -= quantity
            if inventory[index].quantity == 0 {
                inventory.remove(at: index)
            }
            saveInventory()
            return true
        }
        return false
    }

    // MARK: - Statistics

    var completedTasksToday: Int {
        let calendar = Calendar.current
        return dailyTasks.filter {
            if let completedAt = $0.completedAt {
                return calendar.isDateInToday(completedAt)
            }
            return false
        }.count
    }

    var pendingTasks: [DailyTask] {
        dailyTasks.filter { !$0.completed && !$0.isExpired }
    }

    var completedChallenges: [WeeklyChallenge] {
        weeklyChallenges.filter { $0.isCompleted }
    }

    var totalRewardedFood: Int {
        dailyTasks.filter { $0.completed }.reduce(0) { $0 + $1.reward.food }
    }

    // MARK: - Persistence

    func saveEconomy() {
        if let encoded = try? JSONEncoder().encode(economy) {
            UserDefaults.standard.set(encoded, forKey: "economy")
        }
    }

    private func loadEconomy() {
        if let data = UserDefaults.standard.data(forKey: "economy"),
           let loaded = try? JSONDecoder().decode(EconomyLedger.self, from: data) {
            economy = loaded
        }
    }

    private func saveDailyTasks() {
        if let encoded = try? JSONEncoder().encode(dailyTasks) {
            UserDefaults.standard.set(encoded, forKey: "dailyTasks")
        }
    }

    private func loadDailyTasks() {
        if let data = UserDefaults.standard.data(forKey: "dailyTasks"),
           let loaded = try? JSONDecoder().decode([DailyTask].self, from: data) {
            dailyTasks = loaded
        } else {
            // Create default daily tasks for Milestone 2
            createDefaultDailyTasks()
        }
    }

    private func saveWeeklyChallenges() {
        if let encoded = try? JSONEncoder().encode(weeklyChallenges) {
            UserDefaults.standard.set(encoded, forKey: "weeklyChallenges")
        }
    }

    private func loadWeeklyChallenges() {
        if let data = UserDefaults.standard.data(forKey: "weeklyChallenges"),
           let loaded = try? JSONDecoder().decode([WeeklyChallenge].self, from: data) {
            weeklyChallenges = loaded
        } else {
            createDefaultWeeklyChallenges()
        }
    }

    private func saveInventory() {
        if let encoded = try? JSONEncoder().encode(inventory) {
            UserDefaults.standard.set(encoded, forKey: "inventory")
        }
    }

    private func loadInventory() {
        if let data = UserDefaults.standard.data(forKey: "inventory"),
           let loaded = try? JSONDecoder().decode([InventoryItem].self, from: data) {
            inventory = loaded
        }
    }

    private func saveLoginStreak() {
        let streakData = ["streak": loginStreak, "lastLogin": lastLoginDate?.timeIntervalSince1970 ?? 0] as [String: Any]
        UserDefaults.standard.set(streakData, forKey: "loginStreak")
    }

    private func loadLoginStreak() {
        if let streakData = UserDefaults.standard.dictionary(forKey: "loginStreak") {
            loginStreak = streakData["streak"] as? Int ?? 0
            if let timestamp = streakData["lastLogin"] as? Double, timestamp > 0 {
                lastLoginDate = Date(timeIntervalSince1970: timestamp)
            }
        }
    }

    private func saveAchievements() {
        if let encoded = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(encoded, forKey: "achievements")
        }
    }

    private func loadAchievements() {
        if let data = UserDefaults.standard.data(forKey: "achievements"),
           let loaded = try? JSONDecoder().decode([String: Bool].self, from: data) {
            achievements = loaded
        }
    }

    // MARK: - Default Data

    private func createDefaultDailyTasks() {
        let tasksToCreate = [
            ("Post a Cloud", "Share your thoughts in the cloud", DailyTask.TaskType.post, TaskReward(food: 10, decorationToken: 8)),
            ("Feed Your Pet", "Keep your pet happy and healthy", DailyTask.TaskType.feed_pet, TaskReward(food: 15, decorationToken: 5)),
            ("Water Your Plant", "Help your plant grow stronger", DailyTask.TaskType.water_plant, TaskReward(food: 5, decorationToken: 12)),
            ("Write in Journal", "Reflect on your feelings and day", DailyTask.TaskType.write_journal, TaskReward(food: 10, decorationToken: 10)),
            ("Chat with Pet", "Have a friendly chat with your companion", DailyTask.TaskType.chat, TaskReward(food: 5, decorationToken: 7)),
            ("Decorate Home", "Make your pet's home cozy", DailyTask.TaskType.decorate, TaskReward(food: 8, decorationToken: 15)),
        ]

        for (title, description, type, reward) in tasksToCreate {
            createDailyTask(title: title, description: description, type: type, reward: reward)
        }
    }

    func addDailyTasks() {
        let additionalTasks = [
            ("Check In", "Start your day with a warm check-in", DailyTask.TaskType.post, TaskReward(food: 5, decorationToken: 3)),
            ("Plant Love", "Water multiple plants if you have them", DailyTask.TaskType.water_plant, TaskReward(food: 8, decorationToken: 18)),
            ("Pet Cuddles", "Spend time with your pet", DailyTask.TaskType.feed_pet, TaskReward(food: 12, decorationToken: 8)),
            ("Mood Check", "Record your feelings in the journal", DailyTask.TaskType.write_journal, TaskReward(food: 7, decorationToken: 9)),
            ("Home Sweet Home", "Decorate and care for your space", DailyTask.TaskType.decorate, TaskReward(food: 10, decorationToken: 20)),
            ("Quality Time", "Chat and bond with your pet", DailyTask.TaskType.chat, TaskReward(food: 6, decorationToken: 6)),
            ("Mindful Moment", "Write a reflection in your journal", DailyTask.TaskType.write_journal, TaskReward(food: 8, decorationToken: 8)),
            ("Social Butterfly", "Share more posts with the community", DailyTask.TaskType.post, TaskReward(food: 12, decorationToken: 10)),
        ]

        for (title, description, type, reward) in additionalTasks {
            createDailyTask(title: title, description: description, type: type, reward: reward)
        }
    }

    private func createDefaultWeeklyChallenges() {
        let challenges = [
            ("Cloud Talker", "Post 7 clouds this week", 7, TaskReward(food: 50, decorationToken: 35)),
            ("Caring Pet Owner", "Feed your pet 7 times this week", 7, TaskReward(food: 40, decorationToken: 40)),
            ("Green Thumb", "Water your plant 7 times this week", 7, TaskReward(food: 30, decorationToken: 50)),
            ("Journaling Soul", "Write 5 journal entries this week", 5, TaskReward(food: 25, decorationToken: 45)),
            ("Pet Whisperer", "Chat with your pet 5 times this week", 5, TaskReward(food: 20, decorationToken: 30)),
            ("Interior Designer", "Decorate your home 5 times this week", 5, TaskReward(food: 30, decorationToken: 60)),
            ("Wellness Master", "Complete all daily tasks 5 days this week", 5, TaskReward(food: 60, decorationToken: 80)),
        ]

        for (title, description, target, reward) in challenges {
            createWeeklyChallenge(title: title, description: description, targetCount: target, reward: reward)
        }
    }
}
