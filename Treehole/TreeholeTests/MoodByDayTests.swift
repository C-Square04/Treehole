//
//  MoodByDayTests.swift
//  TreeholeTests
//

import Testing
import Foundation
@testable import Treehole

@Suite("MoodByDay Tests")
struct MoodByDayTests {

    private let calendar = Calendar.current

    private func makeEntry(mood: MoodTag,
                           createdAt: Date,
                           entryDate: Date? = nil) -> JournalEntry {
        let entry = JournalEntry(moodTag: mood, text: "entry")
        entry.createdAt = createdAt
        entry.entryDate = entryDate
        return entry
    }

    @Test func testEmptyEntriesGiveEmptyMap() {
        let map = MoodByDay.firstMoodPerDay(entries: [], calendar: calendar)
        #expect(map.isEmpty)
    }

    @Test func testKeysAreStartOfDay() {
        let now = Date()
        let map = MoodByDay.firstMoodPerDay(
            entries: [makeEntry(mood: .happy, createdAt: now)],
            calendar: calendar
        )
        #expect(map[calendar.startOfDay(for: now)] == .happy)
        #expect(map.count == 1)
    }

    // The week strip shows the FIRST matching entry's mood per day, and
    // entries arrive createdAt-descending — array order must win.
    @Test func testFirstEntryInArrayOrderWinsPerDay() {
        let now = Date()
        let earlier = now.addingTimeInterval(-3600)
        let entries = [
            makeEntry(mood: .happy, createdAt: now),
            makeEntry(mood: .sad, createdAt: earlier),
        ]
        let map = MoodByDay.firstMoodPerDay(entries: entries, calendar: calendar)
        #expect(map[calendar.startOfDay(for: now)] == .happy)
    }

    @Test func testUsesDisplayDateOverCreatedAt() {
        let now = Date()
        let lastWeek = now.addingTimeInterval(-7 * 86400)
        // Backdated entry: written now, about last week.
        let entry = makeEntry(mood: .calm, createdAt: now, entryDate: lastWeek)
        let map = MoodByDay.firstMoodPerDay(entries: [entry], calendar: calendar)
        #expect(map[calendar.startOfDay(for: lastWeek)] == .calm)
        #expect(map[calendar.startOfDay(for: now)] == nil)
    }

    @Test func testSeparateDaysGetSeparateMoods() {
        let now = Date()
        let yesterday = now.addingTimeInterval(-86400)
        let entries = [
            makeEntry(mood: .excited, createdAt: now),
            makeEntry(mood: .tired, createdAt: yesterday),
        ]
        let map = MoodByDay.firstMoodPerDay(entries: entries, calendar: calendar)
        #expect(map[calendar.startOfDay(for: now)] == .excited)
        #expect(map[calendar.startOfDay(for: yesterday)] == .tired)
    }
}
