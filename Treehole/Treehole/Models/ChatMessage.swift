import Foundation
import SwiftData

@Model
final class ChatMessage {
    var id: String = UUID().uuidString
    var text: String = ""
    var isFromUser: Bool = true
    var createdAt: Date = Date()

    init() {}
    init(text: String, isFromUser: Bool) {
        self.id = UUID().uuidString
        self.text = text
        self.isFromUser = isFromUser
        self.createdAt = Date()
    }
}
