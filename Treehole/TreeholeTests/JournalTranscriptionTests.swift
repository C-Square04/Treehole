//
//  JournalTranscriptionTests.swift
//  TreeholeTests
//

import Testing
import SwiftData
import Foundation
import Speech
@testable import Treehole

// MARK: - Transcript Selection Tests

@Suite("Journal Transcription Pick Tests")
struct JournalTranscriptionPickTests {

    @Test func testBothNilReturnsNil() {
        #expect(JournalTranscription.pick(zh: nil, en: nil) == nil)
    }

    @Test func testEmptyZhOnlyCollapsesToNil() {
        #expect(JournalTranscription.pick(zh: "", en: nil) == nil)
    }

    @Test func testEmptyEnOnlyCollapsesToNil() {
        #expect(JournalTranscription.pick(zh: nil, en: "") == nil)
    }

    @Test func testBothEmptyCollapsesToNil() {
        #expect(JournalTranscription.pick(zh: "", en: "") == nil)
    }

    @Test func testEnOnly() {
        #expect(JournalTranscription.pick(zh: nil, en: "hello there") == "hello there")
    }

    @Test func testZhOnly() {
        #expect(JournalTranscription.pick(zh: "你好世界", en: nil) == "你好世界")
    }

    @Test func testZhLongerWins() {
        #expect(JournalTranscription.pick(zh: "今天天气很好", en: "nice") == "今天天气很好")
    }

    @Test func testEnLongerWins() {
        #expect(JournalTranscription.pick(zh: "你好", en: "a much longer english transcript") == "a much longer english transcript")
    }

    @Test func testEqualLengthTiePrefersZh() {
        #expect(JournalTranscription.pick(zh: "abc", en: "xyz") == "abc")
    }

    @Test func testEmptyZhLosesToNonEmptyEn() {
        #expect(JournalTranscription.pick(zh: "", en: "hi") == "hi")
    }

    @Test func testEmptyEnLosesToNonEmptyZh() {
        #expect(JournalTranscription.pick(zh: "你好", en: "") == "你好")
    }

    // MARK: - Permission gate

    @Test func testCanTranscribeOnlyWhenAuthorized() {
        #expect(JournalTranscription.canTranscribe(status: .authorized))
        #expect(!JournalTranscription.canTranscribe(status: .notDetermined))
        #expect(!JournalTranscription.canTranscribe(status: .denied))
        #expect(!JournalTranscription.canTranscribe(status: .restricted))
    }

    // MARK: - Recognition locales

    @Test func testRecognitionLocalesAreZhThenEn() {
        #expect(JournalTranscription.recognitionLocales.map(\.identifier) == ["zh-CN", "en-US"])
    }
}

// MARK: - Late Transcript Persistence Tests

@Suite("Journal Transcription Apply Tests")
@MainActor
struct JournalTranscriptionApplyTests {

    private func makeJournalContainer() throws -> (ModelContainer, ModelContext) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: JournalEntry.self, configurations: config)
        let context = ModelContext(container)
        return (container, context)
    }

    @Test func testApplyWritesTranscriptToMatchingEntry() throws {
        let (_, context) = try makeJournalContainer()
        let entry = JournalEntry(moodTag: .calm, text: "voice note entry")
        entry.audioFilename = "take1.m4a"
        context.insert(entry)
        try context.save()

        let applied = JournalTranscription.apply(
            transcript: "hello world",
            toEntryWithAudioFilename: "take1.m4a",
            context: context
        )
        #expect(applied)
        #expect(entry.audioTranscript == "hello world")
    }

    @Test func testApplyIsNoOpWhenNoEntryOwnsTheFilename() throws {
        // Editor cancelled: the recording was never attached to a saved entry.
        let (_, context) = try makeJournalContainer()
        let entry = JournalEntry(moodTag: .calm, text: "other entry")
        entry.audioFilename = "other.m4a"
        context.insert(entry)
        try context.save()

        let applied = JournalTranscription.apply(
            transcript: "orphaned transcript",
            toEntryWithAudioFilename: "cancelled.m4a",
            context: context
        )
        #expect(!applied)
        #expect(entry.audioTranscript == nil)
    }

    @Test func testApplyIsNoOpForNilTranscript() throws {
        let (_, context) = try makeJournalContainer()
        let entry = JournalEntry(moodTag: .calm, text: "entry")
        entry.audioFilename = "take1.m4a"
        entry.audioTranscript = "existing transcript"
        context.insert(entry)
        try context.save()

        let applied = JournalTranscription.apply(
            transcript: nil,
            toEntryWithAudioFilename: "take1.m4a",
            context: context
        )
        #expect(!applied)
        #expect(entry.audioTranscript == "existing transcript")
    }
}
