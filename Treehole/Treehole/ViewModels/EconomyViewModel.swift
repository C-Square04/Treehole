import Foundation
import SwiftData
import Observation

@Observable
final class EconomyViewModel {

    // MARK: - Economy

    func ensureEconomyExists(context: ModelContext, economies: [Economy]) -> Economy {
        if economies.count > 1, let merged = dedupeEconomies(economies, context: context) {
            return merged
        }
        if let existing = economies.first { return existing }
        let newEconomy = Economy()
        context.insert(newEconomy)
        return newEconomy
    }

    // MARK: - CloudKit Dedupe

    /// CloudKit sync forbids unique constraints, so devices that create an
    /// Economy before their first sync end up with duplicate rows. Keeps a
    /// deterministic winner (lowest id) so every device converges on the same
    /// row; balances merge with max() — never summed — so currency is never
    /// double-granted, and the latest claim/login dates win so daily grants
    /// cannot be re-claimed.
    @discardableResult
    func dedupeEconomies(_ economies: [Economy], context: ModelContext) -> Economy? {
        let live = economies.filter { !$0.isDeleted }
        guard let winner = live.min(by: { $0.id < $1.id }) else { return nil }

        for loser in live where loser !== winner {
            winner.food = max(winner.food, loser.food)
            winner.decorationTokens = max(winner.decorationTokens, loser.decorationTokens)
            winner.gems = max(winner.gems, loser.gems)
            winner.loginStreak = max(winner.loginStreak, loser.loginStreak)
            winner.lastLoginDate = latest(winner.lastLoginDate, loser.lastLoginDate)
            winner.lastDailyResetDate = latest(winner.lastDailyResetDate, loser.lastDailyResetDate)
            winner.lastBonusClaimDate = latest(winner.lastBonusClaimDate, loser.lastBonusClaimDate)
            context.delete(loser)
        }
        return winner
    }

    /// Keeps one DailyTask per (type, day); the winner is the lowest id in
    /// each group. isCompleted is OR-ed across duplicates so an already-paid
    /// task can never pay out again through a synced duplicate.
    func dedupeDailyTasks(_ tasks: [DailyTask], context: ModelContext) {
        let calendar = Calendar.current
        var grouped: [String: [DailyTask]] = [:]
        for task in tasks where !task.isDeleted {
            let day = calendar.startOfDay(for: task.createdAt)
            let key = "\(task.typeRaw)|\(day.timeIntervalSinceReferenceDate)"
            grouped[key, default: []].append(task)
        }
        for group in grouped.values where group.count > 1 {
            guard let winner = group.min(by: { $0.id < $1.id }) else { continue }
            for loser in group where loser !== winner {
                if loser.isCompleted { winner.isCompleted = true }
                context.delete(loser)
            }
        }
    }

    private func latest(_ a: Date?, _ b: Date?) -> Date? {
        switch (a, b) {
        case let (a?, b?): max(a, b)
        case let (a?, nil): a
        case let (nil, b?): b
        default: nil
        }
    }

    // MARK: - Daily Tasks

    func createDailyTasks(context: ModelContext, existingTasks: [DailyTask]) {
        // CloudKit sync can duplicate rows — collapse them before deciding
        dedupeDailyTasks(existingTasks, context: context)

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
        // Stale tasks from a previous day must never pay out — the daily reset
        // may not have run yet if the user hasn't visited Shop/Pet today
        guard Calendar.current.isDateInToday(task.createdAt) else { return }
        task.isCompleted = true
        economy.addFood(task.foodReward)
        if task.tokenReward > 0 {
            economy.addTokens(task.tokenReward)
        }
    }

    func resetDailyTasksIfNeeded(tasks: [DailyTask], context: ModelContext) {
        let calendar = Calendar.current

        // Delete per-task so a stray future-dated task can never block the
        // reset or take today's tasks down with it
        for task in tasks where !task.isDeleted && !calendar.isDateInToday(task.createdAt) {
            context.delete(task)
        }
    }

    // MARK: - Helpers

    func completedTaskCount(tasks: [DailyTask]) -> Int {
        tasks.filter { $0.isCompleted }.count
    }

    // MARK: - Weekly Challenges

    func createWeeklyChallenges(context: ModelContext, existing: [WeeklyChallenge]) {
        let weekStart = Calendar.current.startOfWeek(for: Date())

        // Check if challenges already exist for this week
        let thisWeekChallenges = existing.filter {
            Calendar.current.isDate($0.weekStartDate, inSameDayAs: weekStart)
        }
        guard thisWeekChallenges.isEmpty else { return }

        for challengeType in ChallengeType.allCases {
            let challenge = WeeklyChallenge(type: challengeType, weekStartDate: weekStart)
            context.insert(challenge)
        }
    }

    func incrementChallenge(type: ChallengeType, economy: Economy, challenges: [WeeklyChallenge]) {
        let weekStart = Calendar.current.startOfWeek(for: Date())

        guard let challenge = challenges.first(where: {
            $0.type == type &&
            Calendar.current.isDate($0.weekStartDate, inSameDayAs: weekStart) &&
            !$0.isCompleted
        }) else { return }

        challenge.currentCount += 1

        if challenge.currentCount >= type.targetCount {
            challenge.isCompleted = true
            economy.addFood(type.foodReward)
            if type.tokenReward > 0 {
                economy.addTokens(type.tokenReward)
            }
        }
    }

    func resetWeeklyChallengesIfNeeded(challenges: [WeeklyChallenge], context: ModelContext) {
        guard !challenges.isEmpty else { return }
        let weekStart = Calendar.current.startOfWeek(for: Date())

        // Delete challenges that are from a previous week
        let oldChallenges = challenges.filter {
            !Calendar.current.isDate($0.weekStartDate, inSameDayAs: weekStart)
        }
        for challenge in oldChallenges {
            context.delete(challenge)
        }
    }
}

// MARK: - Calendar extension

private extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components) ?? startOfDay(for: date)
    }
}
