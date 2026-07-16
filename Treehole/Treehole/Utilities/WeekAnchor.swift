import Foundation

/// Monday-based week math shared by every journal surface (week strip,
/// mood stats, weekly AI summary). All week boundaries in the app are
/// Monday-start — never rely on Calendar.firstWeekday, which varies by locale.
enum WeekAnchor {

    /// ISO weekday: Mon=1 ... Sun=7
    static func isoWeekday(_ date: Date, calendar: Calendar = .current) -> Int {
        let raw = calendar.component(.weekday, from: date)  // Sun=1...Sat=7
        return raw == 1 ? 7 : raw - 1
    }

    /// Start-of-day Monday of the week containing `date`, shifted by `offset` weeks.
    static func weekStart(containing date: Date = Date(), offset: Int = 0, calendar: Calendar = .current) -> Date {
        let dow = isoWeekday(date, calendar: calendar)  // Mon=1..Sun=7
        let monday = calendar.date(byAdding: .day, value: -(dow - 1), to: calendar.startOfDay(for: date)) ?? date
        return calendar.date(byAdding: .weekOfYear, value: offset, to: monday) ?? monday
    }
}
