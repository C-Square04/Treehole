//
//  EconomyViewModelTests.swift
//  TreeholeTests
//

import Testing
import SwiftData
import Foundation
@testable import Treehole

// MARK: - Helpers

private func makeEconomyVMContainer() throws -> (ModelContainer, ModelContext) {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(
        for: Economy.self, DailyTask.self, WeeklyChallenge.self,
        configurations: config
    )
    let context = ModelContext(container)
    return (container, context)
}

private func fetchTasks(_ context: ModelContext) throws -> [DailyTask] {
    try context.fetch(FetchDescriptor<DailyTask>())
}

private func fetchEconomies(_ context: ModelContext) throws -> [Economy] {
    try context.fetch(FetchDescriptor<Economy>())
}

private func startOfWeek(for date: Date = Date()) -> Date {
    let calendar = Calendar.current
    let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
    return calendar.date(from: components) ?? calendar.startOfDay(for: date)
}

// MARK: - Daily Task Orchestration Tests

@Suite("EconomyViewModel Daily Task Tests")
struct EconomyViewModelDailyTaskTests {

    @Test func testCreateDailyTasksCreatesAllTypes() throws {
        let (_, context) = try makeEconomyVMContainer()
        let vm = EconomyViewModel()
        vm.createDailyTasks(context: context, existingTasks: [])
        try context.save()
        let tasks = try fetchTasks(context)
        #expect(tasks.count == TaskType.allCases.count)
        for taskType in TaskType.allCases {
            #expect(tasks.contains { $0.type == taskType })
        }
    }

    @Test func testCreateDailyTasksIdempotentSameDay() throws {
        let (_, context) = try makeEconomyVMContainer()
        let vm = EconomyViewModel()
        vm.createDailyTasks(context: context, existingTasks: [])
        try context.save()
        let firstBatch = try fetchTasks(context)
        vm.createDailyTasks(context: context, existingTasks: firstBatch)
        try context.save()
        #expect(try fetchTasks(context).count == TaskType.allCases.count)
    }

    @Test func testCompleteTaskGrantsRewardsOnce() throws {
        let (_, context) = try makeEconomyVMContainer()
        let vm = EconomyViewModel()
        let economy = Economy()
        let task = DailyTask(type: .writeJournal)
        context.insert(economy)
        context.insert(task)

        let foodBefore = economy.food
        let tokensBefore = economy.decorationTokens
        vm.completeTask(task, economy: economy)
        #expect(task.isCompleted == true)
        #expect(economy.food == foodBefore + task.foodReward)
        #expect(economy.decorationTokens == tokensBefore + task.tokenReward)

        // Second completion must not pay out again
        vm.completeTask(task, economy: economy)
        #expect(economy.food == foodBefore + task.foodReward)
        #expect(economy.decorationTokens == tokensBefore + task.tokenReward)
    }

    @Test func testCompleteTaskRefusesStaleTask() throws {
        let (_, context) = try makeEconomyVMContainer()
        let vm = EconomyViewModel()
        let economy = Economy()
        let task = DailyTask(type: .writeJournal)
        task.createdAt = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        context.insert(economy)
        context.insert(task)

        let foodBefore = economy.food
        vm.completeTask(task, economy: economy)
        // Yesterday's task must not complete or pay out
        #expect(task.isCompleted == false)
        #expect(economy.food == foodBefore)
    }

    @Test func testResetDeletesStaleKeepsTodayTasks() throws {
        let (_, context) = try makeEconomyVMContainer()
        let vm = EconomyViewModel()
        let staleTask = DailyTask(type: .post)
        staleTask.createdAt = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let todayTask = DailyTask(type: .writeJournal)
        context.insert(staleTask)
        context.insert(todayTask)
        try context.save()

        vm.resetDailyTasksIfNeeded(tasks: [staleTask, todayTask], context: context)
        try context.save()

        let remaining = try fetchTasks(context)
        #expect(remaining.count == 1)
        #expect(remaining.first?.type == .writeJournal)
    }

    @Test func testResetDeletesFutureDatedTask() throws {
        let (_, context) = try makeEconomyVMContainer()
        let vm = EconomyViewModel()
        let futureTask = DailyTask(type: .post)
        futureTask.createdAt = Calendar.current.date(byAdding: .day, value: 2, to: Date())!
        context.insert(futureTask)
        try context.save()

        vm.resetDailyTasksIfNeeded(tasks: [futureTask], context: context)
        try context.save()

        #expect(try fetchTasks(context).isEmpty)
    }

    @Test func testCompletedTaskCount() throws {
        let (_, _) = try makeEconomyVMContainer()
        let vm = EconomyViewModel()
        let done = DailyTask(type: .post)
        done.isCompleted = true
        let pending = DailyTask(type: .feedPet)
        #expect(vm.completedTaskCount(tasks: [done, pending]) == 1)
    }
}

// MARK: - CloudKit Dedupe Tests

@Suite("EconomyViewModel Dedupe Tests")
struct EconomyViewModelDedupeTests {

