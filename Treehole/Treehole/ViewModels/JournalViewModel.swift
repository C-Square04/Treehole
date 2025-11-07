//
//  JournalViewModel.swift
//  Treehole
//
//  Created by Kayli Cheung & Jimmy Chen on 2025-11-06.
//

import Foundation
import Combine

class JournalViewModel: ObservableObject {
    @Published var entries: [JournalEntry] = []
    @Published var currentPrompt: JournalPrompt = JournalPrompt.defaultPrompts.first ?? JournalPrompt(id: "1", text: "How are you today?", category: "reflection", language: .english)
    @Published var draftText: String = ""

    init() {
        loadEntries()
        selectRandomPrompt()
    }

    // MARK: - Entry Management

    func createEntry(mood: CloudPost.MoodTag, text: String) -> JournalEntry {
        let entry = JournalEntry(
            id: UUID().uuidString,
            createdAt: Date(),
            mood: mood,
            text: text,
            rewardGranted: false
        )
        entries.insert(entry, at: 0)
        saveEntries()
        return entry
    }

    func deleteEntry(_ entry: JournalEntry) {
        entries.removeAll { $0.id == entry.id }
        saveEntries()
    }

    func grantReward(to entry: inout JournalEntry, economy: inout EconomyLedger) {
        if !entry.rewardGranted {
            entry.rewardGranted = true
            economy.addFood(entry.foodReward)
            economy.addDecorToken(entry.decorTokenReward)
            saveEntries()
            objectWillChange.send()
        }
    }

    // MARK: - Prompt Management

    func selectRandomPrompt() {
        currentPrompt = JournalPrompt.defaultPrompts.randomElement() ??
                        JournalPrompt.defaultPrompts.first ??
                        JournalPrompt(id: "default", text: "How are you feeling today?", category: "general", language: .english)
        draftText = ""
    }

    func selectPrompt(_ prompt: JournalPrompt) {
        currentPrompt = prompt
        draftText = ""
    }

    // MARK: - Statistics

    var totalEntries: Int {
        entries.count
    }

    var thisWeekEntries: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return entries.filter { $0.createdAt > weekAgo }.count
    }

    var thisMonthEntries: Int {
        let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        return entries.filter { $0.createdAt > monthAgo }.count
    }

    var todayEntry: JournalEntry? {
        let calendar = Calendar.current
        return entries.first { calendar.isDateInToday($0.createdAt) }
    }

    var mostCommonMood: CloudPost.MoodTag? {
        let moods = entries.map { $0.mood }
        return moods.max { a, b in
            moods.filter { $0 == a }.count < moods.filter { $0 == b }.count
        }
    }

    // MARK: - Persistence

    func saveEntries() {
        do {
            let encoded = try JSONEncoder().encode(entries)
            UserDefaults.standard.set(encoded, forKey: "journalEntries")
        } catch {
            print("ERROR: Failed to encode journal entries: \(error)")
        }
    }

    func loadEntries() {
        if let data = UserDefaults.standard.data(forKey: "journalEntries") {
            do {
                let loaded = try JSONDecoder().decode([JournalEntry].self, from: data)
                entries = loaded
            } catch {
                print("ERROR: Failed to decode journal entries: \(error)")
            }
        }
    }
}
