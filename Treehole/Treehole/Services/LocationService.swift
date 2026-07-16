import Foundation
import CoreLocation
import Observation

@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {

    // MARK: - Private
    private let manager = CLLocationManager()
    // Concurrent fetches can overlap (e.g. double-tap on the location button).
    // All waiters queue here and are resumed together, so no continuation is
    // ever silently overwritten and leaked.
    private var locationContinuations: [CheckedContinuation<CLLocation?, Never>] = []
    private var timeoutTask: Task<Void, Never>?

    /// Maximum time to wait for CoreLocation before resuming callers with nil.
    static let locationTimeout: TimeInterval = 10

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    // MARK: - Public API

    /// Requests current location and reverse-geocodes it.
    /// Returns nil if permission is denied, location times out, or geocoding fails.
    func fetchCurrentLocation() async -> (latitude: Double, longitude: Double, name: String)? {
        var status = manager.authorizationStatus
        if status == .denied || status == .restricted {
            return nil
        }

        if status == .notDetermined {
            // Trigger the system prompt and poll for the result.
            // Polling avoids a leaked continuation when the prompt never fires
            // (e.g. test environment, simulator without UI).
            manager.requestWhenInUseAuthorization()
            for _ in 0..<40 {
                if Task.isCancelled { return nil }
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms × 40 = 4s max
                if manager.authorizationStatus != .notDetermined {
                    break
                }
            }
            status = manager.authorizationStatus
        }

        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            return nil
        }

        // Fetch location with a timeout so callers can never await forever
        // if CoreLocation stalls and no delegate callback arrives.
        let location: CLLocation? = await withCheckedContinuation { continuation in
            locationContinuations.append(continuation)
            // Only the first waiter starts a request; later callers piggyback
            // on the in-flight one and share its result.
            guard locationContinuations.count == 1 else { return }
            manager.requestLocation()
            timeoutTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(Self.locationTimeout * 1_000_000_000))
                guard !Task.isCancelled else { return }
                self?.resumeAllWaiters(with: nil)
            }
        }

        guard let loc = location else { return nil }

        // Reverse geocode
        let name = await reverseGeocode(location: loc)
        guard let placeName = name else { return nil }

        return (latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude, name: placeName)
    }

    // MARK: - Geocoding

    private func reverseGeocode(location: CLLocation) async -> String? {
        await withCheckedContinuation { continuation in
            CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
                guard error == nil, let placemark = placemarks?.first else {
                    continuation.resume(returning: nil)
                    return
                }
                let name = Self.displayName(from: placemark)
                continuation.resume(returning: name)
            }
        }
    }

    private static func displayName(from placemark: CLPlacemark) -> String {
        // Try: subLocality + city, or city + state, or locality, etc.
        if let sub = placemark.subLocality, let city = placemark.locality {
            return "\(sub), \(city)"
        } else if let city = placemark.locality, let state = placemark.administrativeArea {
            return "\(city), \(state)"
        } else if let city = placemark.locality {
            return city
        } else if let state = placemark.administrativeArea {
            return state
        } else if let country = placemark.country {
            return country
        }
        return placemark.name ?? ""
    }

    // MARK: - Continuation Handling

    // Emptying the queue before resuming makes a second call (late delegate
    // callback after the timeout already fired, or vice versa) a safe no-op.
    private func resumeAllWaiters(with location: CLLocation?) {
        timeoutTask?.cancel()
        timeoutTask = nil
        let waiters = locationContinuations
        locationContinuations = []
        for continuation in waiters {
            continuation.resume(returning: location)
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        resumeAllWaiters(with: locations.first)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        resumeAllWaiters(with: nil)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // No-op: fetchCurrentLocation polls authorizationStatus after requesting.
    }
}
