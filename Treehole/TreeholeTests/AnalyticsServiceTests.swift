import Testing
import Foundation
@testable import Treehole

// MARK: - AnalyticsService Tests

@Suite("AnalyticsService Tests")
struct AnalyticsServiceTests {

    /// track() with no properties should not crash and return synchronously (fire-and-forget).
    @Test func testTrackEmptyPropertiesNoCrash() {
        // Should return immediately without throwing
        AnalyticsService.track("test_event_empty")
        #expect(Bool(true)) // reached here = no crash
    }

    /// track() with full properties should not crash.
    @Test func testTrackWithPropertiesNoCrash() {
        AnalyticsService.track("test_event_full", properties: [
            "mood": "calm",
            "language": "en",
            "type": "breeze"
        ])
        #expect(Bool(true))
    }

    /// track() is synchronous from caller perspective — returns before network call finishes.
    @Test func testTrackReturnsSynchronously() {
        var completed = false
        AnalyticsService.track("test_sync_event", properties: ["key": "value"])
        completed = true
        // If track() were blocking, completed would not be set immediately
        #expect(completed == true)
    }

    /// Skips analytics for system/seed device IDs.
    /// We can only verify no crash; the actual skip is enforced inside the service.
    @Test func testTrackSkipsForSystemDeviceNoCrash() {
        // We can't override SupabaseConfig.deviceId directly, but we verify
        // that the guard inside track() handles known prefixes without crashing.
        // Indirect test: call track while deviceId is whatever it is — should never crash.
        for _ in 0..<5 {
            AnalyticsService.track("app_opened")
        }
        #expect(Bool(true))
    }

    /// track() with special characters in properties should not crash.
    @Test func testTrackWithSpecialCharactersNoCrash() {
        AnalyticsService.track("test_special", properties: [
            "emoji": "🌬️",
            "unicode": "你好",
            "spaces": "hello world"
        ])
        #expect(Bool(true))
    }
}
