//
//  PetChatServiceTests.swift
//  TreeholeTests
//
//  The offline scripted fallback must reply in the app language
//  (matching the AI path's system prompt), not the script of the message.
//

import Testing
import Foundation
@testable import Treehole

@Suite("Pet Chat Scripted Fallback Tests")
struct PetChatScriptedFallbackTests {

    @Test func testFallbackFollowsChineseAppLanguageForEnglishMessage() throws {
        let reply = PetChatService.scriptedFallback(userMessage: "hello there", language: "zh-Hans")
        #expect(reply.range(of: "\\p{Han}", options: .regularExpression) != nil)
    }

    @Test func testFallbackFollowsEnglishAppLanguageForChineseMessage() throws {
        let reply = PetChatService.scriptedFallback(userMessage: "我很难过", language: "en")
        #expect(reply.range(of: "\\p{Han}", options: .regularExpression) == nil)
    }

    @Test func testSadKeywordEnglishApp() throws {
        let reply = PetChatService.scriptedFallback(userMessage: "I feel sad today", language: "en")
        #expect(reply.contains("hug"))
    }

    @Test func testSadKeywordChineseApp() throws {
        let reply = PetChatService.scriptedFallback(userMessage: "我很难过", language: "zh-Hans")
        #expect(reply.contains("抱抱"))
    }

    @Test func testTiredKeywordCrossLanguage() throws {
        // Chinese keyword in the message, English app language → English reply
        let reply = PetChatService.scriptedFallback(userMessage: "今天好累", language: "en")
        #expect(reply.contains("rest"))
    }

    @Test func testDefaultReplyEnglishApp() throws {
        let reply = PetChatService.scriptedFallback(userMessage: "just checking in", language: "en")
        #expect(reply.contains("Meow"))
    }
}
