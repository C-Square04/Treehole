//
//  HiddenPostsStoreTests.swift
//  TreeholeTests
//

import Testing
import Foundation
@testable import Treehole

// MARK: - HiddenPostsStore Tests
// The store takes an injectable UserDefaults, so each test uses an isolated
// suite that is wiped before and after — nothing touches .standard.

@MainActor
@Suite("HiddenPostsStore Tests", .serialized)
final class HiddenPostsStoreTests {

    private static let suiteName = "HiddenPostsStoreTests"
    private let defaults: UserDefaults

    init() {
        defaults = UserDefaults(suiteName: Self.suiteName)!
        defaults.removePersistentDomain(forName: Self.suiteName)
    }

    deinit {
        UserDefaults(suiteName: Self.suiteName)?.removePersistentDomain(forName: Self.suiteName)
    }

    private func makePost(
        id: String = "post-1",
        deviceId: String = "device-1"
    ) -> RemoteCloudPost {
        RemoteCloudPost(
            id: id,
            authorAlias: "Quiet Fox",
            moodTag: "calm",
            text: "Hello from a test cloud",
            npcReplyText: nil,
            sourceLanguage: "en",
            deviceId: deviceId,
            appleUserId: nil,
            createdAt: "2026-07-16T12:00:00Z",
            flagged: nil
        )
    }

    // MARK: - Hiding posts

    @Test func testFreshStoreHidesNothing() {
        let store = HiddenPostsStore(defaults: defaults)
        #expect(store.isHidden(makePost()) == false)
        #expect(store.hiddenPostIDs.isEmpty)
        #expect(store.blockedAuthorDeviceIDs.isEmpty)
    }

    @Test func testHidePostMarksOnlyThatPostHidden() {
        let store = HiddenPostsStore(defaults: defaults)
        store.hidePost(id: "post-1")
        #expect(store.isHidden(makePost(id: "post-1")))
        #expect(store.isHidden(makePost(id: "post-2")) == false)
    }

    // MARK: - Blocking authors

    @Test func testBlockAuthorHidesAllPostsFromThatDevice() {
        let store = HiddenPostsStore(defaults: defaults)
        store.blockAuthor(deviceId: "device-bad")
        #expect(store.isHidden(makePost(id: "a", deviceId: "device-bad")))
        #expect(store.isHidden(makePost(id: "b", deviceId: "device-bad")))
        #expect(store.isHidden(makePost(id: "c", deviceId: "device-ok")) == false)
    }

    // MARK: - Filtering

    @Test func testFilterRemovesHiddenAndBlockedPosts() {
        let store = HiddenPostsStore(defaults: defaults)
        let visible = makePost(id: "visible", deviceId: "device-ok")
        let reported = makePost(id: "reported", deviceId: "device-ok")
        let fromBlocked = makePost(id: "from-blocked", deviceId: "device-bad")

        store.hidePost(id: "reported")
        store.blockAuthor(deviceId: "device-bad")

        let filtered = store.filter([visible, reported, fromBlocked])
        #expect(filtered.map(\.id) == ["visible"])
    }

    @Test func testFilterKeepsEverythingWhenNothingHidden() {
        let store = HiddenPostsStore(defaults: defaults)
        let posts = [makePost(id: "a"), makePost(id: "b")]
        #expect(store.filter(posts).map(\.id) == ["a", "b"])
    }

    // MARK: - Persistence round-trip

    @Test func testHiddenStateSurvivesReload() {
        let store = HiddenPostsStore(defaults: defaults)
        store.hidePost(id: "post-1")
        store.hidePost(id: "post-2")
        store.blockAuthor(deviceId: "device-bad")

        // A new instance over the same defaults simulates an app relaunch
        let reloaded = HiddenPostsStore(defaults: defaults)
        #expect(reloaded.hiddenPostIDs == ["post-1", "post-2"])
        #expect(reloaded.blockedAuthorDeviceIDs == ["device-bad"])
        #expect(reloaded.isHidden(makePost(id: "post-1")))
        #expect(reloaded.isHidden(makePost(id: "x", deviceId: "device-bad")))
    }

    @Test func testRepeatedHideIsIdempotent() {
        let store = HiddenPostsStore(defaults: defaults)
        store.hidePost(id: "post-1")
        store.hidePost(id: "post-1")
        store.blockAuthor(deviceId: "device-bad")
        store.blockAuthor(deviceId: "device-bad")

        let reloaded = HiddenPostsStore(defaults: defaults)
        #expect(reloaded.hiddenPostIDs.count == 1)
        #expect(reloaded.blockedAuthorDeviceIDs.count == 1)
    }

    // MARK: - Reset (account deletion)

    @Test func testResetClearsMemoryAndPersistence() {
        let store = HiddenPostsStore(defaults: defaults)
        store.hidePost(id: "post-1")
        store.blockAuthor(deviceId: "device-bad")

        store.reset()

        #expect(store.hiddenPostIDs.isEmpty)
        #expect(store.blockedAuthorDeviceIDs.isEmpty)
        // A fresh instance over the same defaults must see nothing — the wipe
        // has to reach disk, not just the in-memory sets.
        let reloaded = HiddenPostsStore(defaults: defaults)
        #expect(reloaded.hiddenPostIDs.isEmpty)
        #expect(reloaded.blockedAuthorDeviceIDs.isEmpty)
        #expect(reloaded.isHidden(makePost(id: "post-1", deviceId: "device-bad")) == false)
    }
}
