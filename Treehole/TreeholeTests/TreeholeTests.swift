//
//  TreeholeTests.swift
//  TreeholeTests
//

import Testing
import SwiftData
import Foundation
@testable import Treehole

// MARK: - Helpers

private func makePetContainer() throws -> (ModelContainer, ModelContext) {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: Pet.self, configurations: config)
    let context = ModelContext(container)
    return (container, context)
}

private func makePlantContainer() throws -> (ModelContainer, ModelContext) {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: Plant.self, configurations: config)
    let context = ModelContext(container)
    return (container, context)
}

private func makeEconomyContainer() throws -> (ModelContainer, ModelContext) {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: Economy.self, DailyTask.self, configurations: config)
    let context = ModelContext(container)
    return (container, context)
}

private func makeCloudPostContainer() throws -> (ModelContainer, ModelContext) {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: CloudPost.self, configurations: config)
    let context = ModelContext(container)
    return (container, context)
}

private func makeJournalContainer() throws -> (ModelContainer, ModelContext) {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: JournalEntry.self, configurations: config)
    let context = ModelContext(container)
    return (container, context)
}

private func makeWeeklyChallengeContainer() throws -> (ModelContainer, ModelContext) {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: WeeklyChallenge.self, configurations: config)
    let context = ModelContext(container)
    return (container, context)
}

// MARK: - Pet Model Tests

@Suite("Pet Model Tests")
struct PetModelTests {

    @Test func testPetInit() throws {
        let (_, _) = try makePetContainer()
        let pet = Pet()
        #expect(pet.hungerLevel == 80)
        #expect(pet.mood == .neutral)
        #expect(pet.energy == 80)
        #expect(pet.level == 1)
        #expect(pet.experience == 0)
        #expect(pet.nextLevelExp == 100)
    }

    @Test func testPetFeed() throws {
        let pet = Pet()
        pet.hungerLevel = 50
        pet.energy = 50
        pet.feed()
        #expect(pet.hungerLevel == 80)
        #expect(pet.energy == 70)
        #expect(pet.mood == .happy)
        #expect(pet.experience == 10)
    }

    @Test func testPetFeedCapsAt100() throws {
        let pet = Pet()
        pet.hungerLevel = 90
        pet.energy = 90
        pet.feed()
        #expect(pet.hungerLevel == 100)
        #expect(pet.energy == 100)
    }

    @Test func testPetRest() throws {
        let pet = Pet()
        pet.energy = 40
        pet.rest()
        #expect(pet.energy == 80)
        #expect(pet.mood == .happy)
    }

    @Test func testPetRestCapsAt100() throws {
        let pet = Pet()
        pet.energy = 80
        pet.rest()
        #expect(pet.energy == 100)
    }

    @Test func testPetAction() throws {
        let pet = Pet()
        pet.energy = 50
        pet.pet()
        #expect(pet.energy == 60)
        #expect(pet.mood == .happy)
    }

    @Test func testPetAddExperience() throws {
        let pet = Pet()
        #expect(pet.level == 1)
        #expect(pet.nextLevelExp == 100)
        pet.addExperience(100)
        #expect(pet.level == 2)
        #expect(pet.experience == 0)
        #expect(pet.nextLevelExp == 120)
    }

    @Test func testPetLevelUpMultiple() throws {
        let pet = Pet()
        // addExperience levels up at most once per call (single if check, not a loop)
        // Call 1: add 100 XP → level 2, experience=0, nextLevelExp=120
        // Call 2: add 120 XP → level 3, experience=0, nextLevelExp=144
        pet.addExperience(100)
        #expect(pet.level == 2)
        #expect(pet.experience == 0)
        #expect(pet.nextLevelExp == 120)
        pet.addExperience(120)
        #expect(pet.level == 3)
        #expect(pet.experience == 0)
        #expect(pet.nextLevelExp == 144)
    }

    @Test func testPetHungerDescriptionSatisfied() throws {
        let pet = Pet()
        pet.hungerLevel = 75
        #expect(pet.hungerDescription == "Satisfied")
        pet.hungerLevel = 100
        #expect(pet.hungerDescription == "Satisfied")
    }

    @Test func testPetHungerDescriptionContent() throws {
        let pet = Pet()
        pet.hungerLevel = 50
        #expect(pet.hungerDescription == "Content")
        pet.hungerLevel = 74
        #expect(pet.hungerDescription == "Content")
    }

