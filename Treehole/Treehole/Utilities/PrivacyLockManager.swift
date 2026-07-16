import Foundation
import LocalAuthentication
import Security
import Observation

@Observable
final class PrivacyLockManager {
    // Settings (persisted)
    var isCloudLockEnabled: Bool = false { didSet { save() } }
    var isJournalLockEnabled: Bool = false { didSet { save() } }
    var isBiometricEnabled: Bool = false { didSet { save() } }
    private(set) var hasPasscode: Bool = false

    private var isLoading = false

    // Runtime state (not persisted)
    var isCloudUnlocked: Bool = false
    var isJournalUnlocked: Bool = false

    // Biometric availability
    var biometricType: BiometricType {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        switch context.biometryType {
        case .faceID: return .faceID
        case .touchID: return .touchID
        default: return .none
        }
    }

    enum BiometricType {
        case none, faceID, touchID

        var label: String {
            switch self {
            case .none: return "Biometric"
            case .faceID: return "Face ID"
            case .touchID: return "Touch ID"
            }
        }

        var icon: String {
            switch self {
            case .none: return "lock"
            case .faceID: return "faceid"
            case .touchID: return "touchid"
            }
        }
    }

    enum LockType { case cloud, journal }

    init() { load() }

    // MARK: - Passcode Management

    func setPasscode(_ passcode: String) {
        KeychainHelper.save(passcode, forKey: "privacyPasscode")
        hasPasscode = true
        // Auto-enable biometric if available
        if biometricType != .none {
            isBiometricEnabled = true
        }
        save()
    }

    func verifyPasscode(_ input: String) -> Bool {
        guard let stored = KeychainHelper.load(forKey: "privacyPasscode") else { return false }
        return input == stored
    }

    func changePasscode(old: String, new: String) -> Bool {
        guard verifyPasscode(old) else { return false }
        setPasscode(new)
        return true
    }

    func removePasscode(verify: String) -> Bool {
        guard verifyPasscode(verify) else { return false }
        KeychainHelper.delete(forKey: "privacyPasscode")
        hasPasscode = false
        isCloudLockEnabled = false
        isJournalLockEnabled = false
        isBiometricEnabled = false
        save()
        return true
    }

    var needsPasscodeSetup: Bool {
        !hasPasscode
    }

    func enableLock(for type: LockType) {
        switch type {
        case .cloud: isCloudLockEnabled = true
        case .journal: isJournalLockEnabled = true
        }
        save()
    }

    func disableLock(for type: LockType) {
        switch type {
        case .cloud: isCloudLockEnabled = false; isCloudUnlocked = false
        case .journal: isJournalLockEnabled = false; isJournalUnlocked = false
        }
        save()
    }

    // MARK: - Unlock

    func authenticateWithBiometric(for type: LockType) async -> Bool {
        guard isBiometricEnabled else { return false }

        let context = LAContext()
        let reason = type == .cloud
            ? L10n.t("Unlock your private clouds", "解锁你的私密云朵")
            : L10n.t("Unlock your journal", "解锁你的日记")

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            if success {
                unlock(type)
            }
            return success
        } catch {
            return false
        }
    }

    func authenticateWithPasscode(_ input: String, for type: LockType) -> Bool {
        guard verifyPasscode(input) else { return false }
        unlock(type)
        return true
    }

    private func unlock(_ type: LockType) {
        switch type {
        case .cloud: isCloudUnlocked = true
        case .journal: isJournalUnlocked = true
        }
    }

    func isLocked(_ type: LockType) -> Bool {
        switch type {
        case .cloud: return isCloudLockEnabled && !isCloudUnlocked
        case .journal: return isJournalLockEnabled && !isJournalUnlocked
        }
    }

    func lockAll() {
        isCloudUnlocked = false
        isJournalUnlocked = false
    }

    /// Full reset for account deletion: removes the passcode from the Keychain
    /// and clears every lock setting, including `hasPasscode`, so no screen can
    /// demand a passcode that no longer exists.
    func resetAfterAccountDeletion() {
        KeychainHelper.delete(forKey: "privacyPasscode")
        hasPasscode = false
        isCloudLockEnabled = false
        isJournalLockEnabled = false
        isBiometricEnabled = false
        isCloudUnlocked = false
        isJournalUnlocked = false
        save()
    }

    // Legacy method name kept for compatibility
    func lock() {
        lockAll()
    }

    // MARK: - Persistence

    private func save() {
        guard !isLoading else { return }
        let d = UserDefaults.standard
        d.set(isCloudLockEnabled, forKey: "pl_cloudLock")
        d.set(isJournalLockEnabled, forKey: "pl_journalLock")
        d.set(isBiometricEnabled, forKey: "pl_biometric")
    }

    private func load() {
        isLoading = true
        let d = UserDefaults.standard
        isCloudLockEnabled = d.bool(forKey: "pl_cloudLock")
        isJournalLockEnabled = d.bool(forKey: "pl_journalLock")
        isBiometricEnabled = d.bool(forKey: "pl_biometric")
        hasPasscode = KeychainHelper.load(forKey: "privacyPasscode") != nil
        isLoading = false
    }
}

// MARK: - Keychain Helper

enum KeychainHelper {
    static func save(_ value: String, forKey key: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func load(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
