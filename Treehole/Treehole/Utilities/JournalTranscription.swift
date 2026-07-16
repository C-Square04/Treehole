import Foundation
import SwiftData
import Speech

/// Pure transcription-handling rules for journal voice notes, extracted from
/// JournalEntryEditor so the selection matrix and persistence rules are
/// unit-testable. The actual SFSpeechRecognizer passes stay in the editor.
enum JournalTranscription {

    /// Both locales are always run; `pick(zh:en:)` chooses the winner.
    static let recognitionLocales = [Locale(identifier: "zh-CN"), Locale(identifier: "en-US")]

    /// Recognition only runs once the user has granted Speech Recognition.
    static func canTranscribe(status: SFSpeechRecognizerAuthorizationStatus) -> Bool {
        status == .authorized
    }

    /// Best-transcript selection: the longer transcript wins, ties prefer zh
    /// (bilingual users tend to mix English words into Chinese speech, not
    /// the reverse), and empty strings collapse to nil.
    static func pick(zh: String?, en: String?) -> String? {
        let best: String?
        switch (zh, en) {
        case (let zh?, let en?) where zh.count >= en.count:
            best = zh
        case (_, let en?):
            best = en
        case (let zh?, _):
            best = zh
        default:
            best = nil
        }
        return (best?.isEmpty == false) ? best : nil
    }

    /// Persist a late-arriving transcript against the already-saved entry that
    /// owns this recording. This is what keeps transcripts from being lost when
    /// the user taps Save before background transcription finishes: the result
    /// lands on the entry via the model context instead of a dismissed view's
    /// @State. No-op when nothing was saved (editor cancelled) or the user
    /// deleted/replaced the recording (filename no longer matches any entry).
    @MainActor
    @discardableResult
    static func apply(transcript: String?, toEntryWithAudioFilename filename: String, context: ModelContext) -> Bool {
        guard let transcript else { return false }
        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { $0.audioFilename == filename }
        )
        guard let entry = try? context.fetch(descriptor).first else { return false }
        entry.audioTranscript = transcript
        try? context.save()
        return true
    }
}
