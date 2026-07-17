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

// MARK: - Timestamp Parsing

// Postgres omits the fractional part of created_at when microseconds are
// exactly zero, so timestamps arrive both with and without fractional
// seconds and both shapes must parse. Formatters are cached — allocating an
// ISO8601DateFormatter per row is wasteful when decoding a feed page.
enum SupabaseTimestamp {
    private static let fractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let plain: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static func parse(_ string: String) -> Date? {
        fractional.date(from: string) ?? plain.date(from: string)
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
    let flagged: Bool?

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
        case flagged
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
        // .distantPast (not Date()) so a parse failure is visible instead of
        // silently rendering an old post as "just now".
        SupabaseTimestamp.parse(createdAt) ?? .distantPast
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

        print("[API] fetchPosts: \(urlString)")

        var lastError: Error = SupabaseError.serverError(nil, nil)

        for attempt in 0..<2 {
            if attempt > 0 {
                print("[API] fetchPosts: retrying (attempt \(attempt + 1))...")
                try? await Task.sleep(for: .seconds(1))
            }
            do {
                let (data, response) = try await session.data(for: request)
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                let responseURL = (response as? HTTPURLResponse)?.url?.absoluteString ?? "nil"
                print("[API] fetchPosts: status=\(statusCode) url=\(responseURL) bytes=\(data.count)")

                if statusCode >= 300 && statusCode < 400 {
                    // Log redirect details
                    let body = String(data: data, encoding: .utf8) ?? "nil"
                    #if DEBUG
                    print("[API] fetchPosts: REDIRECT \(statusCode) body=\(body.prefix(200))")
                    #endif
                }

                if (200..<300).contains(statusCode) {
                    do {
                        let posts = try JSONDecoder().decode([RemoteCloudPost].self, from: data)
                        print("[API] fetchPosts: decoded \(posts.count) posts")
                        return posts
                    } catch {
                        print("[API] fetchPosts: DECODE ERROR: \(error)")
                        let body = String(data: data, encoding: .utf8) ?? "nil"
                        #if DEBUG
                        print("[API] fetchPosts: raw body=\(body.prefix(300))")
                        #endif
                        lastError = error
                    }
                } else {
                    lastError = SupabaseError.serverError(statusCode, nil)
                }
            } catch {
                print("[API] fetchPosts: NETWORK ERROR: \(error)")
                lastError = error
            }
        }
        throw lastError
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

        print("[API] createPost: POST \(urlString)")
        let (data, response) = try await session.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        print("[API] createPost: status=\(statusCode) bytes=\(data.count)")

        guard let httpResponse = response as? HTTPURLResponse, (200...201).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8)
            #if DEBUG
            print("[API] createPost: ERROR body=\(errorBody ?? "nil")")
            #endif
            if let errorBody, let errorData = errorBody.data(using: .utf8),
               let errorJson = try? JSONDecoder().decode(SupabaseErrorBody.self, from: errorData) {
                throw SupabaseError.serverError(statusCode, errorJson.userMessage)
            }
            throw SupabaseError.serverError(statusCode, nil)
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
        // Sending apple_user_id lets the RLS policy delete posts that were
        // created under a different device_id but the same apple_user_id
        // (e.g. user reinstalled the app since posting).
        if let appleId = SupabaseConfig.appleUserID {
            request.addValue(appleId, forHTTPHeaderField: "x-apple-user-id")
        }
        // return=representation: PostgREST answers 2xx even when the filter/RLS
        // matched zero rows, so the deleted rows must come back to verify the
        // delete actually happened.
        request.addValue("return=representation", forHTTPHeaderField: "Prefer")

        print("[API] deletePost id=\(id)")
        let (data, response) = try await session.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        print("[API] deletePost status=\(statusCode)")
        guard (200...204).contains(statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "nil"
            #if DEBUG
            print("[API] deletePost ERROR body=\(body)")
            #endif
            throw SupabaseError.serverError(statusCode, nil)
        }
        let deletedRows = (try? JSONSerialization.jsonObject(with: data)) as? [Any] ?? []
        guard !deletedRows.isEmpty else {
            print("[API] deletePost: no rows deleted (RLS refused or post gone)")
            throw SupabaseError.serverError(nil, L10n.t("This cloud could not be deleted.", "无法删除这朵云。"))
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

        let (_, response) = try await session.data(for: request)
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
            let requestingAppleUserId: String?
            enum CodingKeys: String, CodingKey {
                case requestingDeviceId = "requesting_device_id"
                case requestingAppleUserId = "requesting_apple_user_id"
            }
        }
        request.httpBody = try JSONEncoder().encode(
            RandomPostRequest(
                requestingDeviceId: SupabaseConfig.deviceId,
                requestingAppleUserId: SupabaseConfig.appleUserID
            )
        )

