//
//  MoodTagCoordinatesTests.swift
//  TreeholeTests
//

import Testing
import Foundation
@testable import Treehole

@Suite("MoodTag Coordinates Tests")
struct MoodTagCoordinatesTests {

    // All 16 MoodTag cases have valence in [-1, 1]
    @Test func testAllValencesInRange() {
        for mood in MoodTag.allCases {
            #expect(mood.defaultValence >= -1.0, "Valence out of range for \(mood.rawValue)")
            #expect(mood.defaultValence <= 1.0, "Valence out of range for \(mood.rawValue)")
        }
    }

    // All 16 MoodTag cases have arousal in [0, 1]
    @Test func testAllArousalsInRange() {
        for mood in MoodTag.allCases {
            #expect(mood.defaultArousal >= 0.0, "Arousal out of range for \(mood.rawValue)")
            #expect(mood.defaultArousal <= 1.0, "Arousal out of range for \(mood.rawValue)")
        }
    }

    // There are exactly 16 mood cases
    @Test func testExactly16Cases() {
        #expect(MoodTag.allCases.count == 16)
    }

    // Spot-check specific known values from design spec
    @Test func testSpecificKnownValues() {
        #expect(MoodTag.excited.defaultValence == 0.8)
        #expect(MoodTag.excited.defaultArousal == 0.9)
        #expect(MoodTag.happy.defaultValence == 0.7)
        #expect(MoodTag.happy.defaultArousal == 0.7)
        #expect(MoodTag.angry.defaultValence == -0.7)
        #expect(MoodTag.angry.defaultArousal == 0.85)
        #expect(MoodTag.peaceful.defaultValence == 0.5)
        #expect(MoodTag.peaceful.defaultArousal == 0.2)
        #expect(MoodTag.loved.defaultValence == 0.8)
        #expect(MoodTag.stressed.defaultArousal == 0.75)
    }

    // Nearest mood lookup: position exactly on 'excited' returns excited
    @Test func testNearestMoodExact() {
        let nearest = MoodTag.nearest(valence: 0.8, arousal: 0.9)
        #expect(nearest == .excited)
    }

    // Nearest mood lookup: position in top-right corner (high valence, high arousal)
    // should resolve to excited (0.8, 0.9) not happy (0.7, 0.7)
    @Test func testNearestMoodTopRightCorner() {
        let nearest = MoodTag.nearest(valence: 1.0, arousal: 1.0)
        #expect(nearest == .excited)
    }

    // Nearest mood lookup: position clearly in bottom-left returns a negative low-energy mood
    @Test func testNearestMoodBottomLeft() {
        let nearest = MoodTag.nearest(valence: -0.55, arousal: 0.2)
        // melancholic (-0.5, 0.2) or lonely (-0.6, 0.25) should be the nearest
        let isNegativeLowEnergy = (nearest == .melancholic || nearest == .lonely)
        #expect(isNegativeLowEnergy)
        // Just verify it's a negative valence mood
        #expect(nearest.defaultValence < 0)
    }

    // Nearest mood lookup: position near calm
    @Test func testNearestMoodNearCalm() {
        let nearest = MoodTag.nearest(valence: 0.38, arousal: 0.28)
        #expect(nearest == .calm)
    }

    // Nearest mood lookup: position near grateful
    @Test func testNearestMoodNearGrateful() {
        let nearest = MoodTag.nearest(valence: 0.6, arousal: 0.5)
        #expect(nearest == .grateful)
    }

    // New 8 cases all have non-nil emoji (basic sanity)
    @Test func testNewCasesHaveEmoji() {
        let newCases: [MoodTag] = [.grateful, .loved, .excited, .peaceful, .lonely, .melancholic, .stressed, .proud]
        for mood in newCases {
            #expect(!mood.emoji.isEmpty)
            #expect(!mood.labelEN.isEmpty)
            #expect(!mood.labelZH.isEmpty)
        }
    }

    // Original 8 cases are still valid and unchanged
    @Test func testOriginal8CasesStillValid() {
        let originals: [MoodTag] = [.happy, .sad, .angry, .anxious, .tired, .confused, .hopeful, .calm]
        for mood in originals {
            #expect(!mood.emoji.isEmpty)
            let tag = MoodTag(rawValue: mood.rawValue)
            #expect(tag != nil)
        }
    }
}