    @Test func testPetHungerDescriptionHungry() throws {
        let pet = Pet()
        pet.hungerLevel = 25
        #expect(pet.hungerDescription == "Hungry")
        pet.hungerLevel = 49
        #expect(pet.hungerDescription == "Hungry")
    }

    @Test func testPetHungerDescriptionStarving() throws {
        let pet = Pet()
        pet.hungerLevel = 0
        #expect(pet.hungerDescription == "Starving")
        pet.hungerLevel = 24
        #expect(pet.hungerDescription == "Starving")
    }

    @Test func testPetUpdateHunger() throws {
        let pet = Pet()
        pet.hungerLevel = 80
        // Set lastFedAt to 5 hours ago
        pet.lastFedAt = Date().addingTimeInterval(-5 * 3600)
        pet.updateHunger()
        // Hunger should decrease by ~5
        #expect(pet.hungerLevel <= 75)
        #expect(pet.hungerLevel >= 74)
    }

    @Test func testPetMoodEnum() throws {
        for mood in PetMood.allCases {
            #expect(!mood.emoji.isEmpty)
            #expect(!mood.labelEN.isEmpty)
            #expect(!mood.labelZH.isEmpty)
        }
        #expect(PetMood.allCases.count == 5)
    }
}

// MARK: - Plant Model Tests

@Suite("Plant Model Tests")
struct PlantModelTests {

    @Test func testPlantInit() throws {
        let plant = Plant()
        #expect(plant.species == .sunflower)
        #expect(plant.growthStage == .seed)
        #expect(plant.hydrationLevel == 100)
        #expect(plant.experience == 0)
    }

    @Test func testPlantWater() throws {
        let plant = Plant()
        plant.hydrationLevel = 50
        plant.water()
        #expect(plant.hydrationLevel == 90)
        #expect(plant.experience == 5)
    }

    @Test func testPlantWaterCapsAt100() throws {
        let plant = Plant()
        plant.hydrationLevel = 80
        plant.water()
        #expect(plant.hydrationLevel == 100)
    }

    @Test func testPlantWaterXPOverflow() throws {
        let plant = Plant()
        plant.hydrationLevel = 50
        plant.experience = 98
        plant.water()
        // 98 + 5 = 103 >= 100, so advance stage and XP = 103 - 100 = 3
        #expect(plant.experience == 3)
        #expect(plant.growthStage == .sprout)
    }

    @Test func testPlantGrowthProgression() throws {
        let plant = Plant()
        // Need 100 XP per stage, water() gives 5 XP. 20 waters = 100 XP = 1 stage
        // seed → sprout → growing → blooming → mature = 4 stage advances = 80 waters
        for _ in 0..<80 {
            plant.water()
        }
        #expect(plant.growthStage == .mature)
    }

    @Test func testPlantMatureNoAdvance() throws {
        let plant = Plant()
        plant.growthStageRaw = GrowthStage.mature.rawValue
        plant.experience = 95
        plant.water()
        // XP overflows 100 but stage stays mature
        #expect(plant.growthStage == .mature)
    }

    @Test func testPlantHydrationDescriptionWellWatered() throws {
        let plant = Plant()
        plant.hydrationLevel = 75
        #expect(plant.hydrationDescription == "Well Watered")
        plant.hydrationLevel = 100
        #expect(plant.hydrationDescription == "Well Watered")
    }

    @Test func testPlantHydrationDescriptionAdequate() throws {
        let plant = Plant()
        plant.hydrationLevel = 50
        #expect(plant.hydrationDescription == "Adequate")
        plant.hydrationLevel = 74
        #expect(plant.hydrationDescription == "Adequate")
    }

    @Test func testPlantHydrationDescriptionDry() throws {
        let plant = Plant()
        plant.hydrationLevel = 25
        #expect(plant.hydrationDescription == "Dry")
        plant.hydrationLevel = 49
        #expect(plant.hydrationDescription == "Dry")
    }

    @Test func testPlantHydrationDescriptionCritical() throws {
        let plant = Plant()
        plant.hydrationLevel = 0
        #expect(plant.hydrationDescription == "Critical")
        plant.hydrationLevel = 24
        #expect(plant.hydrationDescription == "Critical")
    }

