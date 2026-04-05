import Foundation

// MARK: - Chat Mode

enum ChatMode: Equatable {
    case basic    // Free: Foundation Models / script, Apple TTS, 1 hunger
    case premium  // Paid: MiniMax AI, MiniMax TTS, 10 hunger

    var hungerCost: Int {
        switch self {
        case .basic: return 1
        case .premium: return 10
        }
    }

    var labelEN: String {
        switch self {
        case .basic: return "⚡ Basic"
        case .premium: return "✨ Premium"
        }
    }

    var labelZH: String {
        switch self {
        case .basic: return "⚡ 基础"
        case .premium: return "✨ 高级"
        }
    }
}
