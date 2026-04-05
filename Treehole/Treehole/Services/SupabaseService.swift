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

    static var appleUserID: String? {
        UserDefaults.standard.string(forKey: "appleUserID")
    }

    // The effective user identifier (apple_user_id if signed in, otherwise device_id)
    static var effectiveUserId: String {
        appleUserID ?? deviceId
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
    let appleUserId: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case authorAlias = "author_alias"
        case moodTag = "mood_tag"
        case text
        case npcReplyText = "npc_reply_text"
        case sourceLanguage = "source_language"
        case deviceId = "device_id"
        case appleUserId = "apple_user_id"
        case createdAt = "created_at"
    }

    var isOwn: Bool {
        if let appleId = SupabaseConfig.appleUserID, let postAppleId = appleUserId, appleId == postAppleId {
            return true
        }
        return deviceId == SupabaseConfig.deviceId
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
    let appleUserId: String?

    enum CodingKeys: String, CodingKey {
        case authorAlias = "author_alias"
        case moodTag = "mood_tag"
        case text
        case npcReplyText = "npc_reply_text"
        case sourceLanguage = "source_language"
        case deviceId = "device_id"
        case appleUserId = "apple_user_id"
    }
}

// MARK: - Supabase Service

enum SupabaseService {

    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        return URLSession(configuration: config)
    }()

    // MARK: - Fetch public feed (newest first, paginated)

    static func fetchPosts(limit: Int = 50, offset: Int = 0) async throws -> [RemoteCloudPost] {
        let urlString = "\(SupabaseConfig.restURL)/cloud_posts?select=*&order=created_at.desc&limit=\(limit)&offset=\(offset)"
        guard let url = URL(string: urlString) else { throw SupabaseError.invalidURL }

        var request = URLRequest(url: url)
        request.addValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.addValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw SupabaseError.serverError((response as? HTTPURLResponse)?.statusCode, nil)
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
            deviceId: SupabaseConfig.deviceId,
            appleUserId: SupabaseConfig.appleUserID
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.addValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("return=representation", forHTTPHeaderField: "Prefer")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...201).contains(httpResponse.statusCode) else {
            throw SupabaseError.serverError((response as? HTTPURLResponse)?.statusCode, nil)
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

        let (responseData, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...204).contains(httpResponse.statusCode) else {
            throw SupabaseError.serverError((response as? HTTPURLResponse)?.statusCode, nil)
        }
    }

    // MARK: - Update post NPC reply (background)

    static func updatePostNPCReply(id: String, npcReply: String) async throws {
        let urlString = "\(SupabaseConfig.restURL)/cloud_posts?id=eq.\(id)"
        guard let url = URL(string: urlString) else { throw SupabaseError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.addValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.addValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        struct UpdateBody: Codable {
            let npcReplyText: String
            enum CodingKeys: String, CodingKey { case npcReplyText = "npc_reply_text" }
        }
        request.httpBody = try JSONEncoder().encode(UpdateBody(npcReplyText: npcReply))

        let (responseData, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...204).contains(httpResponse.statusCode) else {
            throw SupabaseError.serverError((response as? HTTPURLResponse)?.statusCode, nil)
        }
    }

    // MARK: - AI Content Moderation (MiniMax via Edge Function)

    static func moderateWithAI(text: String, language: String) async throws -> (allowed: Bool, reason: String?) {
        let urlString = "\(SupabaseConfig.projectURL)/functions/v1/moderate-post"
        guard let url = URL(string: urlString) else { throw SupabaseError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")

        struct ModerationRequest: Codable { let text: String; let language: String }
        request.httpBody = try JSONEncoder().encode(ModerationRequest(text: text, language: language))

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            // AI unavailable → allow (fail open, DB trigger is backup)
            return (true, nil)
        }

        struct ModerationResponse: Codable { let allowed: Bool; let reason: String? }
        let result = try JSONDecoder().decode(ModerationResponse.self, from: data)
        return (result.allowed, result.reason)
    }

    // MARK: - AI NPC Reply (MiniMax via Edge Function)

    static func generateAINPCReply(text: String, mood: String, language: String) async throws -> String {
        let urlString = "\(SupabaseConfig.projectURL)/functions/v1/generate-npc-reply"
        guard let url = URL(string: urlString) else { throw SupabaseError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")

        struct NPCRequest: Codable { let text: String; let mood: String; let language: String }
        request.httpBody = try JSONEncoder().encode(NPCRequest(text: text, mood: mood, language: language))

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            // Fallback to template
            return try await fetchNPCReplyTemplate(mood: mood, language: language)
        }

        struct NPCResponse: Codable { let reply: String }
        let result = try JSONDecoder().decode(NPCResponse.self, from: data)
        return result.reply
    }

    // MARK: - Fetch NPC reply template (fallback)

    static func fetchNPCReplyTemplate(mood: String, language: String) async throws -> String {
        let urlString = "\(SupabaseConfig.restURL)/npc_reply_templates?mood_tag=eq.\(mood)&limit=1"
        guard let url = URL(string: urlString) else { throw SupabaseError.invalidURL }

        var request = URLRequest(url: url)
        request.addValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.addValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")

        let (data, _) = try await session.data(for: request)

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

    // MARK: - Fetch a random post (not from this device)

    static func fetchRandomPost() async throws -> RemoteCloudPost? {
        let urlString = "\(SupabaseConfig.restURL)/rpc/get_random_post"
        guard let url = URL(string: urlString) else { throw SupabaseError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.addValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        struct RandomPostRequest: Codable {
            let requestingDeviceId: String
            enum CodingKeys: String, CodingKey { case requestingDeviceId = "requesting_device_id" }
        }
        request.httpBody = try JSONEncoder().encode(RandomPostRequest(requestingDeviceId: SupabaseConfig.deviceId))

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...201).contains(httpResponse.statusCode) else {
            throw SupabaseError.serverError((response as? HTTPURLResponse)?.statusCode, nil)
        }

        // The RPC may return a single object or an array with one element
        if let single = try? JSONDecoder().decode(RemoteCloudPost.self, from: data) {
            return single
        }
        let posts = try JSONDecoder().decode([RemoteCloudPost].self, from: data)
        return posts.first
    }

    // MARK: - Fetch comments for a post

    static func fetchComments(postId: String) async throws -> [RemoteComment] {
        let urlString = "\(SupabaseConfig.restURL)/cloud_comments?post_id=eq.\(postId)&order=created_at.asc"
        guard let url = URL(string: urlString) else { throw SupabaseError.invalidURL }

        var request = URLRequest(url: url)
        request.addValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.addValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw SupabaseError.serverError((response as? HTTPURLResponse)?.statusCode, nil)
        }

        return try JSONDecoder().decode([RemoteComment].self, from: data)
    }

    // MARK: - Add a comment to a post

    static func addComment(postId: String, authorAlias: String, text: String) async throws -> RemoteComment {
        let urlString = "\(SupabaseConfig.restURL)/cloud_comments"
        guard let url = URL(string: urlString) else { throw SupabaseError.invalidURL }

        struct AddCommentRequest: Codable {
            let postId: String
            let authorAlias: String
            let text: String
            let deviceId: String
            let appleUserId: String?
            enum CodingKeys: String, CodingKey {
                case postId = "post_id"
                case authorAlias = "author_alias"
                case text
                case deviceId = "device_id"
                case appleUserId = "apple_user_id"
            }
        }

        let body = AddCommentRequest(
            postId: postId,
            authorAlias: authorAlias,
            text: text,
            deviceId: SupabaseConfig.deviceId,
            appleUserId: SupabaseConfig.appleUserID
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.addValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("return=representation", forHTTPHeaderField: "Prefer")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...201).contains(httpResponse.statusCode) else {
            throw SupabaseError.serverError((response as? HTTPURLResponse)?.statusCode, nil)
        }

        let comments = try JSONDecoder().decode([RemoteComment].self, from: data)
        guard let created = comments.first else { throw SupabaseError.noData }
        return created
    }

    // MARK: - Delete own comment

    static func deleteComment(id: String) async throws {
        let urlString = "\(SupabaseConfig.restURL)/cloud_comments?id=eq.\(id)"
        guard let url = URL(string: urlString) else { throw SupabaseError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.addValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.addValue(SupabaseConfig.deviceId, forHTTPHeaderField: "x-device-id")

        let (responseData, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...204).contains(httpResponse.statusCode) else {
            throw SupabaseError.serverError((response as? HTTPURLResponse)?.statusCode, nil)
        }
    }

    // MARK: - Fetch own posts

    static func fetchMyPosts() async throws -> [RemoteCloudPost] {
        let urlString = "\(SupabaseConfig.restURL)/rpc/get_my_posts"
        guard let url = URL(string: urlString) else { throw SupabaseError.invalidURL }

        struct MyPostsRequest: Codable {
            let requestingDeviceId: String
            let requestingAppleUserId: String?
            enum CodingKeys: String, CodingKey {
                case requestingDeviceId = "requesting_device_id"
                case requestingAppleUserId = "requesting_apple_user_id"
            }
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.addValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(MyPostsRequest(
            requestingDeviceId: SupabaseConfig.deviceId,
            requestingAppleUserId: SupabaseConfig.appleUserID
        ))

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...201).contains(httpResponse.statusCode) else {
            throw SupabaseError.serverError((response as? HTTPURLResponse)?.statusCode, nil)
        }

        return try JSONDecoder().decode([RemoteCloudPost].self, from: data)
    }

    // MARK: - Migrate device posts to apple user

    static func migratePostsToAppleUser(deviceId: String, appleUserId: String) async throws {
        let urlString = "\(SupabaseConfig.restURL)/rpc/migrate_posts_to_apple_user"
        guard let url = URL(string: urlString) else { throw SupabaseError.invalidURL }

        struct MigrateRequest: Codable {
            let pDeviceId: String
            let pAppleUserId: String
            enum CodingKeys: String, CodingKey {
                case pDeviceId = "p_device_id"
                case pAppleUserId = "p_apple_user_id"
            }
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.addValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(MigrateRequest(pDeviceId: deviceId, pAppleUserId: appleUserId))

        let (responseData, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...204).contains(httpResponse.statusCode) else {
            throw SupabaseError.serverError((response as? HTTPURLResponse)?.statusCode, nil)
        }
    }

    // MARK: - Add reaction (upsert, ignore duplicates)

    static func addReaction(postId: String, type: String) async throws {
        let urlString = "\(SupabaseConfig.restURL)/cloud_reactions"
        guard let url = URL(string: urlString) else { throw SupabaseError.invalidURL }

        struct AddReactionRequest: Codable {
            let postId: String
            let reactionType: String
            let deviceId: String
            enum CodingKeys: String, CodingKey {
                case postId = "post_id"
                case reactionType = "reaction_type"
                case deviceId = "device_id"
            }
        }

        let body = AddReactionRequest(
            postId: postId,
            reactionType: type,
            deviceId: SupabaseConfig.deviceId
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.addValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("resolution=ignore-duplicates", forHTTPHeaderField: "Prefer")
        request.httpBody = try JSONEncoder().encode(body)

        let (responseData, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...204).contains(httpResponse.statusCode) else {
            throw SupabaseError.serverError((response as? HTTPURLResponse)?.statusCode, nil)
        }
    }

    // MARK: - Remove reaction

    static func removeReaction(postId: String, type: String) async throws {
        let encodedType = type.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? type
        let urlString = "\(SupabaseConfig.restURL)/cloud_reactions?post_id=eq.\(postId)&reaction_type=eq.\(encodedType)&device_id=eq.\(SupabaseConfig.deviceId)"
        guard let url = URL(string: urlString) else { throw SupabaseError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.addValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")

        let (responseData, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...204).contains(httpResponse.statusCode) else {
            throw SupabaseError.serverError((response as? HTTPURLResponse)?.statusCode, nil)
        }
    }

    // MARK: - Fetch reaction counts for a post

    static func fetchReactionCounts(postId: String) async throws -> ReactionCounts {
        let urlString = "\(SupabaseConfig.restURL)/post_reaction_counts?post_id=eq.\(postId)"
        guard let url = URL(string: urlString) else { throw SupabaseError.invalidURL }

        var request = URLRequest(url: url)
        request.addValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.addValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw SupabaseError.serverError((response as? HTTPURLResponse)?.statusCode, nil)
        }

        let counts = try JSONDecoder().decode([ReactionCounts].self, from: data)
        return counts.first ?? ReactionCounts(
            postId: postId,
            breezeCount: 0,
            hugCount: 0,
            starlightCount: 0,
            totalCount: 0
        )
    }

    // MARK: - Fetch current device's reactions on a post

    static func fetchMyReactions(postId: String) async throws -> Set<String> {
        let urlString = "\(SupabaseConfig.restURL)/cloud_reactions?post_id=eq.\(postId)&device_id=eq.\(SupabaseConfig.deviceId)&select=reaction_type"
        guard let url = URL(string: urlString) else { throw SupabaseError.invalidURL }

        var request = URLRequest(url: url)
        request.addValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.addValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw SupabaseError.serverError((response as? HTTPURLResponse)?.statusCode, nil)
        }

        struct ReactionTypeRow: Codable {
            let reactionType: String
            enum CodingKeys: String, CodingKey { case reactionType = "reaction_type" }
        }

        let rows = try JSONDecoder().decode([ReactionTypeRow].self, from: data)
        return Set(rows.map { $0.reactionType })
    }
}

// MARK: - Remote Comment (JSON DTO)

struct RemoteComment: Codable, Identifiable {
    let id: String
    let postId: String
    let authorAlias: String
    let text: String
    let deviceId: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case authorAlias = "author_alias"
        case text
        case deviceId = "device_id"
        case createdAt = "created_at"
    }

    var isOwn: Bool {
        deviceId == SupabaseConfig.deviceId
    }

    var date: Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: createdAt) ?? Date()
    }
}