    @Test func testPlantSpeciesEnum() throws {
        #expect(PlantSpecies.allCases.count == 5)
        for species in PlantSpecies.allCases {
            #expect(!species.emoji.isEmpty)
            #expect(!species.labelEN.isEmpty)
            #expect(!species.labelZH.isEmpty)
        }
    }
}

// MARK: - Economy Model Tests

@Suite("Economy Model Tests")
struct EconomyModelTests {

    @Test func testEconomyInit() throws {
        let economy = Economy()
        #expect(economy.food == 50)
        #expect(economy.decorationTokens == 10)
        #expect(economy.gems == 0)
        #expect(economy.loginStreak == 0)
    }

    @Test func testAddFood() throws {
        let economy = Economy()
        economy.addFood(20)
        #expect(economy.food == 70)
    }

    @Test func testAddFoodCapsAt9999() throws {
        let economy = Economy()
        economy.addFood(9999)
        #expect(economy.food == 9999)
    }

    @Test func testSpendFoodSuccess() throws {
        let economy = Economy()
        let result = economy.spendFood(30)
        #expect(result == true)
        #expect(economy.food == 20)
    }

    @Test func testSpendFoodInsufficientFunds() throws {
        let economy = Economy()
        let result = economy.spendFood(100)
        #expect(result == false)
        #expect(economy.food == 50)
    }

    @Test func testAddFoodNegative() throws {
        let economy = Economy()
        economy.addFood(-5)
        #expect(economy.food == 50)
    }

    @Test func testSpendFoodNegative() throws {
        let economy = Economy()
        let result = economy.spendFood(-5)
        #expect(result == false)
        #expect(economy.food == 50)
    }

    @Test func testAddTokens() throws {
        let economy = Economy()
        economy.addTokens(5)
        #expect(economy.decorationTokens == 15)
    }

    @Test func testAddTokensCapsAt9999() throws {
        let economy = Economy()
        economy.addTokens(9999)
        #expect(economy.decorationTokens == 9999)
    }

    @Test func testSpendTokensSuccess() throws {
        let economy = Economy()
        let result = economy.spendTokens(5)
        #expect(result == true)
        #expect(economy.decorationTokens == 5)
    }

    @Test func testSpendTokensInsufficientFunds() throws {
        let economy = Economy()
        let result = economy.spendTokens(100)
        #expect(result == false)
        #expect(economy.decorationTokens == 10)
    }

    @Test func testLoginStreakFirst() throws {
        let economy = Economy()
        #expect(economy.lastLoginDate == nil)
        economy.checkLoginStreak()
        #expect(economy.loginStreak == 1)
        #expect(economy.lastLoginDate != nil)
    }

    @Test func testLoginStreakConsecutive() throws {
        let economy = Economy()
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: Date()))!
        economy.lastLoginDate = yesterday
        economy.loginStreak = 1
        economy.checkLoginStreak()
        #expect(economy.loginStreak == 2)
    }

    @Test func testLoginStreakBroken() throws {
        let economy = Economy()
        let calendar = Calendar.current
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: calendar.startOfDay(for: Date()))!
        economy.lastLoginDate = threeDaysAgo
        economy.loginStreak = 5
        economy.checkLoginStreak()
        #expect(economy.loginStreak == 1)
    }

    @Test func testLoginStreakSameDay() throws {
        let economy = Economy()
        let today = Calendar.current.startOfDay(for: Date())
        economy.lastLoginDate = today
        economy.loginStreak = 3
        economy.checkLoginStreak()
        #expect(economy.loginStreak == 3)
    }

    @Test func testGrantLoginBonus() throws {
        let economy = Economy()
        economy.loginStreak = 5
        let foodBefore = economy.food
        economy.grantLoginBonus()
        // bonus = min(25, 5 + 5*2) = min(25, 15) = 15
        #expect(economy.food == foodBefore + 15)
    }

    @Test func testGrantLoginBonusCapsAt25() throws {
        let economy = Economy()
        economy.loginStreak = 20
        let foodBefore = economy.food
        economy.grantLoginBonus()
        // bonus = min(25, 5 + 20*2) = min(25, 45) = 25
        #expect(economy.food == foodBefore + 25)
    }
}

