import Foundation

/// Tiny localization helper for the widget — the app's L10n is app-target
/// code, so the widget mirrors the language choice from the snapshot.
enum WL {
    static func t(_ en: String, _ zh: String, lang: String) -> String {
        lang == "zh-Hans" ? zh : en
    }
}
