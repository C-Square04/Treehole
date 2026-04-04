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
        }
        isLoading = false
    }

    // MARK: - Create post (optimistic: post first, AI in background)

    func createPost(authorAlias: String, language: String) async {
        let text = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        // Layer 1: Client-side keyword pre-check (instant, <1ms)
        let keywordResult = ContentModerator.check(text)
        guard keywordResult.isAllowed else {
            errorMessage = keywordResult.reason
            return
        }

        let mood = draftMood

        // Optimistic: close sheet immediately, run everything async
        draftText = ""
        draftMood = .calm
        showCreation = false

        do {
            // Run AI moderation + NPC reply IN PARALLEL
            async let moderationTask = SupabaseService.moderateWithAI(text: text, language: language)
            async let npcTask = SupabaseService.generateAINPCReply(text: text, mood: mood.rawValue, language: language)

            let (moderation, npcReply) = try await (moderationTask, npcTask)

            // Check moderation result
            guard moderation.allowed else {
                errorMessage = moderation.reason
                return
            }

            // Insert post with AI NPC reply
            let newPost = try await SupabaseService.createPost(
                authorAlias: authorAlias,
                moodTag: mood,
                text: text,
                npcReply: npcReply,
                language: language
            )

            remotePosts.insert(newPost, at: 0)
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
}
