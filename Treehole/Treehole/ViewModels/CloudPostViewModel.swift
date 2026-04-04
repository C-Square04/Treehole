import Foundation
import SwiftData
import Observation

@Observable
final class CloudPostViewModel {
    var draftText: String = ""
    var draftMood: MoodTag = .calm
    var showCreation: Bool = false

    // Remote feed
    var remotePosts: [RemoteCloudPost] = []
    var isLoading: Bool = false
    var errorMessage: String?

    var characterCount: Int { draftText.count }
    var isValid: Bool { !draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && draftText.count <= 500 }

    // MARK: - Fetch public feed from Supabase

    func fetchPosts() async {
        isLoading = true
        errorMessage = nil
        do {
            remotePosts = try await SupabaseService.fetchPosts(limit: 50)
        } catch {
            errorMessage = error.localizedDescription
            // Keep existing posts on error (offline graceful degradation)
        }
        isLoading = false
    }

    // MARK: - Create post (uploads to Supabase)

    func createPost(authorAlias: String, language: String) async {
        let text = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        // Layer 1: Client-side keyword pre-check (instant)
        let keywordResult = ContentModerator.check(text)
        guard keywordResult.isAllowed else {
            errorMessage = keywordResult.reason
            return
        }

        do {
            // Layer 2: AI moderation via MiniMax (server-side)
            let aiModeration = try await SupabaseService.moderateWithAI(text: text, language: language)
            guard aiModeration.allowed else {
                errorMessage = aiModeration.reason
                return
            }

            // Generate AI NPC reply via MiniMax
            let npcReply = try await SupabaseService.generateAINPCReply(text: text, mood: draftMood.rawValue, language: language)

            // Create post on Supabase
            let newPost = try await SupabaseService.createPost(
                authorAlias: authorAlias,
                moodTag: draftMood,
                text: text,
                npcReply: npcReply,
                language: language
            )

            // Insert at top of local feed
            remotePosts.insert(newPost, at: 0)
            draftText = ""
            draftMood = .calm
            showCreation = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Delete own post

    func deletePost(id: String) async {
        do {
            try await SupabaseService.deletePost(id: id)
            remotePosts.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resetDraft() {
        draftText = ""
        draftMood = .calm
    }

    // MARK: - Fallback NPC reply (offline)

    func generateNPCReplyOffline(for mood: MoodTag, language: String) -> String {
        let replies: [MoodTag: (zh: String, en: String)] = [
            .happy: ("真好！分享你的喜悦让我也很开心 😊", "That's wonderful! Your happiness brightens my day 😊"),
            .sad: ("听你这样说，我也感到你的伤心。给自己一些温柔吧 💙", "I hear your sadness. Please be gentle with yourself 💙"),
            .angry: ("生气是正常的感受。也许深呼吸能帮助你平静下来", "Anger is a valid feeling. Taking deep breaths might help"),
            .anxious: ("你的忧虑我能理解。也许把担心写下来会有所帮助", "Your concerns matter. Sometimes writing them down helps"),
            .tired: ("你很需要好好休息。休息不是懒惰，是自我关爱", "You deserve rest. Taking care of yourself is important"),
            .confused: ("感到困惑很正常。慢慢想，你会找到方向的", "Confusion is okay. Take your time figuring things out"),
            .hopeful: ("你的希望很珍贵！请珍惜这份光芒", "Your hope is precious! Hold onto that light"),
            .calm: ("平静的你，散发着力量。继续保持这份宁静", "Your calm brings peace. That's beautiful"),
        ]
        let reply = replies[mood] ?? ("感谢你的分享 💙", "Thank you for sharing 💙")
        return language == "zh-Hans" ? reply.0 : reply.1
    }
}
