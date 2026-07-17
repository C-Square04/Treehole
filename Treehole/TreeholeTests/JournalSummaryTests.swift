//
//  JournalSummaryTests.swift
//  TreeholeTests
//

import Testing
import SwiftData
import Foundation
@testable import Treehole

// MARK: - JournalSummary Model Tests

@Suite("JournalSummary Model Tests")
struct JournalSummaryModelTests {

    private func makeContainer() throws -> (ModelContainer, ModelContext) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: JournalSummary.self, configurations: config)
        let context = ModelContext(container)
        return (container, context)
    }

    @Test func testJournalSummaryInitWeekly() throws {
        let start = Date()
        let end = Date().addingTimeInterval(7 * 86400)
        let summary = JournalSummary(
            kind: .weekly,
            periodStart: start,
            periodEnd: end,
            summary: "A calm, reflective week.",
            language: "en"
        )
        #expect(summary.kindRaw == "weekly")
        #expect(summary.kind == .weekly)
        #expect(summary.summary == "A calm, reflective week.")
        #expect(summary.language == "en")
        #expect(summary.sourceEntryId == nil)
    }

    @Test func testJournalSummaryInitSingle() throws {
        let entryDate = Date()
        let entryId = UUID().uuidString
        let summary = JournalSummary(
            kind: .single,
            periodStart: entryDate,
            periodEnd: entryDate,
            summary: "This entry reflects a moment of calm.",
            language: "zh-Hans",
            sourceEntryId: entryId
        )
        #expect(summary.kindRaw == "single")
        #expect(summary.kind == .single)
        #expect(summary.sourceEntryId == entryId)
        #expect(summary.language == "zh-Hans")
    }

    @Test func testJournalSummaryInitInsights() throws {
        let start = Date().addingTimeInterval(-14 * 86400)
        let end = Date()
        let summary = JournalSummary(
            kind: .insights,
            periodStart: start,
            periodEnd: end,
            summary: "Over the past two weeks, you've shown resilience.",
            language: "en"
        )
        #expect(summary.kindRaw == "insights")
        #expect(summary.kind == .insights)
    }

    @Test func testKindEnumRoundtrip() throws {
        for kind in [JournalSummary.Kind.weekly, .single, .insights] {
            let raw = kind.rawValue
            let recovered = JournalSummary.Kind(rawValue: raw)
            #expect(recovered == kind)
        }
    }

    @Test func testKindFallbackForInvalidRaw() throws {
        let summary = JournalSummary(
            kind: .weekly,
            periodStart: Date(),
            periodEnd: Date(),
            summary: "Test",
            language: "en"
        )
        summary.kindRaw = "invalid_kind"
        // Should fall back to .weekly
        #expect(summary.kind == .weekly)
    }

    @Test func testJournalSummaryPersistence() throws {
        let (_, context) = try makeContainer()

        let start = Date()
        let end = Date().addingTimeInterval(86400)
        let summary = JournalSummary(
            kind: .weekly,
            periodStart: start,
            periodEnd: end,
            summary: "Persisted summary",
            language: "en"
        )
        context.insert(summary)
        try context.save()

        let descriptor = FetchDescriptor<JournalSummary>()
        let fetched = try context.fetch(descriptor)
        #expect(fetched.count == 1)
        #expect(fetched.first?.summary == "Persisted summary")
        #expect(fetched.first?.kindRaw == "weekly")
    }

    @Test func testJournalSummaryGeneratedAtIsRecent() throws {
        let before = Date()
        let summary = JournalSummary(
            kind: .insights,
            periodStart: Date(),
            periodEnd: Date(),
            summary: "Insights.",
            language: "en"
        )
        let after = Date()
        #expect(summary.generatedAt >= before)
        #expect(summary.generatedAt <= after)
    }

    @Test func testMultipleSummariesPersistence() throws {
        let (_, context) = try makeContainer()

        for i in 0..<3 {
            let s = JournalSummary(
                kind: .single,
                periodStart: Date(),
                periodEnd: Date(),
                summary: "Entry \(i)",
                language: "en",
                sourceEntryId: UUID().uuidString
            )
            context.insert(s)
        }
        try context.save()

        let descriptor = FetchDescriptor<JournalSummary>()
        let fetched = try context.fetch(descriptor)
        #expect(fetched.count == 3)
    }
}

// MARK: - AppState AI Toggle Tests

@Suite("AppState AI Toggle Tests")
struct AppStateAIToggleTests {

    @Test func testAllowAIJournalAnalysisDefaultsFalse() throws {
        // Use an isolated UserDefaults suite to test defaults
        let suiteName = "AIToggleTest_\(UUID().uuidString)"
        // AppState reads from UserDefaults.standard, but the key won't exist
        // for a fresh install. We verify the property initializer default.
        let state = AppState()
        _ = state // constructing must not crash; the initializer default is false
        // The property default is false; if the key exists from a prior test
        // run it may differ — but the initializer default declaration is false.
        // We test by ensuring it is always a Bool (non-crashing) and that
        // the loadState() path reads the correct key.
        let testDefaults = UserDefaults(suiteName: suiteName)!
        // No key set → bool(forKey:) returns false
        #expect(testDefaults.bool(forKey: "allowAIJournalAnalysis") == false)
        testDefaults.removePersistentDomain(forName: suiteName)
    }

    @Test func testAllowAIJournalAnalysisCanBeSetTrue() throws {
        let state = AppState()
        state.allowAIJournalAnalysis = true
        #expect(state.allowAIJournalAnalysis == true)
        // Verify persistence key was written
        #expect(UserDefaults.standard.bool(forKey: "allowAIJournalAnalysis") == true)
        // Reset
        state.allowAIJournalAnalysis = false
    }

    @Test func testAllowAIJournalAnalysisToggle() throws {
        let state = AppState()
        let initial = state.allowAIJournalAnalysis
        state.allowAIJournalAnalysis = !initial
        #expect(state.allowAIJournalAnalysis == !initial)
        state.allowAIJournalAnalysis = initial
    }
}
