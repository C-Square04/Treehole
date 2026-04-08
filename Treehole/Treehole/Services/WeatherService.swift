import Foundation

// MARK: - WeatherInfo

struct WeatherInfo {
    let tempC: Double
    let code: Int
    let emoji: String
    let description: String
}

// MARK: - WeatherService

enum WeatherService {

    // MARK: - WMO Code Lookup

    private struct WeatherCodeEntry {
        let emoji: String
        let en: String
        let zh: String
    }

    private static let codeTable: [Int: WeatherCodeEntry] = [
        0:  WeatherCodeEntry(emoji: "☀️", en: "Clear",                      zh: "晴"),
        1:  WeatherCodeEntry(emoji: "🌤",  en: "Partly cloudy",             zh: "多云"),
        2:  WeatherCodeEntry(emoji: "🌤",  en: "Partly cloudy",             zh: "多云"),
        3:  WeatherCodeEntry(emoji: "🌤",  en: "Partly cloudy",             zh: "多云"),
        45: WeatherCodeEntry(emoji: "🌫",  en: "Foggy",                     zh: "雾"),
        48: WeatherCodeEntry(emoji: "🌫",  en: "Foggy",                     zh: "雾"),
        51: WeatherCodeEntry(emoji: "🌦",  en: "Drizzle",                   zh: "毛毛雨"),
        53: WeatherCodeEntry(emoji: "🌦",  en: "Drizzle",                   zh: "毛毛雨"),
        55: WeatherCodeEntry(emoji: "🌦",  en: "Drizzle",                   zh: "毛毛雨"),
        56: WeatherCodeEntry(emoji: "🌦",  en: "Drizzle",                   zh: "毛毛雨"),
        57: WeatherCodeEntry(emoji: "🌦",  en: "Drizzle",                   zh: "毛毛雨"),
        61: WeatherCodeEntry(emoji: "🌧",  en: "Rain",                      zh: "雨"),
        63: WeatherCodeEntry(emoji: "🌧",  en: "Rain",                      zh: "雨"),
        65: WeatherCodeEntry(emoji: "🌧",  en: "Rain",                      zh: "雨"),
        66: WeatherCodeEntry(emoji: "🌧",  en: "Rain",                      zh: "雨"),
        67: WeatherCodeEntry(emoji: "🌧",  en: "Rain",                      zh: "雨"),
        71: WeatherCodeEntry(emoji: "🌨",  en: "Snow",                      zh: "雪"),
        73: WeatherCodeEntry(emoji: "🌨",  en: "Snow",                      zh: "雪"),
        75: WeatherCodeEntry(emoji: "🌨",  en: "Snow",                      zh: "雪"),
        77: WeatherCodeEntry(emoji: "🌨",  en: "Snow",                      zh: "雪"),
        80: WeatherCodeEntry(emoji: "🌧",  en: "Showers",                   zh: "阵雨"),
        81: WeatherCodeEntry(emoji: "🌧",  en: "Showers",                   zh: "阵雨"),
        82: WeatherCodeEntry(emoji: "🌧",  en: "Showers",                   zh: "阵雨"),
        85: WeatherCodeEntry(emoji: "🌨",  en: "Snow showers",              zh: "阵雪"),
        86: WeatherCodeEntry(emoji: "🌨",  en: "Snow showers",              zh: "阵雪"),
        95: WeatherCodeEntry(emoji: "⛈",  en: "Thunderstorm",              zh: "雷雨"),
        96: WeatherCodeEntry(emoji: "⛈",  en: "Thunderstorm with hail",    zh: "雷雨冰雹"),
        99: WeatherCodeEntry(emoji: "⛈",  en: "Thunderstorm with hail",    zh: "雷雨冰雹"),
    ]

    private static let defaultEntry = WeatherCodeEntry(emoji: "🌡", en: "Unknown", zh: "未知")

    static func emoji(for code: Int) -> String {
        (codeTable[code] ?? defaultEntry).emoji
    }

    static func description(for code: Int, language: String) -> String {
        let entry = codeTable[code] ?? defaultEntry
        return language == "zh-Hans" ? entry.zh : entry.en
    }

    // MARK: - Fetch

    /// Fetches current weather from Open-Meteo (free, no key).
    /// Returns nil on any error — never throws, never crashes.
    static func fetchWeather(lat: Double, lng: Double, language: String) async -> WeatherInfo? {
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lng)&current=temperature_2m,weather_code"
        guard let url = URL(string: urlString) else {
            print("[WeatherService] Invalid URL")
            return nil
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            return parseResponse(data: data, language: language)
        } catch {
            print("[WeatherService] Fetch error: \(error)")
            return nil
        }
    }

    // MARK: - JSON Parsing

    private static func parseResponse(data: Data, language: String) -> WeatherInfo? {
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let current = json["current"] as? [String: Any],
            let tempC = current["temperature_2m"] as? Double,
            let code = current["weather_code"] as? Int
        else {
            print("[WeatherService] Failed to parse response")
            return nil
        }
        return WeatherInfo(
            tempC: tempC,
            code: code,
            emoji: emoji(for: code),
            description: description(for: code, language: language)
        )
    }
}
