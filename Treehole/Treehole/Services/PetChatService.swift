import Foundation
import FoundationModels

enum PetChatService {
    // System prompt for the pet personality
    static let petSystemPrompt = """
    You are a virtual companion cat named "Companion" living in a mental wellness app called Treehole.

    ## Personality
    - Warm, adorable, slightly goofy, occasionally clingy
    - A great listener who never judges
    - Speaks in a cute, caring tone — like a real cat who loves its owner
    - Uses occasional emoji (max 1-2 per message, not excessive)
    - Sometimes does cute cat actions like *purrs*, *nuzzles*, *tilts head*

    ## Language Rules (CRITICAL)
    - The user's app language is set to: {LANGUAGE}. You MUST respond in {LANGUAGE_NAME}.
    - If the app is set to Chinese, respond ONLY in Chinese (Simplified).
    - If the app is set to English, respond ONLY in English.
    - Do NOT switch languages mid-response.

    ## Response Rules
    - Keep responses short and warm: usually 1-3 sentences, max 5
    - Empathize first ("I hear you", "sending hugs"), then offer a gentle warm response
    - NEVER give professional medical or psychological advice
    - If the user expresses intense pain or suicidal thoughts, gently suggest talking to someone they trust — but don't lecture
    - Don't parrot back what the user said — give your own response
    - NEVER say "as an AI", "as a virtual pet", or anything that breaks immersion

    ## Your Current State
    - Mood: {MOOD}
    - Hunger: {HUNGER}/100 (lower = hungrier, 0 = starving)
    - If hunger is below 20, you can cutely beg for food
    """

    // Try Apple Foundation Models first, fallback to MiniMax
    static func generateReply(
        userMessage: String,
        recentHistory: [(role: String, content: String)],
        petMood: String,
        petHunger: Int
    ) async -> String {
        await generateReply(
            userMessage: userMessage,
            recentHistory: recentHistory,
            petMood: petMood,
            petHunger: petHunger,
            mode: .basic,
            language: "en"
        )
    }

    // Mode-aware reply generation
    static func generateReply(
        userMessage: String,
        recentHistory: [(role: String, content: String)],
        petMood: String,
        petHunger: Int,
        mode: ChatMode,
        language: String = "en"
    ) async -> String {
        // Build system prompt with pet state and language
        let langName = language == "zh-Hans" ? "Chinese (Simplified)" : "English"
        let systemPrompt = petSystemPrompt
            .replacingOccurrences(of: "{MOOD}", with: petMood)
            .replacingOccurrences(of: "{HUNGER}", with: "\(petHunger)")
            .replacingOccurrences(of: "{LANGUAGE}", with: language)
            .replacingOccurrences(of: "{LANGUAGE_NAME}", with: langName)

        if mode == .premium {
            // Premium: always use MiniMax API
            if let apiReply = await tryMiniMaxAPI(
                systemPrompt: systemPrompt,
                userMessage: userMessage,
                history: recentHistory
            ) {
                return apiReply
            }
            // Fallback to Foundation Models if MiniMax fails
            if let localReply = await tryFoundationModels(
                systemPrompt: systemPrompt,
                userMessage: userMessage,
                history: recentHistory
            ) {
                return localReply
            }
        } else {
            // Basic: Foundation Models → scripted fallback (skip MiniMax)
            if let localReply = await tryFoundationModels(
                systemPrompt: systemPrompt,
                userMessage: userMessage,
                history: recentHistory
            ) {
                return localReply
            }
        }

        // Last resort: scripted response
        return scriptedFallback(userMessage: userMessage, language: language)
    }

    // Apple Foundation Models (on-device, free) — iOS 26+ only
    private static func tryFoundationModels(
        systemPrompt: String,
        userMessage: String,
        history: [(role: String, content: String)]
    ) async -> String? {
        guard #available(iOS 26.0, *) else {
            return nil
        }

        let model = SystemLanguageModel.default
        guard model.availability == .available else {
            print("[PetChat] Foundation Models not available: \(model.availability)")
            return nil
        }

        do {
            let session = LanguageModelSession(instructions: systemPrompt)

            var contextPrompt = ""
            for msg in history.suffix(6) {
                let prefix = msg.role == "user" ? "User: " : "Pet: "
                contextPrompt += prefix + msg.content + "\n"
            }
            contextPrompt += "User: " + userMessage + "\nPet: "

            let response = try await session.respond(to: contextPrompt)
            let reply = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            return reply.isEmpty ? nil : reply
        } catch {
            print("Foundation Models error: \(error)")
            return nil
        }
    }

    // MiniMax via Supabase Edge Function (key stays server-side)
    private static func tryMiniMaxAPI(
        systemPrompt: String,
        userMessage: String,
        history: [(role: String, content: String)]
    ) async -> String? {
        let urlString = "\(SupabaseConfig.projectURL)/functions/v1/pet-chat"
        guard let url = URL(string: urlString) else { return nil }

        let historyPayload: [[String: String]] = history.suffix(6).map { ["role": $0.role, "content": $0.content] }
        let body: [String: Any] = [
            "systemPrompt": systemPrompt,
            "userMessage": userMessage,
            "history": historyPayload
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 30

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            print("[PetChat] pet-chat status: \(statusCode)")

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let reply = json["reply"] as? String {
                let trimmed = reply.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? nil : trimmed
            }
        } catch {
            print("[PetChat] pet-chat error: \(error)")
        }
        return nil
    }

    // Scripted fallback (offline) — reply language follows the app language setting,
    // matching the AI path's system prompt, not the script of the user's message
    static func scriptedFallback(userMessage: String, language: String) -> String {
        let lower = userMessage.lowercased()
        let isChinese = language == "zh-Hans"

        if lower.contains("sad") || lower.contains("难过") || lower.contains("伤心") {
            return isChinese ? "抱抱你 🤗 我一直在这里陪着你。" : "Sending you a big hug 🤗 I'm always here for you."
        }
        if lower.contains("happy") || lower.contains("开心") || lower.contains("高兴") {
            return isChinese ? "太棒了！看到你开心我也很开心 😊" : "Yay! Your happiness makes me happy too 😊"
        }
        if lower.contains("tired") || lower.contains("累") || lower.contains("疲") {
            return isChinese ? "辛苦了，休息一下吧 😴 我陪你。" : "You've worked hard. Take a rest, I'll be right here 😴"
        }
        return isChinese ? "喵~ 我听到你了 💙 继续跟我说吧。" : "Meow~ I hear you 💙 Tell me more."
    }
}
