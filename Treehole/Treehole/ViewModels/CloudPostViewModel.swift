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

    // MARK: - Fetch public feed

    func fetchPosts() async {
        isLoading = true
        errorMessage = nil
        do {
            remotePosts = try await SupabaseService.fetchPosts(limit: 50)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Create post (INSTANT: post first, AI in background)

    func createPost(authorAlias: String, language: String) async {
        let text = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        // Layer 1: Client-side keyword check (instant, <1ms)
        let keywordResult = ContentModerator.check(text)
        guard keywordResult.isAllowed else {
            errorMessage = keywordResult.reason
            return
        }

        let mood = draftMood

        // Close sheet IMMEDIATELY — user perceives instant response
        draftText = ""
        draftMood = .calm
        showCreation = false

        do {
            // Step 1: Insert post WITHOUT NPC reply (instant DB write)
            let newPost = try await SupabaseService.createPost(
                authorAlias: authorAlias,
                moodTag: mood,
                text: text,
                npcReply: nil,
                language: language
            )
            remotePosts.insert(newPost, at: 0)

            // Step 2: AI moderation + NPC reply in background (non-blocking)
            let postId = newPost.id
            Task {
                await generateNPCReplyInBackground(postId: postId, text: text, mood: mood, language: language)
            }
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

    // MARK: - Background AI processing

    private func generateNPCReplyInBackground(postId: String, text: String, mood: MoodTag, language: String) async {
        do {
            async let moderationTask = SupabaseService.moderateWithAI(text: text, language: language)
            async let npcTask = SupabaseService.generateAINPCReply(text: text, mood: mood.rawValue, language: language)

            let (moderation, npcReply) = try await (moderationTask, npcTask)

            if !moderation.allowed {
                // AI flagged — remove from feed and DB
                remotePosts.removeAll { $0.id == postId }
                errorMessage = moderation.reason
                try? await SupabaseService.deletePost(id: postId)
            } else if let index = remotePosts.firstIndex(where: { $0.id == postId }) {
                // Update local post with NPC reply
                let old = remotePosts[index]
                let withReply = RemoteCloudPost(
                    id: old.id, authorAlias: old.authorAlias, moodTag: old.moodTag,
                    text: old.text, npcReplyText: npcReply, sourceLanguage: old.sourceLanguage,
                    deviceId: old.deviceId, createdAt: old.createdAt
                )
                remotePosts[index] = withReply
                try? await SupabaseService.updatePostNPCReply(id: postId, npcReply: npcReply)
            }
        } catch {
            // AI failed — post stays without NPC reply
        }
    }
}
