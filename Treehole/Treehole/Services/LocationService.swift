import Foundation
import CoreLocation
import Observation

@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {

    // MARK: - Private
    private let manager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?
    private var authContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?

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
            // Wait for the system prompt to actually return via the delegate, not a fragile sleep.
            status = await withCheckedContinuation { continuation in
                self.authContinuation = continuation
                self.manager.requestWhenInUseAuthorization()
            }
        }

        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            return nil
        }

        // Fetch location with 10-second timeout
        let location: CLLocation? = await withCheckedContinuation { [weak self] continuation in
            guard let self else {
                continuation.resume(returning: nil)
                return
            }
            self.locationContinuation = continuation
            self.manager.requestLocation()
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

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationContinuation?.resume(returning: locations.first)
        locationContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationContinuation?.resume(returning: nil)
        locationContinuation = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // The system fires this once after the user responds to the permission prompt
        // (and also at observer attach time with .notDetermined — ignore that case).
        let status = manager.authorizationStatus
        guard status != .notDetermined else { return }
        authContinuation?.resume(returning: status)
        authContinuation = nil
    }
}
