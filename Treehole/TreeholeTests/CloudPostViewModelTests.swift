//
//  CloudPostViewModelTests.swift
//  TreeholeTests
//

import Testing
import Foundation
@testable import Treehole

// MARK: - CloudPostViewModel Draft Tests

// Covers only the pre-network paths of createPost (empty text, client-side keyword
// moderation) — the guards return before any Supabase call is made.
@Suite("CloudPostViewModel Draft Tests")
@MainActor
struct CloudPostViewModelDraftTests {

    @Test func testIsValidRejectsWhitespaceOnlyDraft() {
        let vm = CloudPostViewModel()
        vm.draftText = "   \n  "
        #expect(vm.isValid == false)
    }

    @Test func testIsValidRejectsOverLongDraft() {
        let vm = CloudPostViewModel()
        vm.draftText = String(repeating: "a", count: 501)
        #expect(vm.isValid == false)
    }

    @Test func testIsValidAcceptsNormalDraft() {
        let vm = CloudPostViewModel()
        vm.draftText = "Hello clouds"
        #expect(vm.isValid == true)
    }

    @Test func testCharacterCountTracksDraft() {
        let vm = CloudPostViewModel()
        vm.draftText = "Hello"
        #expect(vm.characterCount == 5)
    }

    @Test func testCreatePostEmptyTextIsNoOp() async {
        let vm = CloudPostViewModel()
        vm.draftText = "   "
        vm.showCreation = true
        await vm.createPost(authorAlias: "Tester", language: "en")
        #expect(vm.errorMessage == nil)
        #expect(vm.showCreation == true)
        #expect(vm.remotePosts.isEmpty)
    }

    @Test func testCreatePostBlockedTextPreservesDraft() async {
        let vm = CloudPostViewModel()
        vm.draftText = "I will kill you for this"
        vm.draftMood = .angry
        vm.showCreation = true
        await vm.createPost(authorAlias: "Tester", language: "en")
        // Keyword moderation rejects before any network call — the draft must survive
        // so the user can edit and retry instead of losing the text
        #expect(vm.errorMessage != nil)
        #expect(vm.draftText == "I will kill you for this")
        #expect(vm.draftMood == .angry)
        #expect(vm.showCreation == true)
        #expect(vm.didCreatePost == false)
    }

    @Test func testResetDraftClearsTextAndMood() {
        let vm = CloudPostViewModel()
        vm.draftText = "something"
        vm.draftMood = .happy
        vm.resetDraft()
        #expect(vm.draftText.isEmpty)
        #expect(vm.draftMood == .calm)
    }
}

// MARK: - Mock API

private struct MockAPIError: Error {}

/// MainActor class (implicitly Sendable) so it satisfies the @MainActor CloudPostAPI
/// requirements and can be configured/inspected directly from @MainActor tests.
@MainActor
private final class MockCloudPostAPI: CloudPostAPI {
    var fetchPostsResult: Result<[RemoteCloudPost], Error> = .success([])
    var createPostResult: Result<RemoteCloudPost, Error> = .failure(MockAPIError())
    var deletePostError: Error?
    var moderationResult: Result<(allowed: Bool, reason: String?), Error> = .success((true, nil))
    var npcReplyResult: Result<String, Error> = .success("mock npc reply")
    var updateReplyError: Error?

    // Recorded calls
    var deletedPostIds: [String] = []
    var updatedReplies: [(id: String, npcReply: String)] = []

    func fetchPosts(limit: Int) async throws -> [RemoteCloudPost] {
        try fetchPostsResult.get()
    }

    func createPost(authorAlias: String, moodTag: MoodTag, text: String, npcReply: String?, language: String) async throws -> RemoteCloudPost {
        try createPostResult.get()
    }

    func deletePost(id: String) async throws {
        if let deletePostError { throw deletePostError }
        deletedPostIds.append(id)
    }

    func moderateWithAI(text: String, language: String) async throws -> (allowed: Bool, reason: String?) {
        try moderationResult.get()
    }

