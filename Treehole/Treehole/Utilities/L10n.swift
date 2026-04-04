import Foundation

enum L10n {
    static var lang: String = "en"  // Set by AppState on launch/change

    static func t(_ en: String, _ zh: String) -> String {
        lang == "zh-Hans" ? zh : en
    }
}
