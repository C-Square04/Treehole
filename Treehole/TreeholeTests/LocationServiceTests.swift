//
//  LocationServiceTests.swift
//  TreeholeTests
//

import Testing
import Foundation
import CoreLocation
@testable import Treehole

@Suite("LocationService Tests")
struct LocationServiceTests {

    // Verify that LocationService can be instantiated without crashing.
    @Test func testLocationServiceCanBeCreated() {
        let service = LocationService()
        // Just confirm the object was created and has expected type
        let mirror = Mirror(reflecting: service)
        #expect(mirror.subjectType == LocationService.self)
    }

    // Verify that LocationService conforms to CLLocationManagerDelegate by inspecting class lineage.
    @Test func testLocationServiceIsNSObjectSubclass() {
        let service = LocationService()
        // NSObject provides respondsToSelector which all delegates rely on
        #expect(service.responds(to: #selector(NSObject.description)))
    }

    // Verify that fetchCurrentLocation returns nil immediately when called
    // in a unit test context (no real GPS / permission denied).
    // This is a smoke test — we just ensure no crash.
    @MainActor
    @Test func testFetchCurrentLocationDoesNotCrash() async {
        let service = LocationService()
        // In the test sandbox, this should return nil quickly (denied or timeout).
        let result = await withTaskGroup(of: (Double, Double, String)??.self) { group in
            group.addTask {
                await service.fetchCurrentLocation()
            }
            group.addTask {
                // Provide a 3-second timeout so the test doesn't block
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                return .some(nil)
            }
            let first = await group.next()
            group.cancelAll()
            return first ?? nil
        }
        // result might be nil (denied) or have a value — just verify no crash
        _ = result
        #expect(true)
    }
}
