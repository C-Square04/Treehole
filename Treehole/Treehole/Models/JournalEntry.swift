import Foundation
import SwiftData

@Model
final class JournalEntry {
    var id: String
    var createdAt: Date
    var moodTagRaw: String
    var text: String
    var photoFilenames: [String]?

    init(moodTag: MoodTag, text: String) {
        self.id = UUID().uuidString
        self.createdAt = Date()
        self.moodTagRaw = moodTag.rawValue
        self.text = text
        self.photoFilenames = nil
    }

    var photoCount: Int {
        photoFilenames?.count ?? 0
    }

    var moodTag: MoodTag {
        get { MoodTag(rawValue: moodTagRaw) ?? .calm }
        set { moodTagRaw = newValue.rawValue }
    }

    var formattedDate: String {
        createdAt.formatted(date: .abbreviated, time: .shortened)
    }

    var dayOfWeek: String {
        createdAt.formatted(.dateTime.weekday(.wide))
    }
}