    func generateAINPCReply(text: String, mood: String, language: String) async throws -> String {
        try npcReplyResult.get()
    }

    func updatePostNPCReply(id: String, npcReply: String) async throws {
        if let updateReplyError { throw updateReplyError }
        updatedReplies.append((id: id, npcReply: npcReply))
    }
}

@MainActor
private func makeRemotePost(id: String = "post-1", text: String = "hello clouds", mood: MoodTag = .calm) -> RemoteCloudPost {
    RemoteCloudPost(
        id: id, authorAlias: "Tester", moodTag: mood.rawValue,
        text: text, npcReplyText: nil, sourceLanguage: "en",
        deviceId: "test-device", appleUserId: nil,
        createdAt: "2026-01-01T00:00:00Z", flagged: false
    )
}

// MARK: - CloudPostViewModel Network Tests

// Covers the paths that reach the API seam: create success/failure, delete
// success/failure, AI moderation rejection, and NPC-reply fallback.
@Suite("CloudPostViewModel Network Tests")
@MainActor
struct CloudPostViewModelNetworkTests {

    init() {
        // createPost success fires an analytics event — never post rows from tests
        AnalyticsService.isDisabled = true
    }

    // MARK: Create

    @Test func testCreatePostFailurePreservesDraftForRetry() async {
        let api = MockCloudPostAPI()
        api.createPostResult = .failure(MockAPIError())
        let vm = CloudPostViewModel(api: api)
        vm.draftText = "hello clouds"
        vm.draftMood = .hopeful
        vm.showCreation = true

        await vm.createPost(authorAlias: "Tester", language: "en")

        // Sheet closes optimistically, but the draft must survive a failed insert
        #expect(vm.showCreation == false)
        #expect(vm.draftText == "hello clouds")
        #expect(vm.draftMood == .hopeful)
        #expect(vm.errorMessage != nil)
        #expect(vm.didCreatePost == false)
        #expect(vm.remotePosts.isEmpty)
    }

    @Test func testCreatePostSuccessClearsDraftAndInsertsPost() async {
        let api = MockCloudPostAPI()
        let post = makeRemotePost(id: "post-42")
        api.createPostResult = .success(post)
        let vm = CloudPostViewModel(api: api)
        vm.draftText = "hello clouds"
        vm.draftMood = .happy
        vm.showCreation = true

        await vm.createPost(authorAlias: "Tester", language: "en")

        #expect(vm.showCreation == false)
        #expect(vm.draftText.isEmpty)
        #expect(vm.draftMood == .calm)
        #expect(vm.didCreatePost == true)
        #expect(vm.errorMessage == nil)
        #expect(vm.remotePosts.first?.id == "post-42")
    }

    @Test func testCreatePostSuccessAttachesNPCReplyInBackground() async {
        let api = MockCloudPostAPI()
        api.createPostResult = .success(makeRemotePost(id: "post-42"))
        api.npcReplyResult = .success("a warm reply")
        let vm = CloudPostViewModel(api: api)
        vm.draftText = "hello clouds"

        await vm.createPost(authorAlias: "Tester", language: "en")
        await vm.npcReplyTask?.value

        #expect(vm.remotePosts.first?.npcReplyText == "a warm reply")
        #expect(api.updatedReplies.count == 1)
        #expect(api.updatedReplies.first?.id == "post-42")
        #expect(api.updatedReplies.first?.npcReply == "a warm reply")
    }

    // MARK: AI moderation (background pipeline)

    @Test func testAIModerationRejectionRemovesPostAndDeletesRemote() async {
        let api = MockCloudPostAPI()
        api.createPostResult = .success(makeRemotePost(id: "post-42"))
        api.moderationResult = .success((allowed: false, reason: "flagged by AI"))
        let vm = CloudPostViewModel(api: api)
        vm.draftText = "hello clouds"

        await vm.createPost(authorAlias: "Tester", language: "en")
        #expect(vm.remotePosts.count == 1)

        await vm.npcReplyTask?.value

        #expect(vm.remotePosts.isEmpty)
        #expect(vm.errorMessage == "flagged by AI")
        #expect(api.deletedPostIds == ["post-42"])
        #expect(api.updatedReplies.isEmpty)
    }

