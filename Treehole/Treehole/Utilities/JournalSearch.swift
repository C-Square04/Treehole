import Foundation

/// The single source of truth for journal search: JournalView.filteredEntries
/// and the unit tests both call this, so the two can't silently diverge.
enum JournalSearch {

    /// Sorts by displayDate descending, then filters by a case-insensitive
    /// match across text, title, audio transcript, and location name.
    /// An empty (or whitespace-only) query returns all entries, still sorted.
    static func filter(_ entries: [JournalEntry], query: String) -> [JournalEntry] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        // The @Query source is already createdAt-descending — a full re-sort
        // per keystroke is only needed when a custom entryDate (or a
        // caller-supplied order) breaks that, so check in O(n) first.
        let sorted = isSortedByDisplayDateDescending(entries)
            ? entries
            : entries.sorted { $0.displayDate > $1.displayDate }
        guard !trimmed.isEmpty else { return sorted }
        return sorted.filter { entry in
            matches(entry.text, trimmed) ||
            matches(entry.title, trimmed) ||
            matches(entry.audioTranscript, trimmed) ||
            matches(entry.locationName, trimmed)
        }
    }

    /// range(of:options:) matches case-insensitively without allocating a
    /// lowercased copy of every field on every keystroke.
    private static func matches(_ text: String?, _ query: String) -> Bool {
        text?.range(of: query, options: .caseInsensitive) != nil
    }

    private static func isSortedByDisplayDateDescending(_ entries: [JournalEntry]) -> Bool {
        var previous: Date?
        for entry in entries {
            let date = entry.displayDate
            if let previous, date > previous { return false }
            previous = date
        }
        return true
    }
}
