import Foundation
import SwiftData
import Observation

@Observable
final class EconomyViewModel {

    // MARK: - Economy

    func ensureEconomyExists(context: ModelContext, economies: [Economy]) -> Economy {
        if let existing = economies.first { return existing }
        let newEconomy = Economy()
        context.insert(newEconomy)
        return newEconomy
    }

    // MARK: - Daily Tasks

    func createDailyTasks(context: ModelContext, existingTasks: [DailyTask]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Check if any tasks already exist for today
        let todayTasks = existingTasks.filter {
            calendar.isDate(calendar.startOfDay(for: $0.createdAt), inSameDayAs: today)
        }
        guard todayTasks.isEmpty else { return }

        // Create one task for each TaskType
        for taskType in TaskType.allCases {
            let task = DailyTask(type: taskType)
            context.insert(task)
        }
    }

    func completeTask(_ task: DailyTask, economy: Economy) {
        guard !task.isCompleted else { return }
        task.isCompleted = true
        economy.addFood(task.foodReward)
        if task.tokenReward > 0 {
            economy.addTokens(task.tokenReward)
        }
    }

    func resetDailyTasksIfNeeded(tasks: [DailyTask], context: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Find the most recent task creation date
        guard let mostRecentTask = tasks.max(by: { $0.createdAt < $1.createdAt }) else { return }
        let lastResetDay = calendar.startOfDay(for: mostRecentTask.createdAt)

        // If the most recent task was not created today, delete all old tasks
        guard !calendar.isDate(lastResetDay, inSameDayAs: today) else { return }

        for task in tasks {
            context.delete(task)
        }
    }

    // MARK: - Helpers

    func completedTaskCount(tasks: [DailyTask]) -> Int {
        tasks.filter { $0.isCompleted }.count
    }
}
