import Foundation

// MARK: - Cloud Post API

/// Seam over the SupabaseService calls that CloudPostViewModel makes, so unit
/// tests can substitute a mock instead of reaching the production backend.
/// Sendable so implementations can be captured by `async let` child tasks.
@MainActor
protocol CloudPostAPI: Sendable {
    func fetchPosts(limit: Int) async throws -> [RemoteCloudPost]
    func createPost(authorAlias: String, moodTag: MoodTag, text: String, npcReply: String?, language: String) async throws -> RemoteCloudPost
    func deletePost(id: String) async throws
    func moderateWithAI(text: String, language: String) async throws -> (allowed: Bool, reason: String?)
    func generateAINPCReply(text: String, mood: String, language: String) async throws -> String
    func updatePostNPCReply(id: String, npcReply: String) async throws
}

/// Production implementation — forwards 1:1 to the SupabaseService statics.
struct LiveCloudPostAPI: CloudPostAPI {
    // Nonisolated so the stateless struct can be built in default-argument
    // position (evaluated outside MainActor isolation).
    nonisolated init() {}

    func fetchPosts(limit: Int) async throws -> [RemoteCloudPost] {
        try await SupabaseService.fetchPosts(limit: limit)
    }

    func createPost(authorAlias: String, moodTag: MoodTag, text: String, npcReply: String?, language: String) async throws -> RemoteCloudPost {
        try await SupabaseService.createPost(authorAlias: authorAlias, moodTag: moodTag, text: text, npcReply: npcReply, language: language)
    }

    func deletePost(id: String) async throws {
        try await SupabaseService.deletePost(id: id)
    }

    func moderateWithAI(text: String, language: String) async throws -> (allowed: Bool, reason: String?) {
        try await SupabaseService.moderateWithAI(text: text, language: language)
    }

    func generateAINPCReply(text: String, mood: String, language: String) async throws -> String {
        try await SupabaseService.generateAINPCReply(text: text, mood: mood, language: language)
    }

    func updatePostNPCReply(id: String, npcReply: String) async throws {
        try await SupabaseService.updatePostNPCReply(id: id, npcReply: npcReply)
    }
}