// MARK: - Reaction Counts (JSON DTO)

struct ReactionCounts: Codable {
    let postId: String
    let breezeCount: Int
    let hugCount: Int
    let starlightCount: Int
    let totalCount: Int
    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case breezeCount = "breeze_count"
        case hugCount = "hug_count"
        case starlightCount = "starlight_count"
        case totalCount = "total_count"
    }
}

// MARK: - Content Moderation (Client-side pre-check)

enum ContentModerator {
    struct Result {
        let isAllowed: Bool
        let reason: String?
    }

    static func check(_ text: String) -> Result {
        let lower = text.lowercased()

        // 1. Threats toward others
        let threatPatterns = [
            "i will kill.*you", "i'm going to kill.*you", "gonna kill.*him",
            "gonna kill.*her", "gonna kill.*them",
            "我要杀了.*你", "我要杀了.*他", "我要杀了.*她", "要杀死.*你",
            "砍死.*你", "弄死.*你"
        ]
        for pattern in threatPatterns {
            if lower.range(of: pattern, options: .regularExpression) != nil {
                return Result(isAllowed: false, reason: L10n.t(
                    "Threats toward others are not allowed. If you're in distress, please reach out for help.",
                    "不允许威胁他人。如果你感到痛苦，请寻求帮助。"
                ))
            }
        }

        // 2. Hate speech / slurs
        let hateWords = ["nigger", "chink", "faggot", "kike", "wetback"]
        for word in hateWords {
            if lower.range(of: "\\b\(word)", options: .regularExpression) != nil {
                return Result(isAllowed: false, reason: L10n.t(
                    "Hate speech is not allowed in this safe space.",
                    "这个安全空间不允许仇恨言论。"
                ))
            }
        }

        // 3. Spam / links
        let spamPatterns = ["https?://", "www\\.", "\\.com/", "加微信", "加我qq", "免费领取", "click here", "buy now", "赚钱", "兼职招聘"]
        for pattern in spamPatterns {
            if lower.range(of: pattern, options: .regularExpression) != nil {
                return Result(isAllowed: false, reason: L10n.t(
                    "Links and advertising are not allowed.",
                    "不允许发送链接和广告。"
                ))
            }
        }

        // 4. Phone number patterns
        if lower.range(of: "\\d{3}[-.\\s]?\\d{3,4}[-.\\s]?\\d{4}", options: .regularExpression) != nil {
            return Result(isAllowed: false, reason: L10n.t(
                "Please don't share personal contact information.",
                "请不要分享个人联系方式。"
            ))
        }

        return Result(isAllowed: true, reason: nil)
    }
}

// MARK: - Errors

enum SupabaseError: Error, LocalizedError {
    case invalidURL
    case serverError(Int? = nil, String? = nil)
    case noData
    case moderation(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: "Invalid URL"
        case .serverError(let code, let detail):
            if let code { "Server error (\(code))\(detail.map { ": \($0)" } ?? "")" }
            else { "Server error" }
        case .noData: "No data returned"
        case .moderation(let reason): reason
        }
    }
}