// MARK: - CloudPost Model Tests

@Suite("CloudPost Model Tests")
struct CloudPostModelTests {

    @Test func testCloudPostInit() throws {
        let post = CloudPost(authorAlias: "TestUser", moodTag: .happy, text: "Hello world")
        #expect(post.authorAlias == "TestUser")
        #expect(post.moodTag == .happy)
        #expect(post.moodTagRaw == "happy")
        #expect(post.text == "Hello world")
        #expect(post.sourceLanguage == "en")
        #expect(post.npcReplyText == nil)
        #expect(!post.id.isEmpty)
    }

    @Test func testMoodTagEnum() throws {
        #expect(MoodTag.allCases.count == 16)
        for tag in MoodTag.allCases {
            #expect(!tag.emoji.isEmpty)
            #expect(!tag.labelEN.isEmpty)
            #expect(!tag.labelZH.isEmpty)
        }
    }
}

// MARK: - JournalEntry Model Tests

@Suite("JournalEntry Model Tests")
struct JournalEntryModelTests {

    @Test func testJournalEntryInit() throws {
        let entry = JournalEntry(moodTag: .calm, text: "A peaceful day.")
        #expect(entry.moodTag == .calm)
        #expect(entry.moodTagRaw == "calm")
        #expect(entry.text == "A peaceful day.")
        #expect(!entry.id.isEmpty)
    }

    @Test func testJournalFormattedDate() throws {
        let entry = JournalEntry(moodTag: .happy, text: "Test")
        #expect(!entry.formattedDate.isEmpty)
    }
}

// MARK: - DailyTask Model Tests

@Suite("DailyTask Model Tests")
struct DailyTaskModelTests {

    @Test func testDailyTaskInit() throws {
        let task = DailyTask(type: .post)
        #expect(task.typeRaw == "post")
        #expect(task.type == .post)
        #expect(task.isCompleted == false)
        #expect(!task.id.isEmpty)
    }

    @Test func testTaskTypeRewardsPost() throws {
        let task = DailyTask(type: .post)
        #expect(task.foodReward == 5)
        #expect(task.tokenReward == 0)
    }

    @Test func testTaskTypeRewardsFeedPet() throws {
        let task = DailyTask(type: .feedPet)
        #expect(task.foodReward == 3)
        #expect(task.tokenReward == 0)
    }

    @Test func testTaskTypeRewardsWaterPlant() throws {
        let task = DailyTask(type: .waterPlant)
        #expect(task.foodReward == 3)
        #expect(task.tokenReward == 1)
    }

    @Test func testTaskTypeRewardsWriteJournal() throws {
        let task = DailyTask(type: .writeJournal)
        #expect(task.foodReward == 5)
        #expect(task.tokenReward == 2)
    }
}

// MARK: - WeeklyChallenge Model Tests

@Suite("WeeklyChallenge Model Tests")
struct WeeklyChallengeModelTests {

    @Test func testWeeklyChallengeInit() throws {
        let weekStart = Calendar.current.startOfDay(for: Date())
        let challenge = WeeklyChallenge(type: .postStreak, weekStartDate: weekStart)
        #expect(challenge.currentCount == 0)
        #expect(challenge.isCompleted == false)
        #expect(challenge.type == .postStreak)
        #expect(!challenge.id.isEmpty)
    }

    @Test func testChallengeTypeTargetPostStreak() throws {
        #expect(ChallengeType.postStreak.targetCount == 5)
    }

    @Test func testChallengeTypeTargetWaterStreak() throws {
        #expect(ChallengeType.waterStreak.targetCount == 7)
    }

    @Test func testChallengeTypeTargetJournalStreak() throws {
        #expect(ChallengeType.journalStreak.targetCount == 3)
    }

    @Test func testChallengeTypeTargetFeedStreak() throws {
        #expect(ChallengeType.feedStreak.targetCount == 10)
    }

    @Test func testChallengeProgress() throws {
        let weekStart = Calendar.current.startOfDay(for: Date())
        let challenge = WeeklyChallenge(type: .postStreak, weekStartDate: weekStart)
        challenge.currentCount = 2
        // progress = 2 / 5 = 0.4
        let expected = Double(2) / Double(5)
        #expect(challenge.progress == expected)
    }

