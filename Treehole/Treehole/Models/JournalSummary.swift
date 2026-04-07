import Foundation
import SwiftData

@Model
final class JournalSummary {
    enum Kind: String, Codable { case weekly, single, insights }

    var id: UUID = UUID()
    var kindRaw: String = "weekly"
    var periodStart: Date = Date()  // For weekly: start of week. For single: entry date. For insights: start of analyzed window.
    var periodEnd: Date = Date()
    var summary: String = ""
    var language: String = "en"
    var generatedAt: Date = Date()
    /// For single-entry summaries, the journal entry's UUID string. Nil otherwise.
    var sourceEntryId: String? = nil

    init(kind: Kind, periodStart: Date, periodEnd: Date, summary: String, language: String, sourceEntryId: String? = nil) {
        self.id = UUID()
        self.kindRaw = kind.rawValue
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.summary = summary
        self.language = language
        self.generatedAt = Date()
        self.sourceEntryId = sourceEntryId
    }

    var kind: Kind { Kind(rawValue: kindRaw) ?? .weekly }
}
