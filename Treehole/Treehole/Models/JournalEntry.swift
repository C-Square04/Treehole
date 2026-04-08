import Foundation
import SwiftData

@Model
final class JournalEntry {
    var id: String = UUID().uuidString
    var createdAt: Date = Date()
    var moodTagRaw: String = "calm"
    var text: String = ""
    var photoFilenames: [String]? = nil

    // Audio (voice note)
    var audioFilename: String? = nil
    var audioTranscript: String? = nil
    var audioDurationSeconds: Double? = nil

    // Location
    var latitude: Double? = nil
    var longitude: Double? = nil
    var locationName: String? = nil

    init() {}

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
