import Foundation
import CoreLocation

/// Zeichnet Strecke, Fahrzeit, Höchst- und Durchschnittsgeschwindigkeit auf.
final class TripService: ObservableObject {
    @Published private(set) var distance: Double = 0          // Meter
    @Published private(set) var movingTime: TimeInterval = 0  // Sekunden
    @Published private(set) var maxSpeed: Double = 0          // m/s
    @Published private(set) var startDate: Date = Date()
    @Published private(set) var odometer: Double = 0          // Meter, gesamt

    private var lastLocation: CLLocation?
    private let d = UserDefaults.standard
    private var lastSave = Date.distantPast

    init() {
        distance = d.double(forKey: "trip.distance")
        movingTime = d.double(forKey: "trip.movingTime")
        maxSpeed = d.double(forKey: "trip.maxSpeed")
        odometer = d.double(forKey: "trip.odometer")
        if let s = d.object(forKey: "trip.start") as? Date { startDate = s } else { d.set(startDate, forKey: "trip.start") }
    }

    /// Durchschnitt über die Fahrzeit in m/s
    var averageSpeed: Double { movingTime > 5 ? distance / movingTime : 0 }

    func ingest(_ loc: CLLocation) {
        guard loc.horizontalAccuracy >= 0, loc.horizontalAccuracy < 40 else { return }
        defer { lastLocation = loc }
        guard let last = lastLocation else { return }

        let dt = loc.timestamp.timeIntervalSince(last.timestamp)
        guard dt > 0, dt < 30 else { return }
        let delta = loc.distance(from: last)
        let speed = loc.speed >= 0 ? loc.speed : delta / dt

        // Nur echte Bewegung zählen (> ~3 km/h), unrealistische Sprünge verwerfen
        guard speed > 0.8, delta / dt < 90 else { return }
        distance += delta
        odometer += delta
        movingTime += dt
        if speed > maxSpeed, loc.speedAccuracy >= 0, loc.speedAccuracy < 3 { maxSpeed = speed }

        if Date().timeIntervalSince(lastSave) > 10 { save() }
    }

    func reset() {
        distance = 0
        movingTime = 0
        maxSpeed = 0
        startDate = Date()
        lastLocation = nil
        save()
    }

    func save() {
        lastSave = Date()
        d.set(distance, forKey: "trip.distance")
        d.set(movingTime, forKey: "trip.movingTime")
        d.set(maxSpeed, forKey: "trip.maxSpeed")
        d.set(odometer, forKey: "trip.odometer")
        d.set(startDate, forKey: "trip.start")
    }
}
