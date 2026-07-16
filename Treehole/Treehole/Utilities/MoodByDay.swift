import Foundation

/// Builds the day → mood lookup used by calendar-style views (mood week
/// strip). The FIRST entry in array order wins for each day, matching a
/// per-day `entries.first { isDate(inSameDayAs:) }` scan — entries arrive
/// createdAt-descending, so that's the most recently written entry.
enum MoodByDay {

    static func firstMoodPerDay(
        entries: [JournalEntry],
        calendar: Calendar = .current
    ) -> [Date: MoodTag] {
        var map: [Date: MoodTag] = [:]
        for entry in entries {
            let day = calendar.startOfDay(for: entry.displayDate)
            if map[day] == nil {
                map[day] = entry.moodTag
            }
        }
        return map
    }
}
