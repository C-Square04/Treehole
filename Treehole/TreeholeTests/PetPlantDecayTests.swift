//
//  PetPlantDecayTests.swift
//  TreeholeTests
//
//  Decay math must be idempotent: repeated calls (e.g. every view appearance)
//  apply no extra decay, and N short intervals sum to one long interval.
//

import Testing
import Foundation
@testable import Treehole

// MARK: - Plant Hydration Decay Tests

@Suite("Plant Hydration Decay Tests")
struct PlantHydrationDecayTests {

    @Test func testNoDecayBeforeFirstWatering() throws {
        let plant = Plant()
        plant.updateHydration(now: Date())
        #expect(plant.hydrationLevel == 100)
        #expect(plant.lastHydrationUpdateAt == nil)
    }

    @Test func testTwoDaysDecayFromWatering() throws {
        let base = Date()
        let plant = Plant()
        plant.lastWateredAt = base
        plant.updateHydration(now: base.addingTimeInterval(2 * 86400))
        // 20 points/day × 2 days = 40
        #expect(plant.hydrationLevel == 60)
    }

    @Test func testFrequentAppearancesApplyNoExtraDecay() throws {
        let base = Date()
        let plant = Plant()
        plant.lastWateredAt = base

        let firstVisit = base.addingTimeInterval(2 * 86400)
        plant.updateHydration(now: firstVisit)
        #expect(plant.hydrationLevel == 60)

        // Tab-switching back seconds/minutes later must not re-apply cumulative decay
        plant.updateHydration(now: firstVisit.addingTimeInterval(1))
        plant.updateHydration(now: firstVisit.addingTimeInterval(60))
        plant.updateHydration(now: firstVisit.addingTimeInterval(120))
        #expect(plant.hydrationLevel == 60)
    }

    @Test func testShortIntervalsSumToLongInterval() throws {
        let base = Date()
        let single = Plant()
        single.lastWateredAt = base
        single.updateHydration(now: base.addingTimeInterval(48 * 3600))

        let repeated = Plant()
        repeated.lastWateredAt = base
        for hour in 1...48 {
            repeated.updateHydration(now: base.addingTimeInterval(Double(hour) * 3600))
        }

        #expect(single.hydrationLevel == repeated.hydrationLevel)
        #expect(single.hydrationLevel == 60)
    }

    @Test func testFractionalRemainderCarries() throws {
        let base = Date()
        let plant = Plant()
        plant.lastWateredAt = base

        // Just under one decay point (interval is 4,320s): nothing applied, nothing lost
        plant.updateHydration(now: base.addingTimeInterval(Plant.hydrationDecayInterval - 300))
        #expect(plant.hydrationLevel == 100)

        // Crossing the interval boundary applies exactly one point
        plant.updateHydration(now: base.addingTimeInterval(Plant.hydrationDecayInterval + 100))
        #expect(plant.hydrationLevel == 99)
    }

    @Test func testDecayClampsAtZero() throws {
        let base = Date()
        let plant = Plant()
        plant.lastWateredAt = base
        plant.updateHydration(now: base.addingTimeInterval(10 * 86400))
        #expect(plant.hydrationLevel == 0)
    }
}

// MARK: - Pet Hunger Decay Tests

@Suite("Pet Hunger Decay Tests")
struct PetHungerDecayTests {

    @Test func testFrequentChecksStillDecay() throws {
        let base = Date()
        let pet = Pet()
        pet.hungerLevel = 80
        pet.lastFedAt = base

        // Checking every 30 minutes for 4 hours must still apply 4 points
        // (regression: sub-hour truncation used to reset the checkpoint and starve decay)
        for halfHour in 1...8 {
            pet.updateHunger(now: base.addingTimeInterval(Double(halfHour) * 1800))
        }
        #expect(pet.hungerLevel == 76)
    }

    @Test func testSubHourCheckDoesNotResetCheckpoint() throws {
        let base = Date()
        let pet = Pet()
        pet.hungerLevel = 80
        pet.lastFedAt = base

        pet.updateHunger(now: base.addingTimeInterval(1800))
        #expect(pet.hungerLevel == 80)

        // The 30 minutes above must count toward the full hour
        pet.updateHunger(now: base.addingTimeInterval(3600))
        #expect(pet.hungerLevel == 79)
    }

    @Test func testShortIntervalsSumToLongInterval() throws {
        let base = Date()
        let single = Pet()
        single.hungerLevel = 80
        single.lastFedAt = base
        single.updateHunger(now: base.addingTimeInterval(10 * 3600))

        let repeated = Pet()
        repeated.hungerLevel = 80
        repeated.lastFedAt = base
        for hour in 1...10 {
            repeated.updateHunger(now: base.addingTimeInterval(Double(hour) * 3600))
        }

        #expect(single.hungerLevel == repeated.hungerLevel)
        #expect(single.hungerLevel == 70)
    }

    @Test func testRepeatedCallsSameInstantApplyNoExtraDecay() throws {
        let base = Date()
        let pet = Pet()
        pet.hungerLevel = 80
        pet.lastFedAt = base

        let visit = base.addingTimeInterval(5 * 3600)
        pet.updateHunger(now: visit)
        #expect(pet.hungerLevel == 75)
        pet.updateHunger(now: visit)
        pet.updateHunger(now: visit.addingTimeInterval(60))
        #expect(pet.hungerLevel == 75)
    }

    @Test func testHungerClampsAtZeroAndMoodTurnsSad() throws {
        let base = Date()
        let pet = Pet()
        pet.hungerLevel = 5
        pet.lastFedAt = base
        pet.updateHunger(now: base.addingTimeInterval(10 * 3600))
        #expect(pet.hungerLevel == 0)
        #expect(pet.mood == .sad)
    }
}
