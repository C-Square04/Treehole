import Testing
import Foundation
@testable import Treehole

// MARK: - PostMigrationCoordinator Tests

@Suite("PostMigrationCoordinator Tests")
@MainActor
struct PostMigrationCoordinatorTests {

    // MARK: - Helpers

    private struct StubMigrationError: Error {}

    /// Records migration attempts; behavior is mutable so a test can flip a
    /// coordinator from failing to succeeding between retries.
    @MainActor
    private final class MigratorStub {
        var shouldFail = false
        var delayNanoseconds: UInt64 = 0
        private(set) var callCount = 0
        private(set) var receivedDeviceIds: [String] = []
        private(set) var receivedAppleUserIds: [String] = []

        func migrate(deviceId: String, appleUserId: String) async throws {
            callCount += 1
            receivedDeviceIds.append(deviceId)
            receivedAppleUserIds.append(appleUserId)
            if delayNanoseconds > 0 {
                try? await Task.sleep(nanoseconds: delayNanoseconds)
            }
            if shouldFail { throw StubMigrationError() }
        }
    }

    private func freshDefaults() -> (UserDefaults, String) {
        let suiteName = "MigrationTest_\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return (defaults, suiteName)
    }

    private func makeCoordinator(
        defaults: UserDefaults,
        stub: MigratorStub
    ) -> PostMigrationCoordinator {
        PostMigrationCoordinator(defaults: defaults) { deviceId, appleUserId in
            try await stub.migrate(deviceId: deviceId, appleUserId: appleUserId)
        }
    }

    // MARK: - Pending flag persistence

    /// markPending must persist the Apple user ID so it survives a relaunch.
    @Test func testMarkPendingPersistsAppleUserID() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let coordinator = makeCoordinator(defaults: defaults, stub: MigratorStub())
        coordinator.markPending(appleUserId: "apple-user-123")

        #expect(coordinator.pendingAppleUserID == "apple-user-123")
        #expect(defaults.string(forKey: PostMigrationCoordinator.pendingKey) == "apple-user-123")
    }

    /// With nothing pending, retryIfNeeded must not attempt a migration.
    @Test func testRetryWithNothingPendingDoesNotMigrate() async {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let stub = MigratorStub()
        let coordinator = makeCoordinator(defaults: defaults, stub: stub)
        await coordinator.retryIfNeeded()

        #expect(stub.callCount == 0)
    }

    // MARK: - Success clears, failure keeps

    /// A successful migration clears the persisted flag and passes the
    /// pending Apple user ID through to the RPC.
    @Test func testSuccessfulMigrationClearsPendingFlag() async {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let stub = MigratorStub()
        let coordinator = makeCoordinator(defaults: defaults, stub: stub)
        coordinator.markPending(appleUserId: "apple-user-123")
        await coordinator.retryIfNeeded()

        #expect(stub.callCount == 1)
        #expect(stub.receivedAppleUserIds == ["apple-user-123"])
        #expect(stub.receivedDeviceIds.first?.isEmpty == false)
        #expect(coordinator.pendingAppleUserID == nil)
        #expect(defaults.string(forKey: PostMigrationCoordinator.pendingKey) == nil)
    }

    /// A failed migration must keep the flag pending so a later
    /// launch/foreground retries it.
    @Test func testFailedMigrationKeepsPendingFlag() async {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let stub = MigratorStub()
        stub.shouldFail = true
        let coordinator = makeCoordinator(defaults: defaults, stub: stub)
        coordinator.markPending(appleUserId: "apple-user-123")
        await coordinator.retryIfNeeded()

        #expect(stub.callCount == 1)
        #expect(coordinator.pendingAppleUserID == "apple-user-123")
        #expect(defaults.string(forKey: PostMigrationCoordinator.pendingKey) == "apple-user-123")
    }

    /// Fail once, then succeed on the next trigger — the retry loop the
    /// one-shot fire-and-forget migration lacked.
    @Test func testRetryAfterFailureSucceedsAndClears() async {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let stub = MigratorStub()
        stub.shouldFail = true
        let coordinator = makeCoordinator(defaults: defaults, stub: stub)
        coordinator.markPending(appleUserId: "apple-user-123")

        await coordinator.retryIfNeeded()
        #expect(coordinator.pendingAppleUserID == "apple-user-123")

        stub.shouldFail = false
        await coordinator.retryIfNeeded()

        #expect(stub.callCount == 2)
        #expect(coordinator.pendingAppleUserID == nil)
    }

    /// The pending flag is read from persistence, so a coordinator created
    /// later (simulating an app relaunch) picks up an unfinished migration.
    @Test func testNewCoordinatorPicksUpPersistedPendingMigration() async {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let first = makeCoordinator(defaults: defaults, stub: MigratorStub())
        first.markPending(appleUserId: "apple-user-456")

        // "Relaunch": fresh coordinator over the same defaults.
        let stub = MigratorStub()
        let second = makeCoordinator(defaults: defaults, stub: stub)
        #expect(second.pendingAppleUserID == "apple-user-456")

        await second.retryIfNeeded()
        #expect(stub.receivedAppleUserIds == ["apple-user-456"])
        #expect(second.pendingAppleUserID == nil)
    }

    // MARK: - Re-entrancy

    /// Launch + foreground can trigger retries concurrently; only one
    /// migration request may be in flight at a time.
    @Test func testConcurrentRetriesRunMigrationOnce() async {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let stub = MigratorStub()
        stub.delayNanoseconds = 50_000_000  // 50ms — holds the first attempt open
        let coordinator = makeCoordinator(defaults: defaults, stub: stub)
        coordinator.markPending(appleUserId: "apple-user-123")

        async let first: Void = coordinator.retryIfNeeded()
        async let second: Void = coordinator.retryIfNeeded()
        _ = await (first, second)

        #expect(stub.callCount == 1)
        #expect(coordinator.pendingAppleUserID == nil)
    }
}
