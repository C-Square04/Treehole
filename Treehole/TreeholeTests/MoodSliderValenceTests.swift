//
//  MoodSliderValenceTests.swift
//  TreeholeTests
//

import Testing
import Foundation
@testable import Treehole

// MARK: - nearestByValence (1D pleasantness slider) Tests
// Several moods share a valence, so the 0.001-epsilon tie-break toward lower
// arousal decides which mood the slider shows at those positions.

@Suite("MoodTag nearestByValence Tests")
struct MoodSliderValenceTests {

    // Exact hits on moods whose valence is unique in the table
    @Test func testUniqueValenceExactHits() {
        #expect(MoodTag.nearestByValence(0.6) == .grateful)
        #expect(MoodTag.nearestByValence(0.4) == .calm)
        #expect(MoodTag.nearestByValence(-0.2) == .tired)
        #expect(MoodTag.nearestByValence(-0.3) == .confused)
        #expect(MoodTag.nearestByValence(-0.6) == .lonely)
    }

    // Shared-valence positions tie-break toward the lower-arousal mood
    @Test func testTieBreakTowardLowerArousal() {
        #expect(MoodTag.nearestByValence(0.8) == .loved)        // loved (0.5) over excited (0.9)
        #expect(MoodTag.nearestByValence(0.7) == .proud)        // proud (0.6) over happy (0.7)
        #expect(MoodTag.nearestByValence(0.5) == .peaceful)     // peaceful (0.2) over hopeful (0.5)
        #expect(MoodTag.nearestByValence(-0.5) == .melancholic) // melancholic (0.2) over stressed/anxious
        #expect(MoodTag.nearestByValence(-0.7) == .sad)         // sad (0.3) over angry (0.85)
    }

    // Every shared-valence group resolves to its lowest-arousal member,
    // regardless of how the valence table evolves
    @Test func testTieBreakHoldsForEverySharedValenceGroup() {
        let groups = Dictionary(grouping: MoodTag.allCases, by: { $0.defaultValence })
        var sharedGroups = 0
        for (valence, moods) in groups where moods.count > 1 {
            sharedGroups += 1
            let lowestArousal = moods.min { $0.defaultArousal < $1.defaultArousal }!
            #expect(
                MoodTag.nearestByValence(valence) == lowestArousal,
                "Tie at valence \(valence) should pick \(lowestArousal.rawValue)"
            )
        }
        // Sanity: current table shares valences at 0.8, 0.7, 0.5, -0.5, -0.7
        #expect(sharedGroups == 5)
    }

    // Slider endpoints (and out-of-range input) resolve to the extreme moods
    @Test func testEndpoints() {
        #expect(MoodTag.nearestByValence(1.0) == .loved)
        #expect(MoodTag.nearestByValence(-1.0) == .sad)
        #expect(MoodTag.nearestByValence(2.0) == .loved)
        #expect(MoodTag.nearestByValence(-2.0) == .sad)
    }

    // Positions between neighboring valences snap to the closer one
    @Test func testBoundaryBetweenNeighbors() {
        #expect(MoodTag.nearestByValence(0.56) == .grateful)     // 0.6 closer than 0.5
        #expect(MoodTag.nearestByValence(0.54) == .peaceful)     // 0.5 closer than 0.6
        #expect(MoodTag.nearestByValence(-0.45) == .melancholic) // -0.5 closer than -0.3
        #expect(MoodTag.nearestByValence(-0.24) == .tired)       // -0.2 closer than -0.3
        #expect(MoodTag.nearestByValence(0.0) == .tired)         // -0.2 closer than 0.4
    }

    // Property: the chosen mood is always at minimal valence distance
    // (within the tie-break epsilon) over all 16 cases
    @Test func testResultMinimizesValenceDistance() {
        for v in stride(from: -1.0, through: 1.0, by: 0.07) {
            let result = MoodTag.nearestByValence(v)
            let best = MoodTag.allCases.map { abs($0.defaultValence - v) }.min()!
            #expect(
                abs(result.defaultValence - v) <= best + 0.001,
                "nearestByValence(\(v)) picked \(result.rawValue) at non-minimal distance"
            )
        }
    }
}
