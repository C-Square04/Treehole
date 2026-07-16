#if DEBUG
import Foundation
import SwiftData

// MARK: - UI Test Support (Debug builds only)

/// Launch-argument hooks for deterministic UI tests. SwiftData persists across
/// test runs (there is no per-test store reset), so without these hooks tests
/// inherit whatever state earlier tests — or earlier runs — left behind
/// (e.g. a pet fed to 100/100 disables the Feed button).
enum UITestSupport {
    static var isResetStateRequested: Bool {
        CommandLine.arguments.contains("--uitest-reset-state")
    }

    /// Puts the pet and economy into a known mid-range state so economy-driven
    /// controls (Feed, watering, shop) are enabled and their outcomes are
    /// observable. Deliberately does NOT touch journal entries, plants, or
    /// UserDefaults — tests that need those create them through the UI.
    static func applyLaunchOverridesIfNeeded(context: ModelContext) {
        guard isResetStateRequested else { return }

        if let pets = try? context.fetch(FetchDescriptor<Pet>()) {
            for pet in pets {
                pet.hungerLevel = 50
                pet.energy = 50
            }
        }
        if let economies = try? context.fetch(FetchDescriptor<Economy>()) {
            for economy in economies {
                economy.food = 50
            }
        }
        try? context.save()
        print("[UITest] applied --uitest-reset-state (pet 50/50, food 50)")
    }
}
#endif
