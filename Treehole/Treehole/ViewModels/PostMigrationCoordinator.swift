import Foundation

/// Tracks the device_id → apple_user_id post migration that must run after
/// Sign in with Apple. The pending Apple user ID is persisted so a failed
/// migration (offline sign-in, RPC timeout) retries on the next
/// launch/foreground instead of leaving orphaned posts that match neither
/// identifier after a reinstall.
final class PostMigrationCoordinator {
    static let pendingKey = "pendingPostMigrationAppleUserID"

    private let defaults: UserDefaults
    /// Injectable for tests — production performs the Supabase RPC.
    private let migrate: (_ deviceId: String, _ appleUserId: String) async throws -> Void
    /// Prevents overlapping attempts when foreground/launch triggers coincide.
    private var isRetrying = false

    init(
        defaults: UserDefaults = .standard,
        migrate: @escaping (_ deviceId: String, _ appleUserId: String) async throws -> Void = { deviceId, appleUserId in
            try await SupabaseService.migratePostsToAppleUser(deviceId: deviceId, appleUserId: appleUserId)
        }
    ) {
        self.defaults = defaults
        self.migrate = migrate
    }

    /// Apple user ID whose migration the server has not confirmed yet.
    var pendingAppleUserID: String? {
        defaults.string(forKey: Self.pendingKey)
    }

    /// Records the migration as pending. Synchronous so the flag survives even
    /// if the app dies before the first attempt runs.
    func markPending(appleUserId: String) {
        defaults.set(appleUserId, forKey: Self.pendingKey)
    }

    /// Runs the migration if one is pending. The flag is cleared only on a
    /// successful response; failures are logged and left for the next trigger.
    func retryIfNeeded() async {
        guard !isRetrying, let appleUserId = pendingAppleUserID else { return }
        isRetrying = true
        defer { isRetrying = false }
        do {
            try await migrate(SupabaseConfig.deviceId, appleUserId)
            defaults.removeObject(forKey: Self.pendingKey)
        } catch {
            print("[Migration] Device→Apple post migration failed, will retry on next launch/foreground: \(error)")
        }
    }
}
