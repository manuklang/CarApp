import Foundation
import CoreLocation
import Combine

/// Liefert GPS-Position, Geschwindigkeit, Kurs, Kompass und Ortsnamen.
final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var location: CLLocation?
    /// Geglättete Geschwindigkeit in m/s
    @Published private(set) var speed: Double = 0
    /// Fahrtrichtung (GPS-Kurs) in Grad, nur bei Bewegung gültig
    @Published private(set) var course: Double?
    /// Kompass-Richtung in Grad
    @Published private(set) var heading: Double?
    @Published private(set) var authorization: CLAuthorizationStatus
    @Published private(set) var street: String?
    @Published private(set) var city: String?

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var lastGeocode: (date: Date, location: CLLocation)?
    private var isRunning = false

    override init() {
        authorization = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.activityType = .automotiveNavigation
        manager.distanceFilter = kCLDistanceFilterNone
        manager.headingFilter = 2
        manager.pausesLocationUpdatesAutomatically = false
    }

    /// Fahrtrichtung für die Anzeige: bei Fahrt GPS-Kurs, im Stand Kompass.
    var displayHeading: Double? {
        if speed > 2.5, let course { return course }
        return heading ?? course
    }

    func start() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            begin()
        default:
            break
        }
    }

    private func begin() {
        guard !isRunning else { return }
        isRunning = true
        if Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes").flatMap({ $0 as? [String] })?.contains("location") == true {
            manager.allowsBackgroundLocationUpdates = true
            manager.showsBackgroundLocationIndicator = true
        }
        manager.startUpdatingLocation()
        if CLLocationManager.headingAvailable() {
            manager.startUpdatingHeading()
        }
    }

    // MARK: CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorization = manager.authorizationStatus
        if authorization == .authorizedWhenInUse || authorization == .authorizedAlways {
            begin()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last, loc.horizontalAccuracy >= 0 else { return }
        location = loc

        let raw = loc.speed >= 0 ? loc.speed : 0
        // Leichte Glättung gegen GPS-Zittern; im Stand schnell auf 0
        speed = raw < 0.5 ? 0 : speed * 0.3 + raw * 0.7
        if loc.course >= 0, raw > 1.5 { course = loc.course }

        reverseGeocodeIfNeeded(loc)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard newHeading.headingAccuracy >= 0 else { return }
        heading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Fehler (z. B. kurzzeitig kein Signal) ignorieren, Updates laufen weiter.
    }

    private func reverseGeocodeIfNeeded(_ loc: CLLocation) {
        if let last = lastGeocode,
           Date().timeIntervalSince(last.date) < 20 || loc.distance(from: last.location) < 150 {
            return
        }
        guard !geocoder.isGeocoding else { return }
        lastGeocode = (Date(), loc)
        geocoder.reverseGeocodeLocation(loc) { [weak self] placemarks, _ in
            guard let self, let p = placemarks?.first else { return }
            DispatchQueue.main.async {
                self.street = p.thoroughfare ?? p.name
                self.city = p.locality ?? p.subAdministrativeArea
            }
        }
    }
}
