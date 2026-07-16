//
//  PrivacyLockManagerTests.swift
//  TreeholeTests
//

import Testing
import Foundation
@testable import Treehole

// MARK: - PrivacyLockManager Tests
// The manager persists to fixed UserDefaults keys (pl_*) and the fixed
// Keychain account "privacyPasscode" — neither is injectable — so the suite
// runs serialized, snapshots the real values before each test, and restores
// them afterward. Biometric availability depends on simulator enrollment, so
// no test asserts isBiometricEnabled after setPasscode (it may auto-enable).

@Suite("PrivacyLockManager Tests", .serialized)
final class PrivacyLockManagerTests {

    private static let passcodeKey = "privacyPasscode"
    private static let defaultsKeys = ["pl_cloudLock", "pl_journalLock", "pl_biometric"]

    private let savedPasscode: String?
    private let savedDefaults: [String: Any]

    init() {
        savedPasscode = KeychainHelper.load(forKey: Self.passcodeKey)
        var snapshot: [String: Any] = [:]
        for key in Self.defaultsKeys {
            snapshot[key] = UserDefaults.standard.object(forKey: key)
        }
        savedDefaults = snapshot
        // Clean slate for each test
        KeychainHelper.delete(forKey: Self.passcodeKey)
        for key in Self.defaultsKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    deinit {
        if let savedPasscode {
            KeychainHelper.save(savedPasscode, forKey: Self.passcodeKey)
        } else {
            KeychainHelper.delete(forKey: Self.passcodeKey)
        }
        for key in Self.defaultsKeys {
            if let value = savedDefaults[key] {
                UserDefaults.standard.set(value, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }

    // MARK: - Passcode set / verify / change / remove

    @Test func testSetAndVerifyPasscode() {
        let manager = PrivacyLockManager()
        #expect(manager.hasPasscode == false)
        #expect(manager.needsPasscodeSetup == true)
        #expect(manager.verifyPasscode("1234") == false) // nothing stored yet

        manager.setPasscode("1234")
        #expect(manager.hasPasscode == true)
        #expect(manager.needsPasscodeSetup == false)
        #expect(manager.verifyPasscode("1234") == true)
        #expect(manager.verifyPasscode("9999") == false)
        #expect(manager.verifyPasscode("") == false)
    }

    @Test func testChangePasscodeRequiresOldPasscode() {
        let manager = PrivacyLockManager()
        manager.setPasscode("1234")

        // Wrong old passcode: nothing changes
        #expect(manager.changePasscode(old: "0000", new: "5678") == false)
        #expect(manager.verifyPasscode("1234") == true)
        #expect(manager.verifyPasscode("5678") == false)

        // Correct old passcode: new one replaces it
        #expect(manager.changePasscode(old: "1234", new: "5678") == true)
        #expect(manager.verifyPasscode("5678") == true)
        #expect(manager.verifyPasscode("1234") == false)
        #expect(manager.hasPasscode == true)
    }

    @Test func testRemovePasscodeWrongVerifyChangesNothing() {
        let manager = PrivacyLockManager()
        #expect(manager.removePasscode(verify: "1234") == false) // no passcode set

        manager.setPasscode("1234")
        manager.enableLock(for: .journal)
        #expect(manager.removePasscode(verify: "0000") == false)
        #expect(manager.hasPasscode == true)
        #expect(manager.isJournalLockEnabled == true)
        #expect(manager.verifyPasscode("1234") == true)
    }

    @Test func testRemovePasscodeCascadesDisable() {
        let manager = PrivacyLockManager()
        manager.setPasscode("1234")
        manager.enableLock(for: .cloud)
        manager.enableLock(for: .journal)

        #expect(manager.removePasscode(verify: "1234") == true)
        #expect(manager.hasPasscode == false)
        #expect(manager.needsPasscodeSetup == true)
        #expect(manager.isCloudLockEnabled == false)
        #expect(manager.isJournalLockEnabled == false)
        #expect(manager.isBiometricEnabled == false)
        #expect(manager.verifyPasscode("1234") == false) // keychain wiped
    }

    // MARK: - Lock / unlock state machine

    @Test func testIsLockedRequiresEnabledAndNotUnlocked() {
        let manager = PrivacyLockManager()
        #expect(manager.isLocked(.cloud) == false)
        #expect(manager.isLocked(.journal) == false)

        manager.enableLock(for: .journal)
        #expect(manager.isLocked(.journal) == true)
        #expect(manager.isLocked(.cloud) == false)

        manager.isJournalUnlocked = true
        #expect(manager.isLocked(.journal) == false)

        manager.lockAll()
        #expect(manager.isLocked(.journal) == true)

        manager.disableLock(for: .journal)
        #expect(manager.isLocked(.journal) == false)
        #expect(manager.isJournalUnlocked == false) // disable also clears unlock
    }

    @Test func testAuthenticateWithPasscodeUnlocksOnlyRequestedType() {
        let manager = PrivacyLockManager()
        manager.setPasscode("2468")
        manager.enableLock(for: .cloud)
        manager.enableLock(for: .journal)

        #expect(manager.authenticateWithPasscode("0000", for: .cloud) == false)
        #expect(manager.isLocked(.cloud) == true)

        #expect(manager.authenticateWithPasscode("2468", for: .cloud) == true)
        #expect(manager.isLocked(.cloud) == false)
        #expect(manager.isLocked(.journal) == true) // journal stays locked
    }

    @Test func testLockAllRelocksBothTypes() {
        let manager = PrivacyLockManager()
        manager.setPasscode("2468")
        manager.enableLock(for: .cloud)
        manager.enableLock(for: .journal)
        #expect(manager.authenticateWithPasscode("2468", for: .cloud) == true)
        #expect(manager.authenticateWithPasscode("2468", for: .journal) == true)

        manager.lockAll()
        #expect(manager.isLocked(.cloud) == true)
        #expect(manager.isLocked(.journal) == true)
    }

    // MARK: - Account deletion reset

    @Test func testResetAfterAccountDeletionClearsEverything() {
        let manager = PrivacyLockManager()
        manager.setPasscode("1357")
        manager.enableLock(for: .cloud)
        manager.enableLock(for: .journal)
        #expect(manager.authenticateWithPasscode("1357", for: .journal) == true)

        manager.resetAfterAccountDeletion()
        #expect(manager.hasPasscode == false)
        #expect(manager.needsPasscodeSetup == true)
        #expect(manager.isCloudLockEnabled == false)
        #expect(manager.isJournalLockEnabled == false)
        #expect(manager.isBiometricEnabled == false)
        #expect(manager.isCloudUnlocked == false)
        #expect(manager.isJournalUnlocked == false)
        #expect(manager.isLocked(.cloud) == false)
        #expect(manager.isLocked(.journal) == false)
        #expect(manager.verifyPasscode("1357") == false)
        #expect(KeychainHelper.load(forKey: Self.passcodeKey) == nil)
    }

    // MARK: - Persistence

    @Test func testPersistenceAcrossInstances() {
        let first = PrivacyLockManager()
        first.setPasscode("9012")
        first.enableLock(for: .cloud)

        let second = PrivacyLockManager()
        #expect(second.hasPasscode == true)
        #expect(second.isCloudLockEnabled == true)
        #expect(second.isJournalLockEnabled == false)
        // Runtime unlock state is never persisted — a new instance starts locked
        #expect(second.isLocked(.cloud) == true)
    }

    // MARK: - KeychainHelper

    @Test func testKeychainHelperRoundTrip() {
        let key = "test_keychain_\(UUID().uuidString)"
        #expect(KeychainHelper.load(forKey: key) == nil)

        KeychainHelper.save("first", forKey: key)
        #expect(KeychainHelper.load(forKey: key) == "first")

        KeychainHelper.save("second", forKey: key) // overwrite replaces
        #expect(KeychainHelper.load(forKey: key) == "second")

        KeychainHelper.delete(forKey: key)
        #expect(KeychainHelper.load(forKey: key) == nil)
    }
}
