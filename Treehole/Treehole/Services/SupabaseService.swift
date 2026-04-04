import Foundation

// MARK: - Supabase Configuration

enum SupabaseConfig {
    static let projectURL = "https://gjtiqwkhrepwhtoyjeix.supabase.co"
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdqdGlxd2tocmVwd2h0b3lqZWl4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUzMjU3MjYsImV4cCI6MjA5MDkwMTcyNn0.HWSCUL6Y63cI_StCa5B--bWBRY7DfBbyuJuzlFwMP7o"
    static let restURL = "\(projectURL)/rest/v1"

    static var deviceId: String {
        if let stored = UserDefaults.standard.string(forKey: "supabase_device_id") {
            return stored
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: "supabase_device_id")
        return newId
    }
}

// MARK: - Remote Cloud Post (JSON DTO)

struct RemoteCloudPost: Codable, Identifiable {
    let id: String
    let authorAlias: String
    let moodTag: String
    let text: String
    let npcReplyText: String?
    let sourceLanguage: String
    let deviceId: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case authorAlias = "author_alias"
        case moodTag = "mood_tag"
        case text
        case npcReplyText = "npc_reply_text"
        case sourceLanguage = "source_language"
        case deviceId = "device_id"
        case createdAt = "created_at"
    }

    var isOwn: Bool {
        deviceId == SupabaseConfig.deviceId
    }

    var mood: MoodTag {
        MoodTag(rawValue: moodTag) ?? .calm
    }

    var date: Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: createdAt) ?? Date()
    }
}

// MARK: - Create Post Request

struct CreatePostRequest: Codable {
    let authorAlias: String
    let moodTag: String
    let text: String
    let npcReplyText: String?
    let sourceLanguage: String
    let deviceId: String

    enum CodingKeys: String, CodingKey {
        case authorAlias = "author_alias"
        case moodTag = "mood_tag"
        case text
        case npcReplyText = "npc_reply_text"
        case sourceLanguage = "source_language"
        case deviceId = "device_id"
    }
}

// MARK: - Supabase Service

enum SupabaseService {

    // MARK: - Fetch public feed (newest first, paginated)

    static func fetchPosts(limit: Int = 50, offset: Int = 0) async throws -> [RemoteCloudPost] {
        let urlString = "\(SupabaseConfig.restURL)/cloud_posts?select=*&order=created_at.desc&limit=\(limit)&offset=\(offset)"
        guard let url = URL(string: urlString) else { throw SupabaseError.invalidURL }

        var request = URLRequest(url: url)
        request.addValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.addValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw SupabaseError.serverError
        }

        let decoder = JSONDecoder()
        return try decoder.decode([RemoteCloudPost].self, from: data)
    }

    // MARK: - Create a new post

    static func createPost(authorAlias: String, moodTag: MoodTag, text: String, npcReply: String?, language: String) async throws -> RemoteCloudPost {
        let urlString = "\(SupabaseConfig.restURL)/cloud_posts"
        guard let url = URL(string: urlString) else { throw SupabaseError.invalidURL }

        let body = CreatePostRequest(
            authorAlias: authorAlias,
            moodTag: moodTag.rawValue,
            text: text,
            npcReplyText: npcReply,
            sourceLanguage: language,
            deviceId: SupabaseConfig.deviceId
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.addValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("return=representation", forHTTPHeaderField: "Prefer")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...201).contains(httpResponse.statusCode) else {
            throw SupabaseError.serverError
        }

        let posts = try JSONDecoder().decode([RemoteCloudPost].self, from: data)
        guard let created = posts.first else { throw SupabaseError.noData }
        return created
    }

    // MARK: - Delete own post

    static func deletePost(id: String) async throws {
        let urlString = "\(SupabaseConfig.restURL)/cloud_posts?id=eq.\(id)"
        guard let url = URL(string: urlString) else { throw SupabaseError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.addValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.addValue(SupabaseConfig.deviceId, forHTTPHeaderField: "x-device-id")

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...204).contains(httpResponse.statusCode) else {
            throw SupabaseError.serverError
        }
    }

    // MARK: - Fetch NPC reply template

    static func fetchNPCReply(mood: String, language: String) async throws -> String {
        let urlString = "\(SupabaseConfig.restURL)/npc_reply_templates?mood_tag=eq.\(mood)&limit=1"
        guard let url = URL(string: urlString) else { throw SupabaseError.invalidURL }

        var request = URLRequest(url: url)
        request.addValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.addValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")

        let (data, _) = try await URLSession.shared.data(for: request)

        struct NPCTemplate: Codable {
            let replyEn: String
            let replyZh: String
            enum CodingKeys: String, CodingKey {
                case replyEn = "reply_en"
                case replyZh = "reply_zh"
            }
        }

        let templates = try JSONDecoder().decode([NPCTemplate].self, from: data)
        guard let template = templates.first else {
            return language == "zh-Hans" ? "感谢你的分享 💙" : "Thank you for sharing 💙"
        }
        return language == "zh-Hans" ? template.replyZh : template.replyEn
    }
}

// MARK: - Errors

enum SupabaseError: Error, LocalizedError {
    case invalidURL
    case serverError
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL: "Invalid URL"
        case .serverError: "Server error"
        case .noData: "No data returned"
        }
    }
}
