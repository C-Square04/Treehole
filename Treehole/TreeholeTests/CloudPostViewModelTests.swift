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
