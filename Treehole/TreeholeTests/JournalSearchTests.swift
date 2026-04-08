//
//  JournalSearchTests.swift
//  TreeholeTests
//

import Testing
import Foundation
@testable import Treehole

@Suite("Journal Search Tests")
struct JournalSearchTests {

    // Helper: apply the same filter logic as JournalView.filteredEntries
    private func filter(entries: [JournalEntry], query: String) -> [JournalEntry] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return entries }
        let lowered = trimmed.lowercased()
        return entries.filter { entry in
            entry.text.lowercased().contains(lowered) ||
            (entry.title?.lowercased().contains(lowered) ?? false) ||
            (entry.audioTranscript?.lowercased().contains(lowered) ?? false) ||
            (entry.locationName?.lowercased().contains(lowered) ?? false)
        }
    }

    private func makeEntry(text: String = "",
                           title: String? = nil,
                           transcript: String? = nil,
                           location: String? = nil) -> JournalEntry {
        let entry = JournalEntry(moodTag: .calm, text: text)
        entry.title = title
        entry.audioTranscript = transcript
        entry.locationName = location
        return entry
    }

    // MARK: - Filter by text content

    @Test func testFilterByTextContent() {
        let entries = [
            makeEntry(text: "Today I went hiking"),
            makeEntry(text: "Had a great coffee"),
            makeEntry(text: "Feeling anxious about work"),
        ]
        let results = filter(entries: entries, query: "coffee")
        #expect(results.count == 1)
        #expect(results[0].text == "Had a great coffee")
    }

    // MARK: - Filter by title

    @Test func testFilterByTitle() {
        let entries = [
            makeEntry(text: "some text", title: "Morning Reflections"),
            makeEntry(text: "another text", title: "Evening Walk"),
            makeEntry(text: "plain"),
        ]
        let results = filter(entries: entries, query: "morning")
        #expect(results.count == 1)
        #expect(results[0].title == "Morning Reflections")
    }

    // MARK: - Filter by audio transcript

    @Test func testFilterByAudioTranscript() {
        let entries = [
            makeEntry(text: "written note", transcript: "I said something important today"),
            makeEntry(text: "another note", transcript: "just rambling"),
            makeEntry(text: "no audio"),
        ]
        let results = filter(entries: entries, query: "important")
        #expect(results.count == 1)
        #expect(results[0].audioTranscript == "I said something important today")
    }

    // MARK: - Filter by location name

    @Test func testFilterByLocationName() {
        let entries = [
            makeEntry(text: "entry 1", location: "Central Park, New York"),
            makeEntry(text: "entry 2", location: "Golden Gate Bridge"),
            makeEntry(text: "no location"),
        ]
        let results = filter(entries: entries, query: "new york")
        #expect(results.count == 1)
        #expect(results[0].locationName == "Central Park, New York")
    }

    // MARK: - Empty search returns all

    @Test func testEmptySearchReturnsAll() {
        let entries = [
            makeEntry(text: "entry 1"),
            makeEntry(text: "entry 2"),
            makeEntry(text: "entry 3"),
        ]
        let results = filter(entries: entries, query: "")
        #expect(results.count == 3)
    }

    @Test func testWhitespaceOnlySearchReturnsAll() {
        let entries = [
            makeEntry(text: "entry 1"),
            makeEntry(text: "entry 2"),
        ]
        let results = filter(entries: entries, query: "   ")
        #expect(results.count == 2)
    }

    // MARK: - Case-insensitive matching

    @Test func testCaseInsensitiveMatchText() {
        let entries = [
            makeEntry(text: "UPPERCASE ENTRY"),
            makeEntry(text: "lowercase entry"),
        ]
        let results = filter(entries: entries, query: "uppercase")
        #expect(results.count == 1)
    }

    @Test func testCaseInsensitiveMatchTitle() {
        let entries = [
            makeEntry(text: "body", title: "MyTitle"),
        ]
        let results = filter(entries: entries, query: "mytitle")
        #expect(results.count == 1)
    }

    // MARK: - Multi-field match (single entry matches multiple fields)

    @Test func testMatchAcrossMultipleFields() {
        let entries = [
            makeEntry(text: "nothing", title: "nothing", transcript: "target word", location: "nowhere"),
            makeEntry(text: "no match here"),
        ]
        let results = filter(entries: entries, query: "target")
        #expect(results.count == 1)
        #expect(results[0].audioTranscript?.contains("target") == true)
    }

    // MARK: - No match returns empty

    @Test func testNoMatchReturnsEmpty() {
        let entries = [
            makeEntry(text: "apples and oranges"),
            makeEntry(text: "bananas"),
        ]
        let results = filter(entries: entries, query: "xyzzy")
        #expect(results.isEmpty)
    }
}