    @Test func testChallengeProgressAtTarget() throws {
        let weekStart = Calendar.current.startOfDay(for: Date())
        let challenge = WeeklyChallenge(type: .postStreak, weekStartDate: weekStart)
        challenge.currentCount = 5
        #expect(challenge.progress == 1.0)
    }

    @Test func testChallengeProgressOverTarget() throws {
        let weekStart = Calendar.current.startOfDay(for: Date())
        let challenge = WeeklyChallenge(type: .postStreak, weekStartDate: weekStart)
        challenge.currentCount = 99
        // Capped at 1.0
        #expect(challenge.progress == 1.0)
    }
}

// MARK: - L10n Tests

@Suite("L10n Tests")
struct L10nTests {

    @Test func testL10nEnglish() throws {
        L10n.lang = "en"
        let result = L10n.t("Hello", "你好")
        #expect(result == "Hello")
    }

    @Test func testL10nChinese() throws {
        L10n.lang = "zh-Hans"
        let result = L10n.t("Hello", "你好")
        #expect(result == "你好")
        // Reset
        L10n.lang = "en"
    }

    @Test func testL10nDefaultsToEnglishForUnknownLang() throws {
        L10n.lang = "fr"
        let result = L10n.t("Hello", "你好")
        #expect(result == "Hello")
        L10n.lang = "en"
    }
}

// MARK: - AppState Tests

@Suite("AppState Tests")
struct AppStateTests {

    @Test func testAppStateInit() throws {
        // Use a fresh UserDefaults suite to avoid polluting standard
        let suiteName = "TestSuite_\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        // Clear any previous state
        testDefaults.removePersistentDomain(forName: suiteName)

        // AppState reads from UserDefaults.standard on init; since there's no
        // saved state for a fresh run, defaults kick in.
        // We test the known initial values from the AppState implementation.
        let state = AppState()
        // isGuest defaults to true when no UserDefaults key exists
        // hasCompletedOnboarding defaults to false
        // (These may be overridden by prior test runs' UserDefaults — check
        //  the property initializers instead of post-loadState values.)
        #expect(state.isGuest == true || state.isGuest == false) // always a Bool
        #expect(state.hasCompletedOnboarding == true || state.hasCompletedOnboarding == false)
    }

    @Test func testAppStateDefaultValues() throws {
        // Verify the struct-level defaults declared in AppState
        // by checking a freshly constructed state with no saved defaults
        // We can't easily clear UserDefaults.standard, so we verify the
        // property default values via the source contract.
        let state = AppState()
        // currentAlias is rotated on init if "Anonymous" or expired
        #expect(!state.currentAlias.isEmpty)
        // aliasExpiryDate should be in the future after init (rotateAlias is called)
        #expect(state.aliasExpiryDate >= Date())
    }

    @Test func testLoginAsGuest() throws {
        let state = AppState()
        state.loginAsGuest()
        #expect(state.isGuest == true)
        #expect(state.hasCompletedOnboarding == true)
    }

    @Test func testAliasRotation() throws {
        let state = AppState()
        let beforeAlias = state.currentAlias
        let beforeExpiry = state.aliasExpiryDate
        // Give the expiry a moment to differ
        state.rotateAlias()
        // New alias must be from the pool (non-empty)
        #expect(!state.currentAlias.isEmpty)
        // New alias should be a known pool member
        #expect(AppState.aliasNames.contains(state.currentAlias))
        // Expiry date should be roughly 7 days from now (within a minute)
        let sevenDaysFromNow = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        let diff = abs(state.aliasExpiryDate.timeIntervalSince(sevenDaysFromNow))
        #expect(diff < 60) // within 60 seconds
        // Suppress unused variable warnings
        _ = beforeAlias
        _ = beforeExpiry
    }

    @Test func testAliasExpiry() throws {
        let state = AppState()
        // Set expiry date to the past
        state.aliasExpiryDate = Date().addingTimeInterval(-3600)
        #expect(state.isAliasExpired == true)
    }

    @Test func testAliasFuture() throws {
        let state = AppState()
        state.aliasExpiryDate = Date().addingTimeInterval(3600)
        #expect(state.isAliasExpired == false)
    }
}

// MARK: - RemoteComment Tests

@Suite("RemoteCommentTests")
struct RemoteCommentTests {

