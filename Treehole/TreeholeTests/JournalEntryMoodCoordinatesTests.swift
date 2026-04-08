//
//  JournalEntryMoodCoordinatesTests.swift
//  TreeholeTests
//

import Testing
import SwiftData
import Foundation
@testable import Treehole

@Suite("JournalEntry Mood Coordinates Tests")
struct JournalEntryMoodCoordinatesTests {

    private func makeContainer() throws -> (ModelContainer, ModelContext) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: JournalEntry.self, configurations: config)
        let context = ModelContext(container)
        return (container, context)
    }

    // moodValence and moodArousal default to nil on a new entry
    @Test func testMoodCoordsDefaultToNil() throws {
        let entry = JournalEntry(moodTag: .calm, text: "Test")
        #expect(entry.moodValence == nil)
        #expect(entry.moodArousal == nil)
    }

    // effectiveValence falls back to MoodTag default when moodValence is nil
    @Test func testEffectiveValenceFallsBackToDefault() throws {
        let entry = JournalEntry(moodTag: .excited, text: "Test")
        #expect(entry.moodValence == nil)
        #expect(entry.effectiveValence == MoodTag.excited.defaultValence)
        #expect(entry.effectiveValence == 0.8)
    }

    // effectiveArousal falls back to MoodTag default when moodArousal is nil
    @Test func testEffectiveArousalFallsBackToDefault() throws {
        let entry = JournalEntry(moodTag: .angry, text: "Test")
        #expect(entry.moodArousal == nil)
        #expect(entry.effectiveArousal == MoodTag.angry.defaultArousal)
        #expect(entry.effectiveArousal == 0.85)
    }

    // effectiveValence returns custom value when moodValence is set
    @Test func testEffectiveValenceReturnsCustomValue() throws {
        let entry = JournalEntry(moodTag: .calm, text: "Test")
        entry.moodValence = 0.42
        #expect(entry.effectiveValence == 0.42)
    }

    // effectiveArousal returns custom value when moodArousal is set
    @Test func testEffectiveArousalReturnsCustomValue() throws {
        let entry = JournalEntry(moodTag: .calm, text: "Test")
        entry.moodArousal = 0.77
        #expect(entry.effectiveArousal == 0.77)
    }

    // Both custom coords can be set independently and read back
    @Test func testBothCustomCoordsSetAndRead() throws {
        let entry = JournalEntry(moodTag: .happy, text: "Custom coords")
        entry.moodValence = -0.3
        entry.moodArousal = 0.65
        #expect(entry.moodValence == -0.3)
        #expect(entry.moodArousal == 0.65)
        #expect(entry.effectiveValence == -0.3)
        #expect(entry.effectiveArousal == 0.65)
    }

    // SwiftData round-trip: save with custom coords, fetch, verify
    @Test func testSwiftDataRoundTrip() throws {
        let (container, context) = try makeContainer()
        let entry = JournalEntry(moodTag: .stressed, text: "Round trip test")
        entry.moodValence = -0.45
        entry.moodArousal = 0.72
        context.insert(entry)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<JournalEntry>())
        #expect(fetched.count == 1)
        #expect(fetched[0].moodValence == -0.45)
        #expect(fetched[0].moodArousal == 0.72)
        #expect(fetched[0].effectiveValence == -0.45)
        #expect(fetched[0].effectiveArousal == 0.72)
        _ = container
    }

    // Existing entries without custom coords still use MoodTag defaults (backward compat)
    @Test func testBackwardCompatibilityNilCoords() throws {
        let (_, context) = try makeContainer()
        let entry = JournalEntry(moodTag: .hopeful, text: "Old entry")
        context.insert(entry)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<JournalEntry>())
        #expect(fetched.count == 1)
        #expect(fetched[0].moodValence == nil)
        #expect(fetched[0].moodArousal == nil)
        // effectiveValence/Arousal should use MoodTag defaults
        #expect(fetched[0].effectiveValence == MoodTag.hopeful.defaultValence)
        #expect(fetched[0].effectiveArousal == MoodTag.hopeful.defaultArousal)
    }
}
