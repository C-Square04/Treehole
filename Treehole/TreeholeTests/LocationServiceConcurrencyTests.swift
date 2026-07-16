import Testing
import Foundation
import CoreLocation
@testable import Treehole

// MARK: - LocationService Concurrency Tests

// Regression coverage for the continuation-clobber bug: a second concurrent
// fetch used to overwrite the stored continuation, leaving the first caller
// awaiting forever. Real GPS is unavailable in the test sandbox, so these
// tests verify structural guarantees (every caller completes, delegate
// callbacks are safe without pending waiters) rather than location values.
@Suite("LocationService Concurrency Tests")
@MainActor
struct LocationServiceConcurrencyTests {

    /// Advertised timeout must exist so callers can never await forever.
    @Test func testTimeoutConstantIsTenSeconds() {
        #expect(LocationService.locationTimeout == 10)
    }

    /// Two overlapping fetches must BOTH complete — the first caller must not
    /// be left suspended when a second fetch starts. Bounded by a watchdog
    /// slightly longer than the service's own 10s timeout, plus a time limit
    /// so a regression fails instead of hanging the test run.
    @Test(.timeLimit(.minutes(1))) func testConcurrentFetchesBothComplete() async {
        let service = LocationService()
        let completed = await withTaskGroup(of: Bool.self) { group in
            group.addTask { @MainActor in
                _ = await service.fetchCurrentLocation()
                return true
            }
            group.addTask { @MainActor in
                _ = await service.fetchCurrentLocation()
                return true
            }
            group.addTask {
                // Watchdog: auth polling (4s) + location timeout (10s) + margin
                try? await Task.sleep(nanoseconds: 16_000_000_000)
                return false
            }
            var results: [Bool] = []
            for await result in group {
                results.append(result)
                if results.count == 2 { group.cancelAll() }
            }
            return results
        }
        // The two fetch tasks must finish before (or alongside) the watchdog.
        #expect(completed.filter { $0 }.count >= 2)
    }

    /// A delegate callback with no pending waiters (e.g. arriving after the
    /// timeout already resumed everyone) must be a safe no-op, not a crash
    /// or double-resume.
    @Test func testDelegateCallbacksWithoutPendingWaitersAreSafe() {
        let service = LocationService()
        let manager = CLLocationManager()
        service.locationManager(manager, didUpdateLocations: [])
        service.locationManager(manager, didFailWithError: CLError(.locationUnknown))
        // Calling twice in a row exercises the emptied-queue path both times.
        service.locationManager(manager, didUpdateLocations: [CLLocation(latitude: 0, longitude: 0)])
        #expect(true)
    }
}
