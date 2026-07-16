import Foundation

/// The single source of truth for journal search: JournalView.filteredEntries
/// and the unit tests both call this, so the two can't silently diverge.
enum JournalSearch {

    /// Sorts by displayDate descending, then filters by a case-insensitive
    /// match across text, title, audio transcript, and location name.
    /// An empty (or whitespace-only) query returns all entries, still sorted.
    static func filter(_ entries: [JournalEntry], query: String) -> [JournalEntry] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        let sorted = entries.sorted { $0.displayDate > $1.displayDate }
        guard !trimmed.isEmpty else { return sorted }
        let lowered = trimmed.lowercased()
        return sorted.filter { entry in
            entry.text.lowercased().contains(lowered) ||
            (entry.title?.lowercased().contains(lowered) ?? false) ||
            (entry.audioTranscript?.lowercased().contains(lowered) ?? false) ||
            (entry.locationName?.lowercased().contains(lowered) ?? false)
        }
    }
}