    @Test func testDedupeEconomiesKeepsLowestId() throws {
        let (_, context) = try makeEconomyVMContainer()
        let vm = EconomyViewModel()
        let a = Economy()
        a.id = "aaa"
        let b = Economy()
        b.id = "bbb"
        context.insert(a)
        context.insert(b)

        let winner = vm.dedupeEconomies([b, a], context: context)
        try context.save()

        #expect(winner?.id == "aaa")
        let remaining = try fetchEconomies(context)
        #expect(remaining.count == 1)
        #expect(remaining.first?.id == "aaa")
    }

    @Test func testDedupeEconomiesMergesConservatively() throws {
        let (_, context) = try makeEconomyVMContainer()
        let vm = EconomyViewModel()
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!

        let winner = Economy()
        winner.id = "aaa"
        winner.food = 50
        winner.decorationTokens = 20
        winner.loginStreak = 1
        winner.lastBonusClaimDate = yesterday

        let loser = Economy()
        loser.id = "bbb"
        loser.food = 200
        loser.decorationTokens = 5
        loser.gems = 3
        loser.loginStreak = 7
        loser.lastBonusClaimDate = Date()

        context.insert(winner)
        context.insert(loser)
        let merged = vm.dedupeEconomies([winner, loser], context: context)

        // max() per balance — never summed, so currency can't double-grant
        #expect(merged?.food == 200)
        #expect(merged?.decorationTokens == 20)
        #expect(merged?.gems == 3)
        #expect(merged?.loginStreak == 7)
        // Latest claim date wins so today's bonus stays claimed
        #expect(merged?.hasClaimedLoginBonusToday == true)
    }

    @Test func testDedupeEconomiesSingleRowIsNoOp() throws {
        let (_, context) = try makeEconomyVMContainer()
        let vm = EconomyViewModel()
        let only = Economy()
        only.food = 77
        context.insert(only)

        let winner = vm.dedupeEconomies([only], context: context)
        try context.save()

        #expect(winner === only)
        #expect(winner?.food == 77)
        #expect(try fetchEconomies(context).count == 1)
    }

    @Test func testEnsureEconomyExistsDedupesDuplicates() throws {
        let (_, context) = try makeEconomyVMContainer()
        let vm = EconomyViewModel()
        let a = Economy()
        a.id = "aaa"
        let b = Economy()
        b.id = "bbb"
        context.insert(a)
        context.insert(b)

        let result = vm.ensureEconomyExists(context: context, economies: [b, a])
        try context.save()

        #expect(result.id == "aaa")
        #expect(try fetchEconomies(context).count == 1)
    }

    @Test func testEnsureEconomyExistsCreatesWhenEmpty() throws {
        let (_, context) = try makeEconomyVMContainer()
        let vm = EconomyViewModel()
        _ = vm.ensureEconomyExists(context: context, economies: [])
        try context.save()
        #expect(try fetchEconomies(context).count == 1)
    }

    @Test func testDedupeDailyTasksKeepsOnePerTypePerDay() throws {
        let (_, context) = try makeEconomyVMContainer()
        let vm = EconomyViewModel()
        let a = DailyTask(type: .post)
        a.id = "aaa"
        let b = DailyTask(type: .post)
        b.id = "bbb"
        let other = DailyTask(type: .feedPet)
        context.insert(a)
        context.insert(b)
        context.insert(other)
        try context.save()

        vm.dedupeDailyTasks([a, b, other], context: context)
        try context.save()

        let remaining = try fetchTasks(context)
        #expect(remaining.count == 2)
        #expect(remaining.contains { $0.id == "aaa" })
        #expect(!remaining.contains { $0.id == "bbb" })
    }

    @Test func testDedupeDailyTasksPreservesCompletion() throws {
        let (_, context) = try makeEconomyVMContainer()
        let vm = EconomyViewModel()
        let winner = DailyTask(type: .post)
        winner.id = "aaa"
        let completedDupe = DailyTask(type: .post)
        completedDupe.id = "bbb"
        completedDupe.isCompleted = true
        context.insert(winner)
        context.insert(completedDupe)
        try context.save()

        vm.dedupeDailyTasks([winner, completedDupe], context: context)
        try context.save()

        // A paid-out duplicate must leave the survivor completed — otherwise
        // the same task could be completed (and rewarded) twice
        let remaining = try fetchTasks(context)
        #expect(remaining.count == 1)
        #expect(remaining.first?.isCompleted == true)
    }

    @Test func testDedupeDailyTasksKeepsDistinctDays() throws {
        let (_, context) = try makeEconomyVMContainer()
        let vm = EconomyViewModel()
        let today = DailyTask(type: .post)
        let yesterday = DailyTask(type: .post)
        yesterday.createdAt = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        context.insert(today)
        context.insert(yesterday)
        try context.save()

        vm.dedupeDailyTasks([today, yesterday], context: context)
        try context.save()

        // Same type on different days is not a duplicate
        #expect(try fetchTasks(context).count == 2)
    }
}

// MARK: - Login Bonus Persistence Tests

@Suite("Login Bonus Persistence Tests")
struct LoginBonusPersistenceTests {

