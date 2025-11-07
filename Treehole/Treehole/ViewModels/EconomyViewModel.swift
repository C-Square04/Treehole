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

    init() {
        loadEconomy()
        loadDailyTasks()
        loadWeeklyChallenges()
        loadInventory()
    }

    // MARK: - Economy Management

    func addFood(_ amount: Int) {
        economy.addFood(amount)
        saveEconomy()
    }

    func addDecorToken(_ amount: Int) {
        economy.addDecorToken(amount)
        saveEconomy()
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
        }
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

    // MARK: - Default Data

    private func createDefaultDailyTasks() {
        let tasksToCreate = [
            ("Post a Cloud", "Share your thoughts in the cloud", DailyTask.TaskType.post, TaskReward(food: 10, decorationToken: 5)),
            ("Feed Your Pet", "Keep your pet happy", DailyTask.TaskType.feed_pet, TaskReward(food: 15, decorationToken: 0)),
            ("Water Your Plant", "Help your plant grow", DailyTask.TaskType.water_plant, TaskReward(food: 5, decorationToken: 10)),
            ("Write in Journal", "Reflect on your day", DailyTask.TaskType.write_journal, TaskReward(food: 10, decorationToken: 10)),
        ]

        for (title, description, type, reward) in tasksToCreate {
            createDailyTask(title: title, description: description, type: type, reward: reward)
        }
    }

    private func createDefaultWeeklyChallenges() {
        let challenges = [
            ("Cloud Talker", "Post 7 clouds this week", 7, TaskReward(food: 50, decorationToken: 30)),
            ("Caring Pet Owner", "Feed your pet 7 times this week", 7, TaskReward(food: 40, decorationToken: 40)),
            ("Gardener", "Water your plant 7 times this week", 7, TaskReward(food: 30, decorationToken: 50)),
        ]

        for (title, description, target, reward) in challenges {
            createWeeklyChallenge(title: title, description: description, targetCount: target, reward: reward)
        }
    }
}
