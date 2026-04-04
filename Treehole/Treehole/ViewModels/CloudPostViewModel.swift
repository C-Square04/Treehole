import Foundation
import SwiftData
import Observation

@Observable
final class CloudPostViewModel {
    var draftText: String = ""
    var draftMood: MoodTag = .calm
    var showCreation: Bool = false

    var characterCount: Int { draftText.count }
    var isValid: Bool { !draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && draftText.count <= 500 }

    func createPost(context: ModelContext, authorAlias: String, language: String) {
        let npcReply = generateNPCReply(for: draftMood, language: language)
        let post = CloudPost(
            authorAlias: authorAlias,
            moodTag: draftMood,
            text: draftText.trimmingCharacters(in: .whitespacesAndNewlines),
            npcReplyText: npcReply,
            sourceLanguage: language
        )
        context.insert(post)
        try? context.save()
        draftText = ""
        draftMood = .calm
        showCreation = false
    }

    func deletePost(_ post: CloudPost, context: ModelContext) {
        context.delete(post)
    }

    func resetDraft() {
        draftText = ""
        draftMood = .calm
    }

    // MARK: - NPC Reply Templates

    func generateNPCReply(for mood: MoodTag, language: String) -> String {
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