        print("[API] fetchRandomPost: POST \(urlString)")
        let (data, response) = try await session.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        let body = String(data: data, encoding: .utf8) ?? "nil"
        #if DEBUG
        print("[API] fetchRandomPost: status=\(statusCode) bytes=\(data.count) body=\(body.prefix(200))")
        #endif
        guard (200...204).contains(statusCode) else {
            throw SupabaseError.serverError(statusCode, nil)
        }

        // Empty response = no posts available
        if data.isEmpty || String(data: data, encoding: .utf8) == "[]" || String(data: data, encoding: .utf8) == "null" {
            return nil
        }

        // The RPC may return a single object or an array
        if let single = try? JSONDecoder().decode(RemoteCloudPost.self, from: data) {
            return single
        }
        if let posts = try? JSONDecoder().decode([RemoteCloudPost].self, from: data) {
            return posts.first
        }
        return nil
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

        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...204).contains(httpResponse.statusCode) else {
            throw SupabaseError.serverError((response as? HTTPURLResponse)?.statusCode, nil)
        }
    }

    // MARK: - Bulk delete all of the user's posts via SECURITY DEFINER RPC
    //
    // This is the canonical "wipe my account" path. It bypasses RLS so it
    // works even if the user's device_id has rotated (e.g. they reinstalled).
    // Returns the number of rows deleted (for logging / verification).
    @discardableResult
    static func deleteAllMyPosts() async throws -> Int {
        let urlString = "\(SupabaseConfig.restURL)/rpc/delete_my_posts"
        guard let url = URL(string: urlString) else { throw SupabaseError.invalidURL }

        struct DeleteRequest: Codable {
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
        request.httpBody = try JSONEncoder().encode(DeleteRequest(
            requestingDeviceId: SupabaseConfig.deviceId,
            requestingAppleUserId: SupabaseConfig.appleUserID
        ))

        print("[API] deleteAllMyPosts: device=\(SupabaseConfig.deviceId) apple=\(SupabaseConfig.appleUserID ?? "nil")")
        let (data, response) = try await session.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        let body = String(data: data, encoding: .utf8) ?? "nil"
        #if DEBUG
        print("[API] deleteAllMyPosts: status=\(statusCode) body=\(body)")
        #endif
        guard (200...204).contains(statusCode) else {
            throw SupabaseError.serverError(statusCode, nil)
        }
        // The RPC returns a single int; PostgREST wraps it as the response body.
        if let count = Int(body.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return count
        }
        return 0
    }

    // MARK: - Full account wipe via delete_my_data RPC (with fallback)
    //
    // delete_my_data (posts + comments + reactions, incl. rows under rotated
    // device_ids) requires the pending Supabase migration in
    // supabase/migrations/20260716_delete_my_data_wipes_comments_reactions.sql.
    // Until it is applied, PostgREST answers 404 for the unknown function and
    // we fall back to delete_my_posts + client-side comment/reaction cleanup.
    @discardableResult
    static func deleteAllMyData() async throws -> Int {
        let urlString = "\(SupabaseConfig.restURL)/rpc/delete_my_data"
        guard let url = URL(string: urlString) else { throw SupabaseError.invalidURL }

        struct DeleteRequest: Codable {
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
        request.httpBody = try JSONEncoder().encode(DeleteRequest(
            requestingDeviceId: SupabaseConfig.deviceId,
            requestingAppleUserId: SupabaseConfig.appleUserID
        ))

        let (data, response) = try await session.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        let body = String(data: data, encoding: .utf8) ?? "nil"
        print("[API] deleteAllMyData: status=\(statusCode)")

        if statusCode == 404 {
            // Function not deployed yet — legacy two-step wipe.
            let count = try await deleteAllMyPosts()
            await deleteAllMyCommentsAndReactions()
            return count
        }
        guard (200...204).contains(statusCode) else {
            throw SupabaseError.serverError(statusCode, nil)
        }
        return Int(body.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    }

    // MARK: - Report a post (UGC moderation, App Review guideline 1.2)
    //
    // Inserts into post_reports (see the pending migration). Best effort by
    // design: the caller hides the post locally regardless, so a failure here
    // never blocks the user-protective action.
    static func reportPost(id: String, reason: String) async {
        let urlString = "\(SupabaseConfig.restURL)/post_reports"
        guard let url = URL(string: urlString) else { return }

        struct ReportRequest: Codable {
            let postId: String
            let reporterDeviceId: String
            let reason: String
            enum CodingKeys: String, CodingKey {
                case postId = "post_id"
                case reporterDeviceId = "reporter_device_id"
                case reason
            }
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.addValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("return=minimal", forHTTPHeaderField: "Prefer")

        do {
            request.httpBody = try JSONEncoder().encode(ReportRequest(
                postId: id,
                reporterDeviceId: SupabaseConfig.deviceId,
                reason: reason
            ))
            let (_, response) = try await session.data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            print("[API] reportPost: status=\(statusCode)")
        } catch {
            print("[API] reportPost failed: \(error)")
        }
    }

    // MARK: - Bulk delete own comments and reactions (account deletion)
    //
    // Best effort: removes the rows this device left on OTHER people's posts.
    // Uses the same x-device-id header contract as deleteComment, so the RLS
    // policy scopes the delete to rows owned by this device.
    static func deleteAllMyCommentsAndReactions() async {
        for table in ["cloud_comments", "cloud_reactions"] {
            let urlString = "\(SupabaseConfig.restURL)/\(table)?device_id=eq.\(SupabaseConfig.deviceId)"
            guard let url = URL(string: urlString) else { continue }

            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.addValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
            request.addValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
            request.addValue(SupabaseConfig.deviceId, forHTTPHeaderField: "x-device-id")
            request.addValue("return=minimal", forHTTPHeaderField: "Prefer")

            do {
                let (_, response) = try await session.data(for: request)
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                print("[API] deleteAllMy \(table): status=\(statusCode)")
            } catch {
                print("[API] deleteAllMy \(table) failed: \(error)")
            }
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

        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...204).contains(httpResponse.statusCode) else {
            throw SupabaseError.serverError((response as? HTTPURLResponse)?.statusCode, nil)
        }
    }

    // MARK: - Add reaction (upsert, ignore duplicates)

    static func addReaction(postId: String, type: String) async throws {
        let urlString = "\(SupabaseConfig.restURL)/cloud_reactions"
        guard let url = URL(string: urlString) else { throw SupabaseError.invalidURL }

        // apple_user_id lets the account-deletion RPC wipe a signed-in user's
        // reactions regardless of device_id rotation (migration
        // 20260717_reactions_apple_user_id.sql). Until that migration is
        // applied the column doesn't exist and PostgREST rejects the insert
        // with 400 — retry once without the key.
        var payload: [String: String] = [
            "post_id": postId,
            "reaction_type": type,
            "device_id": SupabaseConfig.deviceId
        ]
        if let appleUserId = SupabaseConfig.appleUserID {
            payload["apple_user_id"] = appleUserId
        }

        func send(_ payload: [String: String]) async throws -> HTTPURLResponse? {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
            request.addValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("resolution=ignore-duplicates", forHTTPHeaderField: "Prefer")
            request.httpBody = try JSONEncoder().encode(payload)
            let (_, response) = try await session.data(for: request)
            return response as? HTTPURLResponse
        }

        var httpResponse = try await send(payload)
        if httpResponse?.statusCode == 400, payload["apple_user_id"] != nil {
            payload["apple_user_id"] = nil
            httpResponse = try await send(payload)
        }
        guard let httpResponse, (200...204).contains(httpResponse.statusCode) else {
            throw SupabaseError.serverError(httpResponse?.statusCode, nil)
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

        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...204).contains(httpResponse.statusCode) else {
            throw SupabaseError.serverError((response as? HTTPURLResponse)?.statusCode, nil)
        }
    }

    // MARK: - AI Journal Summary (MiniMax via Edge Function)

    static func summarizeJournal(
        mode: String,
        language: String,
        entries: [(date: String, mood: String, text: String)]
    ) async throws -> String? {
        let urlString = "\(SupabaseConfig.projectURL)/functions/v1/summarize-journal"
        guard let url = URL(string: urlString) else { throw SupabaseError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")

        struct EntryPayload: Codable {
            let date: String
            let mood: String
            let text: String
        }
        struct SummarizeRequest: Codable {
            let mode: String
            let language: String
            let entries: [EntryPayload]
        }
        struct SummarizeResponse: Codable {
            let summary: String?
        }

        let payload = SummarizeRequest(
            mode: mode,
            language: language,
            entries: entries.map { EntryPayload(date: $0.date, mood: $0.mood, text: $0.text) }
        )
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return nil
        }

        let result = try JSONDecoder().decode(SummarizeResponse.self, from: data)
        return result.summary
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

    // MARK: - Fetch unread interaction counts (comments + reactions on own posts)

    static func fetchUnreadCount(since: Date) async -> (commentCount: Int, reactionCount: Int) {
        let urlString = "\(SupabaseConfig.restURL)/rpc/get_my_unread_count"
        guard let url = URL(string: urlString) else {
            print("[API] fetchUnreadCount: invalid URL")
            return (0, 0)
        }

        let iso = ISO8601DateFormatter()
        let sinceStr = iso.string(from: since)

        struct UnreadRequest: Codable {
            let requestingDeviceId: String
            let requestingAppleUserId: String?
            let since: String
            enum CodingKeys: String, CodingKey {
                case requestingDeviceId = "requesting_device_id"
                case requestingAppleUserId = "requesting_apple_user_id"
                case since
            }
        }

        let body = UnreadRequest(
            requestingDeviceId: SupabaseConfig.deviceId,
            requestingAppleUserId: SupabaseConfig.appleUserID,
            since: sinceStr
        )

        guard let jsonData = try? JSONEncoder().encode(body) else {
            print("[API] fetchUnreadCount: encoding failed")
            return (0, 0)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.addValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 10

        do {
            let (data, response) = try await session.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard (200..<300).contains(status) else {
                print("[API] fetchUnreadCount: status=\(status)")
                return (0, 0)
            }

            struct UnreadRow: Codable {
                let commentCount: Int
                let reactionCount: Int
                enum CodingKeys: String, CodingKey {
                    case commentCount = "comment_count"
                    case reactionCount = "reaction_count"
                }
            }

            if let rows = try? JSONDecoder().decode([UnreadRow].self, from: data),
               let first = rows.first {
                return (first.commentCount, first.reactionCount)
            }
        } catch {
            print("[API] fetchUnreadCount: \(error.localizedDescription)")
        }
        return (0, 0)
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
        // .distantPast (not Date()) so a parse failure is visible instead of
        // silently rendering an old comment as "just now".
        SupabaseTimestamp.parse(createdAt) ?? .distantPast
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

// MARK: - Supabase Error Body (from REST API)

private struct SupabaseErrorBody: Codable {
    let message: String
    let code: String?

    var userMessage: String {
        if message.contains("Please wait before posting again") || message.contains("wait") {
            return L10n.t("Please wait a moment before posting again.", "请稍等片刻再发布。")
        }
        if message.contains("Post cannot be empty") {
            return L10n.t("Post cannot be empty.", "内容不能为空。")
        }
        if message.contains("500 character") {
            return L10n.t("Post exceeds 500 character limit.", "内容超过500字限制。")
        }
        if message.contains("prohibited content") || message.contains("threats") || message.contains("hate speech") {
            return L10n.t("This content is not allowed.", "此内容不被允许。")
        }
        if message.contains("personal information") {
            return L10n.t("Please don't share personal contact information.", "请不要分享个人联系方式。")
        }
        if message.contains("Advertising") || message.contains("links") {
            return L10n.t("Links and advertising are not allowed.", "不允许发送链接和广告。")
        }
        return message
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
        case .invalidURL: L10n.t("Invalid URL", "无效的链接")
        case .serverError(let code, let detail):
            if let code { L10n.t("Server error (\(code))", "服务器错误（\(code)）") + (detail.map { ": \($0)" } ?? "") }
            // Detail without a code is already a user-facing localized message.
            else if let detail { detail }
            else { L10n.t("Server error", "服务器错误") }
        case .noData: L10n.t("No data returned", "未返回数据")
        case .moderation(let reason): reason
        }
    }
}
