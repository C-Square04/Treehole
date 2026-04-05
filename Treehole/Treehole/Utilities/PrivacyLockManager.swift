import Foundation
import LocalAuthentication
import Observation

@Observable
final class PrivacyLockManager {
    // Settings
    var isCloudLockEnabled: Bool = false { didSet { save() } }
    var isJournalLockEnabled: Bool = false { didSet { save() } }
    var lockPIN: String? = nil { didSet { save() } }  // Optional PIN fallback

    // State
    var isCloudUnlocked: Bool = false
    var isJournalUnlocked: Bool = false

    init() { load() }

    // Authenticate with FaceID/TouchID, fallback to PIN
    func authenticate(for type: LockType) async -> Bool {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            do {
                let success = try await context.evaluatePolicy(
                    .deviceOwnerAuthenticationWithBiometrics,
                    localizedReason: type == .cloud
                        ? "Unlock My Clouds"
                        : "Unlock Journal"
                )
                if success {
                    if type == .cloud { isCloudUnlocked = true }
                    else { isJournalUnlocked = true }
                }
                return success
            } catch {
                return false
            }
        }
        // No biometrics available — use PIN if set
        return false
    }

    func authenticateWithPIN(_ pin: String, for type: LockType) -> Bool {
        guard pin == lockPIN else { return false }
        if type == .cloud { isCloudUnlocked = true }
        else { isJournalUnlocked = true }
        return true
    }

    func lock() {
        isCloudUnlocked = false
        isJournalUnlocked = false
    }

    enum LockType { case cloud, journal }

    private func save() {
        let defaults = UserDefaults.standard
        defaults.set(isCloudLockEnabled, forKey: "privacyLockCloud")
        defaults.set(isJournalLockEnabled, forKey: "privacyLockJournal")
        defaults.set(lockPIN, forKey: "privacyLockPIN")
    }

    private func load() {
        let defaults = UserDefaults.standard
        isCloudLockEnabled = defaults.bool(forKey: "privacyLockCloud")
        isJournalLockEnabled = defaults.bool(forKey: "privacyLockJournal")
        lockPIN = defaults.string(forKey: "privacyLockPIN")
    }
}
