//
//  JournalEntryFieldsTests.swift
//  TreeholeTests
//

import Testing
import SwiftData
import Foundation
@testable import Treehole

@Suite("JournalEntry New Fields Tests")
struct JournalEntryFieldsTests {

    private func makeJournalContainer() throws -> (ModelContainer, ModelContext) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: JournalEntry.self, configurations: config)
        let context = ModelContext(container)
        return (container, context)
    }

    // All new fields default to nil on a fresh JournalEntry.
    @Test func testNewFieldsDefaultToNil() throws {
        let entry = JournalEntry(moodTag: .calm, text: "Test")
        #expect(entry.audioFilename == nil)
        #expect(entry.audioTranscript == nil)
        #expect(entry.audioDurationSeconds == nil)
        #expect(entry.latitude == nil)
        #expect(entry.longitude == nil)
        #expect(entry.locationName == nil)
    }

    // Audio fields can be set and read back.
    @Test func testAudioFieldsSetAndRead() throws {
        let (_, _) = try makeJournalContainer()
        let entry = JournalEntry(moodTag: .happy, text: "Voice entry")
        entry.audioFilename = "test-audio.m4a"
        entry.audioTranscript = "Hello world"
        entry.audioDurationSeconds = 42.5
        #expect(entry.audioFilename == "test-audio.m4a")
        #expect(entry.audioTranscript == "Hello world")
        #expect(entry.audioDurationSeconds == 42.5)
    }

    // Location fields can be set and read back.
    @Test func testLocationFieldsSetAndRead() throws {
        let (_, _) = try makeJournalContainer()
        let entry = JournalEntry(moodTag: .calm, text: "Location entry")
        entry.latitude = 37.7749
        entry.longitude = -122.4194
        entry.locationName = "San Francisco, CA"
        #expect(entry.latitude == 37.7749)
        #expect(entry.longitude == -122.4194)
        #expect(entry.locationName == "San Francisco, CA")
    }

    // JournalEntry persists new fields via in-memory SwiftData.
    @Test func testAudioFieldsPersistedViaSwiftData() throws {
        let (container, context) = try makeJournalContainer()
        let entry = JournalEntry(moodTag: .hopeful, text: "Persisted audio")
        entry.audioFilename = "persisted-audio.m4a"
        entry.audioDurationSeconds = 120.0
        entry.audioTranscript = "Transcribed text"
        context.insert(entry)
        try context.save()

        let fetchDescriptor = FetchDescriptor<JournalEntry>()
        let fetched = try context.fetch(fetchDescriptor)
        #expect(fetched.count == 1)
        #expect(fetched[0].audioFilename == "persisted-audio.m4a")
        #expect(fetched[0].audioDurationSeconds == 120.0)
        #expect(fetched[0].audioTranscript == "Transcribed text")
        _ = container
    }

    // JournalEntry persists location fields via in-memory SwiftData.
    @Test func testLocationFieldsPersistedViaSwiftData() throws {
        let (container, context) = try makeJournalContainer()
        let entry = JournalEntry(moodTag: .anxious, text: "Persisted location")
        entry.latitude = 51.5074
        entry.longitude = -0.1278
        entry.locationName = "London, England"
        context.insert(entry)
        try context.save()

        let fetchDescriptor = FetchDescriptor<JournalEntry>()
        let fetched = try context.fetch(fetchDescriptor)
        #expect(fetched.count == 1)
        #expect(fetched[0].latitude == 51.5074)
        #expect(fetched[0].longitude == -0.1278)
        #expect(fetched[0].locationName == "London, England")
        _ = container
    }

    // Existing entries without the new fields still have nil for audio/location.
    @Test func testExistingEntryCompatibility() throws {
        let (_, context) = try makeJournalContainer()
        let entry = JournalEntry(moodTag: .sad, text: "Old entry")
        context.insert(entry)
        try context.save()

        // New fields must be nil (backward compat)
        #expect(entry.audioFilename == nil)
        #expect(entry.latitude == nil)
        #expect(entry.locationName == nil)
    }
}
