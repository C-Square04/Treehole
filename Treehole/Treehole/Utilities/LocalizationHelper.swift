//
//  LocalizationHelper.swift
//  Treehole
//
//  Created by Kayli Cheung & Jimmy Chen on 2025-11-06.
//

import Foundation
import SwiftUI

// MARK: - String Extension for Localization

extension String {
    func localized() -> String {
        return NSLocalizedString(self, comment: "")
    }

    func localized(withArguments args: CVarArg...) -> String {
        let format = NSLocalizedString(self, comment: "")
        return String(format: format, arguments: args)
    }
}

// MARK: - Localization Keys Struct

struct LocalizationKeys {
    // MARK: - Tab Navigation
    static let tabClouds = "tab.clouds"
    static let tabPet = "tab.pet"
    static let tabPlant = "tab.plant"
    static let tabJournal = "tab.journal"
    static let tabShop = "tab.shop"

    // MARK: - Authentication
    static let authLogin = "auth.login"
    static let authLogout = "auth.logout"
    static let authSignInWithApple = "auth.signInWithApple"
    static let authSignInWithGoogle = "auth.signInWithGoogle"
    static let authSignInWithEmail = "auth.signInWithEmail"
    static let authEmail = "auth.email"
    static let authPassword = "auth.password"
    static let authRegister = "auth.register"
    static let authGuest = "auth.guest"
    static let authGuestLimited = "auth.guestLimited"

    // MARK: - Cloud Posts
    static let cloudTitle = "cloud.title"
    static let cloudNewPost = "cloud.newPost"
    static let cloudPost = "cloud.post"
    static let cloudDelete = "cloud.delete"
    static let cloudTranslate = "cloud.translate"
    static let cloudRestore = "cloud.restore"
    static let cloudMood = "cloud.mood"
    static let cloudMoodHappy = "cloud.moodHappy"
    static let cloudMoodSad = "cloud.moodSad"
    static let cloudMoodAngry = "cloud.moodAngry"
    static let cloudMoodAnxious = "cloud.moodAnxious"
    static let cloudMoodTired = "cloud.moodTired"
    static let cloudMoodConfused = "cloud.moodConfused"
    static let cloudMoodHopeful = "cloud.moodHopeful"
    static let cloudMoodCalm = "cloud.moodCalm"
    static let cloudReply = "cloud.reply"
    static let cloudCharacter = "cloud.character"
    static let cloudEmptyState = "cloud.emptyState"
    static let cloudPostSuccess = "cloud.postSuccess"

    // MARK: - Pet
    static let petTitle = "pet.title"
    static let petFeed = "pet.feed"
    static let petPet = "pet.pet"
    static let petRest = "pet.rest"
    static let petHunger = "pet.hunger"
    static let petEnergy = "pet.energy"
    static let petMood = "pet.mood"
    static let petLevel = "pet.level"
    static let petExperience = "pet.experience"
    static let petHome = "pet.home"
    static let petDecorations = "pet.decorations"
    static let petSkins = "pet.skins"
    static let petTheme = "pet.theme"
    static let petThemeDay = "pet.themeDay"
    static let petThemeNight = "pet.themeNight"
    static let petThemeSunset = "pet.themeSunset"
    static let petThemeGarden = "pet.themeGarden"

    // MARK: - Plant
    static let plantTitle = "plant.title"
    static let plantWater = "plant.water"
    static let plantHealth = "plant.health"
    static let plantHydration = "plant.hydration"
    static let plantStage = "plant.stage"
    static let plantSeed = "plant.seed"
    static let plantSprout = "plant.sprout"
    static let plantGrowing = "plant.growing"
    static let plantBlooming = "plant.blooming"
    static let plantMature = "plant.mature"
    static let plantLastWatered = "plant.lastWatered"
    static let plantEmptyState = "plant.emptyState"
    static let plantCreate = "plant.create"

    // MARK: - Journal
    static let journalTitle = "journal.title"
    static let journalWrite = "journal.write"
    static let journalNewEntry = "journal.newEntry"
    static let journalPrompt = "journal.prompt"
    static let journalEntries = "journal.entries"
    static let journalEntryCount = "journal.entryCount"
    static let journalThisWeek = "journal.thisWeek"
    static let journalThisMonth = "journal.thisMonth"
    static let journalReward = "journal.reward"
    static let journalClaimed = "journal.claimed"
    static let journalClaim = "journal.claim"
    static let journalEmptyState = "journal.emptyState"

    // MARK: - Shop
    static let shopTitle = "shop.title"
    static let shopDecorations = "shop.decorations"
    static let shopFood = "shop.food"
    static let shopSkins = "shop.skins"
    static let shopPrice = "shop.price"
    static let shopOwned = "shop.owned"
    static let shopPurchase = "shop.purchase"
    static let shopInsufficient = "shop.insufficient"
    static let shopCurrencyFood = "shop.currency.food"
    static let shopCurrencyDecorToken = "shop.currency.decorToken"
    static let shopCurrencyGems = "shop.currency.gems"

    // MARK: - Tasks
    static let taskTitle = "task.title"
    static let taskDaily = "task.daily"
    static let taskWeekly = "task.weekly"
    static let taskCompleted = "task.completed"
    static let taskPending = "task.pending"
    static let taskReward = "task.reward"
    static let taskComplete = "task.complete"
    static let taskReset = "task.reset"
    static let taskProgress = "task.progress"

    // MARK: - Settings
    static let settingsTitle = "settings.title"
    static let settingsAccount = "settings.account"
    static let settingsProfile = "settings.profile"
    static let settingsLanguage = "settings.language"
    static let settingsPrivacy = "settings.privacy"
    static let settingsNotifications = "settings.notifications"
    static let settingsAbout = "settings.about"
    static let settingsVersion = "settings.version"
    static let settingsLogout = "settings.logout"
    static let settingsDeleteAccount = "settings.deleteAccount"
    static let settingsPrivacyPolicy = "settings.privacyPolicy"
    static let settingsTermsOfService = "settings.termsOfService"
    static let settingsAnonymous = "settings.anonymous"
    static let settingsAnonymityExplained = "settings.anonymityExplained"
    static let settingsContentModeration = "settings.contentModeration"
    static let settingsModerationInfo = "settings.moderationInfo"

    // MARK: - General
    static let generalYes = "general.yes"
    static let generalNo = "general.no"
    static let generalClose = "general.close"
    static let generalSave = "general.save"
    static let generalCancel = "general.cancel"
    static let generalDelete = "general.delete"
    static let generalEdit = "general.edit"
    static let generalDone = "general.done"
    static let generalLoading = "general.loading"
    static let generalError = "general.error"
    static let generalSuccess = "general.success"
    static let generalTryAgain = "general.tryAgain"
    static let generalConfirm = "general.confirm"
    static let generalConfirmDelete = "general.confirmDelete"
}

// MARK: - Text View Modifier for Localization

struct LocalizedText: View {
    let key: String
    let comment: String

    init(_ key: String, comment: String = "") {
        self.key = key
        self.comment = comment
    }

    var body: some View {
        Text(NSLocalizedString(key, comment: comment))
    }
}
