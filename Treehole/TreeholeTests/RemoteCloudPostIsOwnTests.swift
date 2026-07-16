//
//  RemoteCloudPostIsOwnTests.swift
//  TreeholeTests
//

import Testing
import Foundation
@testable import Treehole

// MARK: - RemoteCloudPost.isOwn Tests
// isOwn reads SupabaseConfig, which is UserDefaults-backed and not injectable:
// the suite runs serialized, drives the "appleUserID" key directly, and
// restores the prior value after each test. The "supabase_device_id" key is
// never mutated — same-device cases reuse SupabaseConfig.deviceId and
// other-device cases use a random id — so parallel suites keep a stable id.

@Suite("RemoteCloudPost isOwn Tests", .serialized)
final class RemoteCloudPostIsOwnTests {

    private static let appleUserIDKey = "appleUserID"

    private let savedAppleUserID: String?

    init() {
        savedAppleUserID = UserDefaults.standard.string(forKey: Self.appleUserIDKey)
        // Each test starts signed out unless it sets the key itself
        UserDefaults.standard.removeObject(forKey: Self.appleUserIDKey)
    }

    deinit {
        if let savedAppleUserID {
            UserDefaults.standard.set(savedAppleUserID, forKey: Self.appleUserIDKey)
        } else {
            UserDefaults.standard.removeObject(forKey: Self.appleUserIDKey)
        }
    }

    private func makePost(deviceId: String, appleUserId: String?) -> RemoteCloudPost {
        RemoteCloudPost(
            id: UUID().uuidString,
            authorAlias: "Cloud Fox",
            moodTag: "calm",
            text: "test post",
            npcReplyText: nil,
            sourceLanguage: "en",
            deviceId: deviceId,
            appleUserId: appleUserId,
            createdAt: "2026-01-01T00:00:00.000Z",
            flagged: nil
        )
    }

    @Test func testMatchingAppleIdOwnsRegardlessOfDevice() {
        UserDefaults.standard.set("apple-me", forKey: Self.appleUserIDKey)
        // Post created on another device under the same Apple account
        let post = makePost(deviceId: "other-device-\(UUID().uuidString)", appleUserId: "apple-me")
        #expect(post.isOwn == true)
    }

    @Test func testMismatchedAppleIdButMatchingDeviceOwns() {
        // A post made on this device under a different (or stale) apple id
        // still counts as own via the device_id fallback — intended behavior.
        UserDefaults.standard.set("apple-me", forKey: Self.appleUserIDKey)
        let post = makePost(deviceId: SupabaseConfig.deviceId, appleUserId: "apple-someone-else")
        #expect(post.isOwn == true)
    }

    @Test func testNilPostAppleIdMatchingDeviceOwns() {
        // Pre-sign-in post from this device: no apple id on the row yet
        UserDefaults.standard.set("apple-me", forKey: Self.appleUserIDKey)
        let post = makePost(deviceId: SupabaseConfig.deviceId, appleUserId: nil)
        #expect(post.isOwn == true)
    }

    @Test func testSignedOutMatchingDeviceOwns() {
        // No appleUserID stored (cleared in init): device match decides
        let post = makePost(deviceId: SupabaseConfig.deviceId, appleUserId: "apple-author")
        #expect(post.isOwn == true)
    }

    @Test func testSignedOutDifferentDeviceNotOwn() {
        let post = makePost(deviceId: "other-device-\(UUID().uuidString)", appleUserId: nil)
        #expect(post.isOwn == false)
    }

    @Test func testMismatchedAppleIdAndDeviceNotOwn() {
        UserDefaults.standard.set("apple-me", forKey: Self.appleUserIDKey)
        let post = makePost(deviceId: "other-device-\(UUID().uuidString)", appleUserId: "apple-someone-else")
        #expect(post.isOwn == false)
    }
}