    @Test func testNPCReplyFailureLeavesPostWithoutReply() async {
        let api = MockCloudPostAPI()
        api.createPostResult = .success(makeRemotePost(id: "post-42"))
        api.npcReplyResult = .failure(MockAPIError())
        let vm = CloudPostViewModel(api: api)
        vm.draftText = "hello clouds"

        await vm.createPost(authorAlias: "Tester", language: "en")
        await vm.npcReplyTask?.value

        // AI failure is silent: the post stays in the feed with no NPC reply
        #expect(vm.remotePosts.first?.id == "post-42")
        #expect(vm.remotePosts.first?.npcReplyText == nil)
        #expect(vm.errorMessage == nil)
        #expect(api.updatedReplies.isEmpty)
        #expect(api.deletedPostIds.isEmpty)
    }

    // MARK: Delete

    @Test func testDeletePostErrorKeepsPostInFeed() async {
        let api = MockCloudPostAPI()
        api.deletePostError = MockAPIError()
        let vm = CloudPostViewModel(api: api)
        vm.remotePosts = [makeRemotePost(id: "post-42")]

        await vm.deletePost(id: "post-42")

        // Failed remote delete must not drop the post locally — feed stays truthful
        #expect(vm.remotePosts.count == 1)
        #expect(vm.errorMessage != nil)
    }

    @Test func testDeletePostSuccessRemovesPostFromFeed() async {
        let api = MockCloudPostAPI()
        let vm = CloudPostViewModel(api: api)
        vm.remotePosts = [makeRemotePost(id: "post-42"), makeRemotePost(id: "post-43")]

        await vm.deletePost(id: "post-42")

        #expect(vm.remotePosts.map(\.id) == ["post-43"])
        #expect(vm.errorMessage == nil)
        #expect(api.deletedPostIds == ["post-42"])
    }

    // MARK: Fetch

    @Test func testFetchPostsSuccessPopulatesFeed() async {
        let api = MockCloudPostAPI()
        api.fetchPostsResult = .success([makeRemotePost(id: "post-1"), makeRemotePost(id: "post-2")])
        let vm = CloudPostViewModel(api: api)

        await vm.fetchPosts()

        #expect(vm.remotePosts.map(\.id) == ["post-1", "post-2"])
        #expect(vm.errorMessage == nil)
        #expect(vm.isLoading == false)
    }

    @Test func testFetchPostsFiltersHiddenAndBlockedPosts() async {
        let api = MockCloudPostAPI()
        api.fetchPostsResult = .success([
            makeRemotePost(id: "post-1"),
            makeRemotePost(id: "post-2"),
            RemoteCloudPost(
                id: "post-3", authorAlias: "Tester", moodTag: MoodTag.calm.rawValue,
                text: "from a blocked author", npcReplyText: nil, sourceLanguage: "en",
                deviceId: "blocked-device", appleUserId: nil,
                createdAt: "2026-01-01T00:00:00Z", flagged: false
            )
        ])
        let vm = CloudPostViewModel(api: api)

        // Reported/blocked content must never reach any feed, not just grab flows
        HiddenPostsStore.shared.hidePost(id: "post-2")
        HiddenPostsStore.shared.blockAuthor(deviceId: "blocked-device")
        defer { HiddenPostsStore.shared.reset() }

        await vm.fetchPosts()

        #expect(vm.remotePosts.map(\.id) == ["post-1"])
        #expect(vm.errorMessage == nil)
    }

    @Test func testFetchPostsErrorSetsErrorMessageAndStopsLoading() async {
        let api = MockCloudPostAPI()
        api.fetchPostsResult = .failure(MockAPIError())
        let vm = CloudPostViewModel(api: api)

        await vm.fetchPosts()

        #expect(vm.errorMessage != nil)
        #expect(vm.remotePosts.isEmpty)
        #expect(vm.isLoading == false)
    }
}
