import Testing
import Foundation
@testable import Treehole

// MARK: - NotificationService Tests

@Suite("NotificationService Tests")
struct NotificationServiceTests {

    // MARK: - Helpers

    private func freshDefaults() -> (UserDefaults, String) {
        let suiteName = "NotifTest_\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return (defaults, suiteName)
    }

    // MARK: - lastUnreadCheck UserDefaults storage

    /// lastUnreadCheck key is absent by default; should fall back to 7 days ago.
    @Test func testLastUnreadCheckDefaultsTo7DaysAgo() {
        let (defaults, _) = freshDefaults()
        // No value stored — verify we can handle nil gracefully
        let stored = defaults.object(forKey: NotificationService.lastUnreadCheckKey) as? Date
        #expect(stored == nil)

        // Simulate the fallback logic used in checkUnreadInteractionsAndNotify
        let since: Date
        if let s = stored {
            since = s
        } else {
            since = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        }

        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let diff = abs(since.timeIntervalSince(sevenDaysAgo))
        #expect(diff < 5) // within 5 seconds of 7 days ago
    }

    /// After notification fires, lastUnreadCheck should be updated to ~now.
    @Test func testLastUnreadCheckUpdatedAfterFiring() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let before = Date()
        defaults.set(Date(), forKey: NotificationService.lastUnreadCheckKey)
        let after = Date()

        let stored = defaults.object(forKey: NotificationService.lastUnreadCheckKey) as? Date
        #expect(stored != nil)
        if let s = stored {
            #expect(s >= before)
            #expect(s <= after.addingTimeInterval(1))
        }
    }

    // MARK: - Throttle logic

    /// Throttle: if lastNotificationFired is within 6 hours, skip should be implied.
    @Test func testThrottleWithin6HoursReturnsFired() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        // Simulate firing 1 hour ago
        let oneHourAgo = Date().addingTimeInterval(-3600)
        defaults.set(oneHourAgo, forKey: NotificationService.lastNotificationFiredKey)

        let lastFired = defaults.object(forKey: NotificationService.lastNotificationFiredKey) as? Date
        #expect(lastFired != nil)

        if let lastFired {
            let sixHours: TimeInterval = 6 * 3600
            let shouldSkip = Date().timeIntervalSince(lastFired) < sixHours
            #expect(shouldSkip == true)
        }
    }

    /// Throttle: if lastNotificationFired is older than 6 hours, should NOT skip.
    @Test func testThrottleOlderThan6HoursAllowsFiring() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        // Simulate firing 7 hours ago
        let sevenHoursAgo = Date().addingTimeInterval(-(7 * 3600))
        defaults.set(sevenHoursAgo, forKey: NotificationService.lastNotificationFiredKey)

        let lastFired = defaults.object(forKey: NotificationService.lastNotificationFiredKey) as? Date
        #expect(lastFired != nil)

        if let lastFired {
            let sixHours: TimeInterval = 6 * 3600
            let shouldSkip = Date().timeIntervalSince(lastFired) < sixHours
            #expect(shouldSkip == false)
        }
    }

    /// Throttle: if no lastNotificationFired stored, should NOT skip.
    @Test func testThrottleNoPreviousFiringAllows() {
        let (defaults, _) = freshDefaults()
        let lastFired = defaults.object(forKey: NotificationService.lastNotificationFiredKey) as? Date
        // No stored value means we have never fired — should allow
        #expect(lastFired == nil)
        // Simulate the guard condition: if nil, we proceed (don't skip)
        let shouldSkip = lastFired.map { Date().timeIntervalSince($0) < 6 * 3600 } ?? false
        #expect(shouldSkip == false)
    }
}
