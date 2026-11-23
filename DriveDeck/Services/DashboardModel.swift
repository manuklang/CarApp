import Foundation
import Combine
import UIKit

/// Zentrales Modell, das iPhone-UI und CarPlay gemeinsam nutzen.
final class DashboardModel: ObservableObject {
    static let shared = DashboardModel()

    let settings = AppSettings.shared
    let location = LocationService()
    let trip = TripService()
    let weather = WeatherService()

    @Published private(set) var batteryLevel: Float = UIDevice.current.batteryLevel
    @Published private(set) var batteryState: UIDevice.BatteryState = UIDevice.current.batteryState

    private var bag = Set<AnyCancellable>()
    private var started = false

    private init() {
        // Änderungen der Teilmodelle an SwiftUI weiterreichen
        [location.objectWillChange, trip.objectWillChange, weather.objectWillChange, settings.objectWillChange]
            .forEach { $0.receive(on: RunLoop.main).sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &bag) }

        location.$location
            .compactMap { $0 }
            .sink { [weak self] loc in
                self?.trip.ingest(loc)
                self?.weather.refreshIfNeeded(for: loc)
            }
            .store(in: &bag)
    }

    func start() {
        location.start()
        guard !started else { return }
        started = true
        UIDevice.current.isBatteryMonitoringEnabled = true
        updateBattery()
        NotificationCenter.default.publisher(for: UIDevice.batteryLevelDidChangeNotification)
            .merge(with: NotificationCenter.default.publisher(for: UIDevice.batteryStateDidChangeNotification))
            .sink { [weak self] _ in self?.updateBattery() }
            .store(in: &bag)
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in self?.trip.save() }
            .store(in: &bag)
    }

    private func updateBattery() {
        batteryLevel = UIDevice.current.batteryLevel
        batteryState = UIDevice.current.batteryState
    }

    // MARK: Formatierte Werte (gemeinsam für App und CarPlay)

    var speedValue: Double { settings.speedUnit.fromMetersPerSecond(location.speed) }
    var speedText: String { Fmt.number(speedValue.rounded()) }
    var isOverSpeedLimit: Bool { settings.speedWarningEnabled && speedValue > settings.speedWarningLimit }

    var headingText: String {
        guard let h = location.displayHeading else { return "–" }
        return "\(Fmt.compassPoint(h)) \(Int(h.rounded()) % 360)°"
    }

    var altitudeText: String {
        guard let loc = location.location, loc.verticalAccuracy >= 0 else { return "–" }
        return "\(Fmt.number(settings.altitudeUnit.convert(loc.altitude).rounded())) \(settings.altitudeUnit.label)"
    }

    var altitudeAccuracyText: String? {
        guard let loc = location.location, loc.verticalAccuracy >= 0 else { return nil }
        return "± \(Fmt.number(settings.altitudeUnit.convert(loc.verticalAccuracy).rounded())) \(settings.altitudeUnit.label)"
    }

    func temperatureText(_ c: Double?) -> String {
        guard let c else { return "–" }
        return "\(Fmt.number(settings.temperatureUnit.convert(c).rounded()))°"
    }

    var tripDistanceText: String {
        "\(Fmt.number(settings.speedUnit.distance(fromMeters: trip.distance), digits: 1)) \(settings.speedUnit.distanceLabel)"
    }
    var odometerText: String {
        "\(Fmt.number(settings.speedUnit.distance(fromMeters: trip.odometer).rounded())) \(settings.speedUnit.distanceLabel)"
    }
    var tripAverageText: String {
        "\(Fmt.number(settings.speedUnit.fromMetersPerSecond(trip.averageSpeed).rounded())) \(settings.speedUnit.label)"
    }
    var tripMaxText: String {
        "\(Fmt.number(settings.speedUnit.fromMetersPerSecond(trip.maxSpeed).rounded())) \(settings.speedUnit.label)"
    }
    var tripTimeText: String { Fmt.duration(trip.movingTime) }

    var placeText: String {
        [location.street, location.city].compactMap { $0 }.joined(separator: ", ").nilIfEmpty ?? "Standort wird ermittelt…"
    }

    var batteryText: String {
        batteryLevel < 0 ? "–" : "\(Int((batteryLevel * 100).rounded())) %"
    }
}

extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
