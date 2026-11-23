import Foundation
import SwiftUI

enum SpeedUnit: String, CaseIterable, Identifiable {
    case kmh, mph
    var id: String { rawValue }
    var label: String { self == .kmh ? "km/h" : "mph" }
    var distanceLabel: String { self == .kmh ? "km" : "mi" }
    /// Umrechnung von m/s
    func fromMetersPerSecond(_ v: Double) -> Double { self == .kmh ? v * 3.6 : v * 2.236936 }
    /// Umrechnung von Metern in km bzw. Meilen
    func distance(fromMeters m: Double) -> Double { self == .kmh ? m / 1000 : m / 1609.344 }
    var gaugeMax: Double { self == .kmh ? 240 : 160 }
}

enum AltitudeUnit: String, CaseIterable, Identifiable {
    case meters, feet
    var id: String { rawValue }
    var label: String { self == .meters ? "m" : "ft" }
    func convert(_ meters: Double) -> Double { self == .meters ? meters : meters * 3.28084 }
}

enum TemperatureUnit: String, CaseIterable, Identifiable {
    case celsius, fahrenheit
    var id: String { rawValue }
    var label: String { self == .celsius ? "°C" : "°F" }
    func convert(_ c: Double) -> Double { self == .celsius ? c : c * 9 / 5 + 32 }
}

enum AccentTheme: String, CaseIterable, Identifiable {
    case cyan, green, orange, red, purple, white
    var id: String { rawValue }
    var name: String {
        switch self {
        case .cyan: return "Cyan"
        case .green: return "Grün"
        case .orange: return "Orange"
        case .red: return "Rot"
        case .purple: return "Violett"
        case .white: return "Weiß"
        }
    }
    var uiColor: UIColor {
        switch self {
        case .cyan: return UIColor(red: 0.0, green: 0.80, blue: 1.0, alpha: 1)
        case .green: return UIColor(red: 0.20, green: 0.92, blue: 0.55, alpha: 1)
        case .orange: return UIColor(red: 1.0, green: 0.62, blue: 0.15, alpha: 1)
        case .red: return UIColor(red: 1.0, green: 0.33, blue: 0.30, alpha: 1)
        case .purple: return UIColor(red: 0.70, green: 0.45, blue: 1.0, alpha: 1)
        case .white: return UIColor(white: 0.92, alpha: 1)
        }
    }
    var color: Color { Color(uiColor) }
}

enum WidgetKind: String, CaseIterable, Identifiable, Codable {
    case speed, compass, altitude, clock, weather, trip, location, battery, coordinates

    var id: String { rawValue }
    var title: String {
        switch self {
        case .speed: return "Tacho"
        case .compass: return "Kompass"
        case .altitude: return "Höhe"
        case .clock: return "Uhr & Datum"
        case .weather: return "Wetter"
        case .trip: return "Fahrt"
        case .location: return "Standort"
        case .battery: return "iPhone-Akku"
        case .coordinates: return "Koordinaten"
        }
    }
    var symbol: String {
        switch self {
        case .speed: return "speedometer"
        case .compass: return "location.north.circle"
        case .altitude: return "mountain.2"
        case .clock: return "clock"
        case .weather: return "cloud.sun"
        case .trip: return "road.lanes"
        case .location: return "mappin.and.ellipse"
        case .battery: return "battery.75"
        case .coordinates: return "scope"
        }
    }
    /// Widgets, die die volle Breite belegen
    var isWide: Bool { self == .speed || self == .trip }
}

/// Persistente Benutzereinstellungen (UserDefaults).
final class AppSettings: ObservableObject {
    static let shared = AppSettings()
    private let d = UserDefaults.standard

    @Published var speedUnit: SpeedUnit { didSet { d.set(speedUnit.rawValue, forKey: "speedUnit") } }
    @Published var altitudeUnit: AltitudeUnit { didSet { d.set(altitudeUnit.rawValue, forKey: "altitudeUnit") } }
    @Published var temperatureUnit: TemperatureUnit { didSet { d.set(temperatureUnit.rawValue, forKey: "temperatureUnit") } }
    @Published var accent: AccentTheme { didSet { d.set(accent.rawValue, forKey: "accent") } }
    @Published var keepScreenOn: Bool { didSet { d.set(keepScreenOn, forKey: "keepScreenOn") } }
    @Published var speedWarningEnabled: Bool { didSet { d.set(speedWarningEnabled, forKey: "speedWarningEnabled") } }
    /// Warnschwelle in der gewählten Einheit
    @Published var speedWarningLimit: Double { didSet { d.set(speedWarningLimit, forKey: "speedWarningLimit") } }
    @Published var widgets: [WidgetKind] {
        didSet { d.set(widgets.map(\.rawValue), forKey: "widgets") }
    }

    static let defaultWidgets: [WidgetKind] = [.speed, .compass, .altitude, .clock, .weather, .trip, .location, .battery]

    private init() {
        speedUnit = SpeedUnit(rawValue: d.string(forKey: "speedUnit") ?? "") ?? (Locale.current.measurementSystem == .us ? .mph : .kmh)
        altitudeUnit = AltitudeUnit(rawValue: d.string(forKey: "altitudeUnit") ?? "") ?? .meters
        temperatureUnit = TemperatureUnit(rawValue: d.string(forKey: "temperatureUnit") ?? "") ?? .celsius
        accent = AccentTheme(rawValue: d.string(forKey: "accent") ?? "") ?? .cyan
        keepScreenOn = d.object(forKey: "keepScreenOn") as? Bool ?? true
        speedWarningEnabled = d.object(forKey: "speedWarningEnabled") as? Bool ?? false
        speedWarningLimit = d.object(forKey: "speedWarningLimit") as? Double ?? 130
        if let raw = d.stringArray(forKey: "widgets") {
            widgets = raw.compactMap(WidgetKind.init(rawValue:))
        } else {
            widgets = AppSettings.defaultWidgets
        }
    }
}
