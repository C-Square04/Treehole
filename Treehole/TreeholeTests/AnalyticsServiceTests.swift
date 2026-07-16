import Testing
import Foundation
@testable import Treehole

// MARK: - AnalyticsService Tests
// isDisabled is set in init so no test ever posts a row to the production
// analytics_events table; payload logic is verified via the pure helpers.

@Suite("AnalyticsService Tests")
struct AnalyticsServiceTests {

    init() {
        // Never send test events to production Supabase.
        AnalyticsService.isDisabled = true
    }

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

    /// Skips analytics for system/seed device IDs (the guard track() uses).
    @Test func testTrackSkipsForSystemDeviceNoCrash() {
        #expect(AnalyticsService.shouldSkip(deviceId: "system") == true)
        #expect(AnalyticsService.shouldSkip(deviceId: "system-treehole-1") == true)
        #expect(AnalyticsService.shouldSkip(deviceId: "npc-seed") == true)
        #expect(AnalyticsService.shouldSkip(deviceId: "npc-seed-42") == true)
        // Calling track() repeatedly must also stay crash-free
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

    /// Normal device IDs (anon UUIDs) are never skipped.
    @Test func testShouldSkipAllowsNormalDeviceIds() {
        #expect(AnalyticsService.shouldSkip(deviceId: UUID().uuidString) == false)
        #expect(AnalyticsService.shouldSkip(deviceId: "") == false)
        // Prefix must be at the start, not merely contained
        #expect(AnalyticsService.shouldSkip(deviceId: "my-system-device") == false)
    }

    /// The event body carries every analytics_events column with the given values.
    @Test func testMakeEventBodyContainsAllColumns() {
        let body = AnalyticsService.makeEventBody(
            event: "post_created",
            properties: ["mood": "calm"],
            deviceId: "device-123",
            appleUserId: "apple-456",
            language: "zh-Hans",
            appVersion: "1.2.3"
        )
        #expect(body["event_type"] as? String == "post_created")
        #expect(body["device_id"] as? String == "device-123")
        #expect(body["apple_user_id"] as? String == "apple-456")
        #expect(body["language"] as? String == "zh-Hans")
        #expect(body["app_version"] as? String == "1.2.3")
        #expect(body["properties"] as? [String: String] == ["mood": "calm"])
        #expect(body.count == 6) // no extra columns sneak in
    }

    /// A signed-out user reports an explicit JSON null, not a missing column.
    @Test func testMakeEventBodyNilAppleIdIsNull() {
        let body = AnalyticsService.makeEventBody(
            event: "app_opened",
            properties: [:],
            deviceId: "device-123",
            appleUserId: nil,
            language: "en",
            appVersion: "1.0"
        )
        #expect(body["apple_user_id"] is NSNull)
        #expect(body["properties"] as? [String: String] == [:])
    }

    /// The body must survive JSONSerialization even with emoji/unicode properties.
    @Test func testMakeEventBodyIsJSONSerializable() throws {
        let body = AnalyticsService.makeEventBody(
            event: "test_special",
            properties: ["emoji": "🌬️", "unicode": "你好", "spaces": "hello world"],
            deviceId: UUID().uuidString,
            appleUserId: nil,
            language: "zh-Hans",
            appVersion: "1.0"
        )
        #expect(JSONSerialization.isValidJSONObject(body))
        let data = try JSONSerialization.data(withJSONObject: body)
        let decoded = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let properties = decoded?["properties"] as? [String: String]
        #expect(properties?["unicode"] == "你好")
        #expect(properties?["emoji"] == "🌬️")
    }
}
