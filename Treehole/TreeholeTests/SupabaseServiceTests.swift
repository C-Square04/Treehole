import Testing
import Foundation
@testable import Treehole

// MARK: - SupabaseTimestamp Tests

// Postgres omits fractional seconds when microseconds are exactly zero, so
// both timestamp shapes must parse (a non-fractional created_at used to fail
// and silently render as "just now").
@Suite("SupabaseTimestamp Tests")
@MainActor
struct SupabaseTimestampTests {

    @Test func testParsesFractionalSecondsTimestamp() {
        let date = SupabaseTimestamp.parse("2026-07-16T04:00:00.123456+00:00")
        #expect(date != nil)
    }

    @Test func testParsesTimestampWithoutFractionalSeconds() {
        let date = SupabaseTimestamp.parse("2026-07-16T04:00:00+00:00")
        #expect(date != nil)
    }

    @Test func testParsesZuluSuffixWithAndWithoutFraction() {
        #expect(SupabaseTimestamp.parse("2026-07-16T04:00:00Z") != nil)
        #expect(SupabaseTimestamp.parse("2026-07-16T04:00:00.500Z") != nil)
    }

    @Test func testFractionalAndPlainAgreeOnTheSameInstant() throws {
        let plain = try #require(SupabaseTimestamp.parse("2026-07-16T04:00:00+00:00"))
        let fractional = try #require(SupabaseTimestamp.parse("2026-07-16T04:00:00.000+00:00"))
        #expect(plain == fractional)
    }

    @Test func testFractionalPartIsPreserved() throws {
        let base = try #require(SupabaseTimestamp.parse("2026-07-16T04:00:00Z"))
        let half = try #require(SupabaseTimestamp.parse("2026-07-16T04:00:00.500Z"))
        #expect(abs(half.timeIntervalSince(base) - 0.5) < 0.001)
    }

    @Test func testGarbageReturnsNil() {
        #expect(SupabaseTimestamp.parse("not a date") == nil)
        #expect(SupabaseTimestamp.parse("") == nil)
        #expect(SupabaseTimestamp.parse("2026-07-16") == nil)
    }

    // DTO date properties share the helper and fall back to .distantPast
    // (not Date()) so parse failures are visible instead of showing "now".

    @Test func testRemoteCloudPostDateParsesNonFractionalCreatedAt() throws {
        let post = makePost(createdAt: "2026-07-16T04:00:00+00:00")
        let expected = try #require(SupabaseTimestamp.parse("2026-07-16T04:00:00Z"))
        #expect(post.date == expected)
    }

    @Test func testRemoteCloudPostDateParsesFractionalCreatedAt() throws {
        let post = makePost(createdAt: "2026-07-16T04:00:00.250+00:00")
        let expected = try #require(SupabaseTimestamp.parse("2026-07-16T04:00:00.250Z"))
        #expect(post.date == expected)
    }

    @Test func testRemoteCloudPostDateFallsBackToDistantPast() {
        let post = makePost(createdAt: "garbage")
        #expect(post.date == .distantPast)
    }

    @Test func testRemoteCommentDateParsesBothShapes() throws {
        let plainComment = makeComment(createdAt: "2026-07-16T04:00:00+00:00")
        let fractionalComment = makeComment(createdAt: "2026-07-16T04:00:00.000+00:00")
        let expected = try #require(SupabaseTimestamp.parse("2026-07-16T04:00:00Z"))
        #expect(plainComment.date == expected)
        #expect(fractionalComment.date == expected)
    }

    @Test func testRemoteCommentDateFallsBackToDistantPast() {
        let comment = makeComment(createdAt: "")
        #expect(comment.date == .distantPast)
    }

    // MARK: - Helpers

    private func makePost(createdAt: String) -> RemoteCloudPost {
        RemoteCloudPost(
            id: UUID().uuidString,
            authorAlias: "Cloud Fox",
            moodTag: "calm",
            text: "hello",
            npcReplyText: nil,
            sourceLanguage: "en",
            deviceId: "test-device",
            appleUserId: nil,
            createdAt: createdAt,
            flagged: nil
        )
    }

    private func makeComment(createdAt: String) -> RemoteComment {
        RemoteComment(
            id: UUID().uuidString,
            postId: UUID().uuidString,
            authorAlias: "Cloud Fox",
            text: "hi",
            deviceId: "test-device",
            createdAt: createdAt
        )
    }
}

// MARK: - SupabaseError Localization Tests

// errorDescription surfaces directly in UI error banners, so it must follow
// the L10n rule like every other user-facing string.
@Suite("SupabaseError Localization Tests")
@MainActor
struct SupabaseErrorLocalizationTests {

    @Test func testInvalidURLIsBilingual() {
        L10n.lang = "en"
        #expect(SupabaseError.invalidURL.errorDescription == "Invalid URL")
        L10n.lang = "zh-Hans"
        #expect(SupabaseError.invalidURL.errorDescription == "无效的链接")
        L10n.lang = "en"
    }

    @Test func testNoDataIsBilingual() {
        L10n.lang = "en"
        #expect(SupabaseError.noData.errorDescription == "No data returned")
        L10n.lang = "zh-Hans"
        #expect(SupabaseError.noData.errorDescription == "未返回数据")
        L10n.lang = "en"
    }

    @Test func testServerErrorWithCodeIsBilingual() {
        L10n.lang = "en"
        #expect(SupabaseError.serverError(500, nil).errorDescription == "Server error (500)")
        L10n.lang = "zh-Hans"
        #expect(SupabaseError.serverError(500, nil).errorDescription == "服务器错误（500）")
        L10n.lang = "en"
    }

    @Test func testServerErrorWithCodeAndDetailAppendsDetail() {
        L10n.lang = "en"
        let description = SupabaseError.serverError(429, "Please wait").errorDescription
        #expect(description == "Server error (429): Please wait")
        L10n.lang = "en"
    }

    @Test func testServerErrorWithoutCodeIsBilingual() {
        L10n.lang = "en"
        #expect(SupabaseError.serverError(nil, nil).errorDescription == "Server error")
        L10n.lang = "zh-Hans"
        #expect(SupabaseError.serverError(nil, nil).errorDescription == "服务器错误")
        L10n.lang = "en"
    }

    /// Detail without a code is already a user-facing localized message and
    /// passes through unwrapped (used by e.g. the zero-row delete guard).
    @Test func testServerErrorDetailOnlyPassesThrough() {
        L10n.lang = "en"
        let description = SupabaseError.serverError(nil, "This cloud could not be deleted.").errorDescription
        #expect(description == "This cloud could not be deleted.")
    }

    @Test func testModerationReasonPassesThrough() {
        let description = SupabaseError.moderation("Not allowed").errorDescription
        #expect(description == "Not allowed")
    }
}