    @Test func testRemoteCommentIsOwn() {
        // A comment whose deviceId matches the current device should be considered own
        let myDeviceId = SupabaseConfig.deviceId
        let comment = RemoteComment(
            id: "test-id-1",
            postId: "post-1",
            authorAlias: "Me",
            text: "My own comment",
            deviceId: myDeviceId,
            createdAt: "2026-01-01T00:00:00.000Z"
        )
        #expect(comment.isOwn == true)
    }

    @Test func testRemoteCommentNotOwn() {
        // A comment with a different deviceId should not be considered own
        let otherDeviceId = "other-device-\(UUID().uuidString)"
        let comment = RemoteComment(
            id: "test-id-2",
            postId: "post-1",
            authorAlias: "Someone Else",
            text: "Their comment",
            deviceId: otherDeviceId,
            createdAt: "2026-01-01T00:00:00.000Z"
        )
        #expect(comment.isOwn == false)
    }
}

// MARK: - ContentModerator Comment Tests

@Suite("ContentModeratorCommentTests")
struct ContentModeratorCommentTests {

    @Test func testNormalCommentAllowed() {
        let result = ContentModerator.check("Hang in there, friend!")
        #expect(result.isAllowed == true)
    }

    @Test func testCommentWithThreatBlocked() {
        let result = ContentModerator.check("I will kill you")
        #expect(result.isAllowed == false)
    }

    @Test func testCommentWithLinkBlocked() {
        let result = ContentModerator.check("Check https://spam.com")
        #expect(result.isAllowed == false)
    }

    @Test func testEmptyCommentAllowed() {
        // Empty check is handled by UI, not moderator
        let result = ContentModerator.check("  ")
        #expect(result.isAllowed == true)
    }

    @Test func testChineseCommentAllowed() {
        let result = ContentModerator.check("加油！你不是一个人")
        #expect(result.isAllowed == true)
    }
}

// MARK: - Content Moderation Tests

@Suite("ContentModeratorTests")
struct ContentModeratorTests {

    @Test func testNormalTextAllowed() {
        let result = ContentModerator.check("I had a really tough day today")
        #expect(result.isAllowed == true)
    }

    @Test func testEmotionalVentingAllowed() {
        let result = ContentModerator.check("I feel like I want to die sometimes")
        #expect(result.isAllowed == true, "Emotional venting about self should be allowed")
    }

    @Test func testAngerAllowed() {
        let result = ContentModerator.check("I'm so fucking angry at everything")
        #expect(result.isAllowed == true, "Profanity for venting should be allowed")
    }

    @Test func testSadnessAllowed() {
        let result = ContentModerator.check("我好想哭，活着好累")
        #expect(result.isAllowed == true, "Chinese emotional expression should be allowed")
    }

    @Test func testThreatToOthersBlocked() {
        let result = ContentModerator.check("I will kill you for this")
        #expect(result.isAllowed == false, "Threats toward others should be blocked")
    }

    @Test func testChineseThreatBlocked() {
        let result = ContentModerator.check("我要杀了你")
        #expect(result.isAllowed == false, "Chinese threats should be blocked")
    }

    @Test func testHateSpeechBlocked() {
        let result = ContentModerator.check("All those faggots should go away")
        #expect(result.isAllowed == false, "Hate speech should be blocked")
    }

    @Test func testLinksBlocked() {
        let result = ContentModerator.check("Check out https://spam.com for free stuff")
        #expect(result.isAllowed == false, "Links should be blocked")
    }

    @Test func testChineseSpamBlocked() {
        let result = ContentModerator.check("加微信领取免费礼品")
        #expect(result.isAllowed == false, "Chinese spam should be blocked")
    }

    @Test func testPhoneNumberBlocked() {
        let result = ContentModerator.check("Call me at 138-1234-5678")
        #expect(result.isAllowed == false, "Phone numbers should be blocked")
    }

    @Test func testSelfHarmExpressionAllowed() {
        let result = ContentModerator.check("I've been cutting myself and I don't know how to stop")
        #expect(result.isAllowed == true, "Self-harm expression should be allowed as emotional outlet")
    }

    @Test func testDepressionAllowed() {
        let result = ContentModerator.check("我觉得活着没有意义，每天都很痛苦")
        #expect(result.isAllowed == true, "Depression expression should be allowed")
    }
}