    @Test func testGrantLoginBonusOncePerDay() throws {
        let economy = Economy()
        economy.loginStreak = 3
        let foodBefore = economy.food

        #expect(economy.grantLoginBonus() == true)
        let foodAfterFirst = economy.food
        #expect(foodAfterFirst == foodBefore + min(25, 5 + 3 * 2))

        // Second claim the same day is refused
        #expect(economy.grantLoginBonus() == false)
        #expect(economy.food == foodAfterFirst)
    }

    @Test func testGrantLoginBonusRecordsClaimDate() throws {
        let economy = Economy()
        #expect(economy.hasClaimedLoginBonusToday == false)
        economy.grantLoginBonus()
        #expect(economy.lastBonusClaimDate != nil)
        #expect(economy.hasClaimedLoginBonusToday == true)
    }

    @Test func testGrantLoginBonusAllowedAfterYesterdayClaim() throws {
        let economy = Economy()
        economy.lastBonusClaimDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        #expect(economy.hasClaimedLoginBonusToday == false)
        let foodBefore = economy.food
        #expect(economy.grantLoginBonus() == true)
        #expect(economy.food > foodBefore)
    }
}

// MARK: - Task Title Localization Tests

@Suite("Task Title Localization Tests")
struct TaskTitleLocalizationTests {

    @Test func testTaskTypeChineseTitlesExist() throws {
        for taskType in TaskType.allCases {
            #expect(!taskType.titleZH.isEmpty)
            #expect(taskType.titleZH != taskType.title)
        }
    }

    @Test func testDailyTaskLocalizedTitleFollowsLanguage() throws {
        let task = DailyTask(type: .post)
        L10n.lang = "zh-Hans"
        #expect(task.localizedTitle == TaskType.post.titleZH)
        L10n.lang = "en"
        #expect(task.localizedTitle == TaskType.post.title)
    }

    @Test func testLocalizedTitleIgnoresPersistedEnglishTitle() throws {
        // The stored title is English at creation time; display must derive
        // from the type, not the persisted string
        let task = DailyTask(type: .writeJournal)
        #expect(task.title == TaskType.writeJournal.title)
        L10n.lang = "zh-Hans"
        #expect(task.localizedTitle == TaskType.writeJournal.titleZH)
        L10n.lang = "en"
    }
}

// MARK: - Weekly Challenge Orchestration Tests

@Suite("EconomyViewModel Weekly Challenge Tests")
struct EconomyViewModelWeeklyChallengeTests {

    @Test func testCreateWeeklyChallengesCreatesAllTypes() throws {
        let (_, context) = try makeEconomyVMContainer()
        let vm = EconomyViewModel()
        vm.createWeeklyChallenges(context: context, existing: [])
        try context.save()
        let challenges = try context.fetch(FetchDescriptor<WeeklyChallenge>())
        #expect(challenges.count == ChallengeType.allCases.count)
    }

    @Test func testIncrementChallengeCompletesAtTargetAndGrantsOnce() throws {
        let (_, context) = try makeEconomyVMContainer()
        let vm = EconomyViewModel()
        let economy = Economy()
        let challenge = WeeklyChallenge(type: .journalStreak, weekStartDate: startOfWeek())
        context.insert(economy)
        context.insert(challenge)

        let foodBefore = economy.food
        for _ in 0..<ChallengeType.journalStreak.targetCount {
            vm.incrementChallenge(type: .journalStreak, economy: economy, challenges: [challenge])
        }
        #expect(challenge.isCompleted == true)
        #expect(economy.food == foodBefore + ChallengeType.journalStreak.foodReward)

        // Further increments after completion must not pay out again
        vm.incrementChallenge(type: .journalStreak, economy: economy, challenges: [challenge])
        #expect(economy.food == foodBefore + ChallengeType.journalStreak.foodReward)
    }

    @Test func testIncrementChallengeIgnoresPriorWeek() throws {
        let (_, context) = try makeEconomyVMContainer()
        let vm = EconomyViewModel()
        let economy = Economy()
        let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: startOfWeek())!
        let stale = WeeklyChallenge(type: .postStreak, weekStartDate: lastWeek)
        context.insert(economy)
        context.insert(stale)

        vm.incrementChallenge(type: .postStreak, economy: economy, challenges: [stale])
        #expect(stale.currentCount == 0)
    }

    @Test func testResetWeeklyChallengesDeletesOnlyPriorWeek() throws {
        let (_, context) = try makeEconomyVMContainer()
        let vm = EconomyViewModel()
        let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: startOfWeek())!
        let stale = WeeklyChallenge(type: .postStreak, weekStartDate: lastWeek)
        let current = WeeklyChallenge(type: .journalStreak, weekStartDate: startOfWeek())
        context.insert(stale)
        context.insert(current)
        try context.save()

        vm.resetWeeklyChallengesIfNeeded(challenges: [stale, current], context: context)
        try context.save()

        let remaining = try context.fetch(FetchDescriptor<WeeklyChallenge>())
        #expect(remaining.count == 1)
        #expect(remaining.first?.type == .journalStreak)
    }
}
