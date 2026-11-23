import Foundation
import CoreLocation

struct WeatherSnapshot: Equatable {
    var temperature: Double        // °C
    var apparentTemperature: Double
    var humidity: Double           // %
    var windSpeed: Double          // km/h
    var code: Int
    var isDay: Bool
    var todayMax: Double?
    var todayMin: Double?
    var updated: Date

    var description: String { WeatherCode.description(code) }
    var symbol: String { WeatherCode.symbol(code, isDay: isDay) }
}

/// Wetterdaten von Open-Meteo (kostenlos, kein API-Schlüssel nötig).
final class WeatherService: ObservableObject {
    @Published private(set) var current: WeatherSnapshot?
    @Published private(set) var lastError: String?

    private var lastFetch: (date: Date, location: CLLocation)?
    private var task: Task<Void, Never>?

    func refreshIfNeeded(for loc: CLLocation) {
        if let last = lastFetch,
           Date().timeIntervalSince(last.date) < 600,
           loc.distance(from: last.location) < 5000 {
            return
        }
        guard task == nil else { return }
        lastFetch = (Date(), loc)
        task = Task { [weak self] in
            await self?.fetch(loc.coordinate)
            await MainActor.run { self?.task = nil }
        }
    }

    private func fetch(_ c: CLLocationCoordinate2D) async {
        var comps = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        comps.queryItems = [
            URLQueryItem(name: "latitude", value: String(format: "%.4f", c.latitude)),
            URLQueryItem(name: "longitude", value: String(format: "%.4f", c.longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m,is_day"),
            URLQueryItem(name: "daily", value: "temperature_2m_max,temperature_2m_min"),
            URLQueryItem(name: "forecast_days", value: "1"),
            URLQueryItem(name: "timezone", value: "auto"),
        ]
        do {
            let (data, _) = try await URLSession.shared.data(from: comps.url!)
            let r = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
            let snap = WeatherSnapshot(
                temperature: r.current.temperature_2m,
                apparentTemperature: r.current.apparent_temperature,
                humidity: r.current.relative_humidity_2m,
                windSpeed: r.current.wind_speed_10m,
                code: r.current.weather_code,
                isDay: r.current.is_day == 1,
                todayMax: r.daily?.temperature_2m_max.first ?? nil,
                todayMin: r.daily?.temperature_2m_min.first ?? nil,
                updated: Date()
            )
            await MainActor.run {
                self.current = snap
                self.lastError = nil
            }
        } catch {
            await MainActor.run {
                self.lastError = "Wetter nicht verfügbar"
                self.lastFetch = nil
            }
        }
    }
}

private struct OpenMeteoResponse: Decodable {
    struct Current: Decodable {
        let temperature_2m: Double
        let apparent_temperature: Double
        let relative_humidity_2m: Double
        let weather_code: Int
        let wind_speed_10m: Double
        let is_day: Int
    }
    struct Daily: Decodable {
        let temperature_2m_max: [Double?]
        let temperature_2m_min: [Double?]
    }
    let current: Current
    let daily: Daily?
}

enum WeatherCode {
    static func description(_ code: Int) -> String {
        switch code {
        case 0: return "Klar"
        case 1: return "Überwiegend klar"
        case 2: return "Teilweise bewölkt"
        case 3: return "Bewölkt"
        case 45, 48: return "Nebel"
        case 51, 53, 55: return "Nieselregen"
        case 56, 57: return "Gefrierender Niesel"
        case 61, 63: return "Regen"
        case 65: return "Starker Regen"
        case 66, 67: return "Gefrierender Regen"
        case 71, 73, 75, 77: return "Schnee"
        case 80, 81, 82: return "Regenschauer"
        case 85, 86: return "Schneeschauer"
        case 95: return "Gewitter"
        case 96, 99: return "Gewitter mit Hagel"
        default: return "–"
        }
    }

    static func symbol(_ code: Int, isDay: Bool) -> String {
        switch code {
        case 0: return isDay ? "sun.max.fill" : "moon.stars.fill"
        case 1, 2: return isDay ? "cloud.sun.fill" : "cloud.moon.fill"
        case 3: return "cloud.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51, 53, 55, 56, 57: return "cloud.drizzle.fill"
        case 61, 63, 66, 67, 80, 81: return "cloud.rain.fill"
        case 65, 82: return "cloud.heavyrain.fill"
        case 71, 73, 75, 77, 85, 86: return "cloud.snow.fill"
        case 95, 96, 99: return "cloud.bolt.rain.fill"
        default: return "cloud.fill"
        }
    }
}
