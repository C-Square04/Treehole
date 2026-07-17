//
//  WeatherServiceTests.swift
//  TreeholeTests
//

import Testing
import Foundation
@testable import Treehole

@Suite("WeatherService Tests")
struct WeatherServiceTests {

    // MARK: - WMO Code → Emoji

    @Test func testClearEmoji() {
        let emoji = WeatherService.emoji(for: 0)
        #expect(emoji == "☀️")
    }

    @Test func testThunderstormEmoji() {
        let emoji = WeatherService.emoji(for: 95)
        #expect(emoji == "⛈")
    }

    @Test func testThunderstormWithHailEmoji() {
        let emoji = WeatherService.emoji(for: 96)
        #expect(emoji == "⛈")
        let emoji99 = WeatherService.emoji(for: 99)
        #expect(emoji99 == "⛈")
    }

    @Test func testPartlyCloudyEmoji() {
        for code in [1, 2, 3] {
            let emoji = WeatherService.emoji(for: code)
            #expect(emoji == "🌤")
        }
    }

    @Test func testFoggyEmoji() {
        #expect(WeatherService.emoji(for: 45) == "🌫")
        #expect(WeatherService.emoji(for: 48) == "🌫")
    }

    @Test func testSnowEmoji() {
        for code in [71, 73, 75, 77] {
            #expect(WeatherService.emoji(for: code) == "🌨")
        }
    }

    @Test func testDefaultEmojiForUnknownCode() {
        let emoji = WeatherService.emoji(for: 9999)
        #expect(emoji == "🌡")
    }

    // MARK: - English vs Chinese Description

    @Test func testEnglishDescriptionClear() {
        let desc = WeatherService.description(for: 0, language: "en")
        #expect(desc == "Clear")
    }

    @Test func testChineseDescriptionClear() {
        let desc = WeatherService.description(for: 0, language: "zh-Hans")
        #expect(desc == "晴")
    }

    @Test func testEnglishDescriptionThunderstorm() {
        let desc = WeatherService.description(for: 95, language: "en")
        #expect(desc == "Thunderstorm")
    }

    @Test func testChineseDescriptionThunderstorm() {
        let desc = WeatherService.description(for: 95, language: "zh-Hans")
        #expect(desc == "雷雨")
    }

    @Test func testEnglishDescriptionRain() {
        let desc = WeatherService.description(for: 61, language: "en")
        #expect(desc == "Rain")
    }

    @Test func testChineseDescriptionRain() {
        let desc = WeatherService.description(for: 61, language: "zh-Hans")
        #expect(desc == "雨")
    }

    // MARK: - Default Fallback for Unknown Code

    @Test func testDefaultFallbackDescriptionEnglish() {
        let desc = WeatherService.description(for: 9999, language: "en")
        #expect(desc == "Unknown")
    }

    @Test func testDefaultFallbackDescriptionChinese() {
        let desc = WeatherService.description(for: 9999, language: "zh-Hans")
        #expect(desc == "未知")
    }

    @Test func testNonChineseLanguageDefaultsToEnglish() {
        let desc = WeatherService.description(for: 0, language: "fr")
        #expect(desc == "Clear")
    }

    // MARK: - Request URL (privacy rounding)

    @Test func testRequestURLRoundsCoordinatesToTwoDecimals() {
        let url = WeatherService.requestURL(lat: 49.282730, lng: -123.120735)
        let s = try! #require(url?.absoluteString)
        // ~1.1 km precision — weather doesn't need the user's exact GPS
        #expect(s.contains("latitude=49.28"))
        #expect(s.contains("longitude=-123.12"))
        #expect(!s.contains("49.282730"))
    }

    @Test func testRequestURLHandlesShortRoundedValues() {
        let url = WeatherService.requestURL(lat: 49.2, lng: -123.1)
        let s = try! #require(url?.absoluteString)
        #expect(s.contains("latitude=49.2"))
        #expect(s.contains("longitude=-123.1"))
        #expect(s.contains("current=temperature_2m,weather_code"))
    }
}
