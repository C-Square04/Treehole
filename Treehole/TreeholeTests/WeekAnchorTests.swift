//
//  WeekAnchorTests.swift
//  TreeholeTests
//

import Testing
import Foundation
@testable import Treehole

@Suite("Week Anchor Tests")
struct WeekAnchorTests {

    private let cal = Calendar.current

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 10) -> Date {
        cal.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    // 2026-07-13 is a Monday; 2026-07-19 is the following Sunday.

    // MARK: - isoWeekday

    @Test func testIsoWeekdayMondayIsOne() {
        #expect(WeekAnchor.isoWeekday(date(2026, 7, 13), calendar: cal) == 1)
    }

    @Test func testIsoWeekdaySundayIsSeven() {
        #expect(WeekAnchor.isoWeekday(date(2026, 7, 19), calendar: cal) == 7)
    }

    @Test func testIsoWeekdayMidweek() {
        #expect(WeekAnchor.isoWeekday(date(2026, 7, 15), calendar: cal) == 3)  // Wednesday
    }

    // MARK: - weekStart

    @Test func testWeekStartOfMidweekDateIsMonday() {
        let start = WeekAnchor.weekStart(containing: date(2026, 7, 15), calendar: cal)
        #expect(start == cal.startOfDay(for: date(2026, 7, 13)))
    }

    @Test func testWeekStartOfMondayIsItself() {
        let start = WeekAnchor.weekStart(containing: date(2026, 7, 13), calendar: cal)
        #expect(start == cal.startOfDay(for: date(2026, 7, 13)))
    }

    @Test func testSundayBelongsToPrecedingMondayWeek() {
        // The regression this guards: a Sunday-start week would treat Sunday
        // as the beginning of a NEW week and orphan the Mon-Sat just lived.
        let start = WeekAnchor.weekStart(containing: date(2026, 7, 19), calendar: cal)
        #expect(start == cal.startOfDay(for: date(2026, 7, 13)))
    }

    @Test func testWeekStartOffsetGoesBackWholeWeeks() {
        let start = WeekAnchor.weekStart(containing: date(2026, 7, 15), offset: -1, calendar: cal)
        #expect(start == cal.startOfDay(for: date(2026, 7, 6)))
    }

    @Test func testWeekStartIsStartOfDay() {
        let start = WeekAnchor.weekStart(containing: date(2026, 7, 15), calendar: cal)
        #expect(start == cal.startOfDay(for: start))
    }
}
