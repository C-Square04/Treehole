//
//  CloudPostViewModel.swift
//  Treehole
//
//  Created by Kayli Cheung & Jimmy Chen on 2025-11-06.
//

import Foundation
import Combine

class CloudPostViewModel: ObservableObject {
    @Published var posts: [CloudPost] = []
    @Published var personalPosts: [CloudPost] = []
    @Published var isLoading: Bool = false
    @Published var error: String?

    init() {
        loadPosts()
    }

    // MARK: - Post Management

    func createPost(text: String, mood: CloudPost.MoodTag, authorAlias: String, language: CloudPost.Language = .simplifiedChinese, visibilityState: CloudPost.VisibilityState = .onlyMe) {
        let post = CloudPost(
            id: UUID().uuidString,
            authorAlias: authorAlias,
            moodTag: mood,
            text: text,
            createdAt: Date(),
            npcReplyId: nil,
            npcReplyText: generateNPCReply(for: mood, language: language),
            visibilityState: visibilityState,
            sourceLanguage: language,
            isPublic: false
        )
        personalPosts.insert(post, at: 0)
        posts.insert(post, at: 0)
        savePosts()
    }

    func deletePost(_ postId: String) {
        posts.removeAll { $0.id == postId }
        personalPosts.removeAll { $0.id == postId }
        savePosts()
    }

    func translatePost(_ postId: String, to language: CloudPost.Language) {
        guard let index = posts.firstIndex(where: { $0.id == postId }) else {
            return
        }

        if posts[index].translations[language] == nil {
            // In a real app, call translation API
            let translatedText = simulateTranslation(posts[index].text, to: language)
            posts[index].translations[language] = TranslationData(
                text: translatedText,
                updatedAt: Date()
            )
            savePosts()
        }
    }

    func addNPCReply(_ postId: String, reply: String) {
        guard let index = posts.firstIndex(where: { $0.id == postId }) else {
            return
        }
        posts[index].npcReplyId = UUID().uuidString
        posts[index].npcReplyText = reply
        savePosts()
    }

    // MARK: - Content Moderation

    func moderatePost(_ text: String) -> (isApproved: Bool, reason: String?) {
        let bannedWords = ["hate", "kill", "abuse"]
        let lowerText = text.lowercased()

        for word in bannedWords {
            if lowerText.contains(word) {
                return (false, "Content contains prohibited words")
            }
        }

        if text.count > 500 {
            return (false, "Post exceeds maximum length")
        }

        return (true, nil)
    }

    // MARK: - NPC Replies

    private func generateNPCReply(for mood: CloudPost.MoodTag, language: CloudPost.Language) -> String {
        let replies: [CloudPost.MoodTag: (zh: String, en: String)] = [
            .happy: (zh: "真好！分享你的喜悦让我也很开心 😊", en: "That's wonderful! Your happiness brightens my day 😊"),
            .sad: (zh: "听你这样说，我也感到你的伤心。给自己一些温柔吧 💙", en: "I hear your sadness. Please be gentle with yourself 💙"),
            .angry: (zh: "生气是正常的感受。也许深呼吸能帮助你平静下来", en: "Anger is a valid feeling. Taking deep breaths might help"),
            .anxious: (zh: "你的忧虑我能理解。也许把担心写下来会有所帮助", en: "Your concerns matter. Sometimes writing them down helps"),
            .tired: (zh: "你很需要好好休息。休息不是懒惰，是自我关爱", en: "You deserve rest. Taking care of yourself is important"),
            .confused: (zh: "感到困惑很正常。慢慢想，你会找到方向的", en: "Confusion is okay. Take your time figuring things out"),
            .hopeful: (zh: "你的希望很珍贵！请珍惜这份光芒", en: "Your hope is precious! Hold onto that light"),
            .calm: (zh: "平静的你，散发着力量。继续保持这份宁静", en: "Your calm brings peace. That's beautiful"),
        ]

        let reply = replies[mood] ?? (zh: "感谢你的分享 💙", en: "Thank you for sharing 💙")
        return language == .simplifiedChinese ? reply.zh : reply.en
    }

    private func simulateTranslation(_ text: String, to language: CloudPost.Language) -> String {
        // In a real app, call translation service
        if language == .english {
            return "[EN] \(text)"
        } else {
            return "[ZH] \(text)"
        }
    }

    // MARK: - Filtering & Searching

    func filterPosts(by mood: CloudPost.MoodTag) -> [CloudPost] {
        posts.filter { $0.moodTag == mood }
    }

    func searchPosts(_ query: String) -> [CloudPost] {
        posts.filter { $0.text.lowercased().contains(query.lowercased()) }
    }

    func getPosts(for userId: String) -> [CloudPost] {
        personalPosts
    }

    // MARK: - Persistence

    func savePosts() {
        if let encoded = try? JSONEncoder().encode(posts) {
            UserDefaults.standard.set(encoded, forKey: "cloudPosts")
        }
        if let encoded = try? JSONEncoder().encode(personalPosts) {
            UserDefaults.standard.set(encoded, forKey: "personalPosts")
        }
    }

    func loadPosts() {
        if let data = UserDefaults.standard.data(forKey: "cloudPosts"),
           let loaded = try? JSONDecoder().decode([CloudPost].self, from: data) {
            posts = loaded
        }
        if let data = UserDefaults.standard.data(forKey: "personalPosts"),
           let loaded = try? JSONDecoder().decode([CloudPost].self, from: data) {
            personalPosts = loaded
        }
    }
}
