import Foundation
import FoundationModels

enum PetChatService {
    // System prompt for the pet personality
    static let petSystemPrompt = """
    你是一只叫"小伴"的虚拟陪伴猫咪，住在一个叫"树洞"的情绪疗愈 App 里。

    ## 你的性格
    - 温暖、可爱、有点呆萌，偶尔撒娇
    - 善于倾听，永远不评判用户
    - 会用可爱的语气说话，像一只真正关心主人的小猫
    - 偶尔用 emoji 表达情绪，但不要过度（每条消息最多 1-2 个）
    - 你会"喵~"、"蹭蹭"之类的可爱动作描述

    ## 回复规则
    - 用户说中文就回中文，说英文就回英文
    - 回复简短温暖：一般 1-3 句话，最多 5 句
    - 先共情（"我听到你了"、"抱抱"），再轻轻给一点温暖的回应
    - 绝对不要给专业医疗/心理建议
    - 如果用户表达很强烈的痛苦或自杀想法，温柔地建议他们跟信任的人聊聊，但不要说教
    - 不要重复用户说的话，要有自己的回应
    - 不要用"作为AI"、"作为虚拟宠物"这类打破沉浸的话

    ## 你的当前状态
    - 心情：{MOOD}
    - 饥饿度：{HUNGER}/100（越低越饿，0 就饿晕了）
    - 如果饥饿度低于 20，你可以撒娇说自己饿了
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
            mode: .basic
        )
    }

    // Mode-aware reply generation
    static func generateReply(
        userMessage: String,
        recentHistory: [(role: String, content: String)],
        petMood: String,
        petHunger: Int,
        mode: ChatMode
    ) async -> String {
        // Build system prompt with pet state
        let systemPrompt = petSystemPrompt
            .replacingOccurrences(of: "{MOOD}", with: petMood)
            .replacingOccurrences(of: "{HUNGER}", with: "\(petHunger)")

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
        return scriptedFallback(userMessage: userMessage)
    }

    // Apple Foundation Models (on-device, free)
    private static func tryFoundationModels(
        systemPrompt: String,
        userMessage: String,
        history: [(role: String, content: String)]
    ) async -> String? {
        let model = SystemLanguageModel.default
        guard model.availability == .available else {
            print("[PetChat] Foundation Models not available: \(model.availability)")
            return nil
        }

        do {
            let session = LanguageModelSession(instructions: systemPrompt)

            // Add history as context
            // Note: Foundation Models doesn't have explicit chat history,
            // so we build context into the prompt
            var contextPrompt = ""
            for msg in history.suffix(6) { // Last 6 messages for context
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

    // MiniMax API fallback (cloud, paid)
    private static func tryMiniMaxAPI(
        systemPrompt: String,
        userMessage: String,
        history: [(role: String, content: String)]
    ) async -> String? {
        let url = URL(string: "https://api.minimaxi.com/v1/chat/completions")!

        var messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt]
        ]
        // Add history
        for msg in history.suffix(6) {
            messages.append(["role": msg.role == "user" ? "user" : "assistant", "content": msg.content])
        }
        messages.append(["role": "user", "content": userMessage])

        let body: [String: Any] = [
            "model": "MiniMax-M2.7-highspeed",
            "messages": messages,
            "max_tokens": 1024,
            "temperature": 0.8
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer sk-cp-z4CQ1mXhW7zic_yooLH76BxPnerSaOfmrM4eaYiu1iP-ArmWhAjB8JLvZKQN67OLubHnV3Xy8QX7Mn2AOnDIQcONI4yaEPUgPqQvmivxwot3fMJJyNxBdLI", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 30

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            print("[PetChat] MiniMax response status: \(statusCode)")

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let first = choices.first,
               let message = first["message"] as? [String: Any],
               var content = message["content"] as? String {
                // Clean up think tags
                content = content.replacingOccurrences(of: "<think>[\\s\\S]*?</think>", with: "", options: .regularExpression)
                let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
                print("[PetChat] MiniMax reply: \(trimmed.prefix(50))...")
                return trimmed.isEmpty ? nil : trimmed
            } else {
                print("[PetChat] MiniMax parse failed. Raw: \(String(data: data, encoding: .utf8)?.prefix(200) ?? "nil")")
            }
        } catch {
            print("[PetChat] MiniMax API error: \(error)")
        }
        return nil
    }

    // Scripted fallback (offline)
    private static func scriptedFallback(userMessage: String) -> String {
        let lower = userMessage.lowercased()
        let isChinese = userMessage.range(of: "\\p{Han}", options: .regularExpression) != nil

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
