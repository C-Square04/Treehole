import Foundation

// MARK: - Analytics Service
// Fire-and-forget. Never blocks UI. Never throws. Never shows errors to user.
// PRIVACY: Only collects device_id (anon UUID), optional apple_user_id, and
//          categorical metadata (mood, language, count). NO user text content.

enum AnalyticsService {

    // MARK: - Test Seam

    /// When true, track() drops events before any network work.
    /// Unit tests set this so they never write rows to the production table.
    nonisolated(unsafe) static var isDisabled = false

    // MARK: - Public API

    static func track(_ event: String, properties: [String: String] = [:]) {
        guard !isDisabled else { return }
        // Skip analytics for system/seed accounts
        guard !shouldSkip(deviceId: SupabaseConfig.deviceId) else { return }

        Task.detached {
            await sendEvent(event, properties: properties)
        }
    }

    // MARK: - Pure Helpers (unit-tested)

    /// System/seed device IDs never report analytics.
    static func shouldSkip(deviceId: String) -> Bool {
        deviceId.hasPrefix("system") || deviceId.hasPrefix("npc-seed")
    }

    /// Builds the analytics_events row body. Pure so tests can verify the
    /// payload without touching the network.
    static func makeEventBody(
        event: String,
        properties: [String: String],
        deviceId: String,
        appleUserId: String?,
        language: String,
        appVersion: String
    ) -> [String: Any] {
        var body: [String: Any] = [
            "event_type": event,
            "device_id": deviceId,
            "language": language,
            "app_version": appVersion,
            "properties": properties
        ]
        if let appleUserId {
            body["apple_user_id"] = appleUserId
        } else {
            body["apple_user_id"] = NSNull()
        }
        return body
    }

    // MARK: - Private

    private static func sendEvent(_ event: String, properties: [String: String]) async {
        let urlString = "\(SupabaseConfig.restURL)/analytics_events"
        guard let url = URL(string: urlString) else {
            print("[Analytics] Invalid URL for event: \(event)")
            return
        }

        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"

        let body = makeEventBody(
            event: event,
            properties: properties,
            deviceId: SupabaseConfig.deviceId,
            appleUserId: SupabaseConfig.appleUserID,
            language: L10n.lang,
            appVersion: appVersion
        )

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            print("[Analytics] JSON serialization failed for event: \(event)")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("return=minimal", forHTTPHeaderField: "Prefer")
        request.httpBody = jsonData
        request.timeoutInterval = 10

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            if status < 200 || status >= 300 {
                print("[Analytics] Non-2xx status \(status) for event: \(event)")
            }
        } catch {
            print("[Analytics] Network error for event \(event): \(error.localizedDescription)")
        }
    }
}
