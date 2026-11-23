import UIKit
import CarPlay
import CoreLocation

/// CarPlay-Oberfläche (Kategorie „Driving Task“): drei Tabs mit Live-Werten.
final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    private var interfaceController: CPInterfaceController?
    private var timer: Timer?
    private let model = DashboardModel.shared

    // Cockpit
    private let speedItem = CPListItem(text: "–", detailText: "Geschwindigkeit")
    private let headingItem = CPListItem(text: "–", detailText: "Richtung")
    private let altitudeItem = CPListItem(text: "–", detailText: "Höhe")
    private let clockItem = CPListItem(text: "–", detailText: nil)
    private let placeItem = CPListItem(text: "–", detailText: "Standort")

    // Wetter
    private let weatherItem = CPListItem(text: "Wetter wird geladen…", detailText: nil)
    private let weatherRangeItem = CPListItem(text: "–", detailText: "Heute")
    private let weatherWindItem = CPListItem(text: "–", detailText: "Wind & Luftfeuchte")

    // Fahrt
    private let tripDistanceItem = CPListItem(text: "–", detailText: "Strecke")
    private let tripTimeItem = CPListItem(text: "–", detailText: "Fahrzeit")
    private let tripAvgItem = CPListItem(text: "–", detailText: "Ø Geschwindigkeit")
    private let tripMaxItem = CPListItem(text: "–", detailText: "Höchstgeschwindigkeit")
    private let odometerItem = CPListItem(text: "–", detailText: "Gesamtstrecke")
    private let resetItem = CPListItem(text: "Fahrt zurücksetzen", detailText: nil)

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didConnect interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        model.start()

        let cockpit = CPListTemplate(title: "Cockpit", sections: [
            CPListSection(items: [speedItem, headingItem, altitudeItem, clockItem, placeItem])
        ])
        cockpit.tabTitle = "Cockpit"
        cockpit.tabImage = UIImage(systemName: "speedometer")

        let weather = CPListTemplate(title: "Wetter", sections: [
            CPListSection(items: [weatherItem, weatherRangeItem, weatherWindItem])
        ])
        weather.tabTitle = "Wetter"
        weather.tabImage = UIImage(systemName: "cloud.sun")

        resetItem.setImage(GaugeRenderer.symbol("arrow.counterclockwise.circle.fill", color: .systemRed))
        resetItem.handler = { [weak self] _, completion in
            self?.confirmReset()
            completion()
        }
        tripDistanceItem.setImage(GaugeRenderer.symbol("road.lanes"))
        tripTimeItem.setImage(GaugeRenderer.symbol("timer"))
        tripAvgItem.setImage(GaugeRenderer.symbol("gauge.with.dots.needle.33percent"))
        tripMaxItem.setImage(GaugeRenderer.symbol("gauge.with.dots.needle.100percent"))
        odometerItem.setImage(GaugeRenderer.symbol("car.fill"))
        altitudeItem.setImage(GaugeRenderer.symbol("mountain.2.fill"))
        clockItem.setImage(GaugeRenderer.symbol("clock.fill"))
        placeItem.setImage(GaugeRenderer.symbol("mappin.circle.fill", color: .systemRed))
        weatherRangeItem.setImage(GaugeRenderer.symbol("thermometer.medium"))
        weatherWindItem.setImage(GaugeRenderer.symbol("wind"))

        let trip = CPListTemplate(title: "Fahrt", sections: [
            CPListSection(items: [tripDistanceItem, tripTimeItem, tripAvgItem, tripMaxItem, odometerItem]),
            CPListSection(items: [resetItem]),
        ])
        trip.tabTitle = "Fahrt"
        trip.tabImage = UIImage(systemName: "road.lanes")

        let tabs = CPTabBarTemplate(templates: [cockpit, weather, trip])
        interfaceController.setRootTemplate(tabs, animated: true, completion: nil)

        refresh()
        let t = Timer(timeInterval: 1, repeats: true) { [weak self] _ in self?.refresh() }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didDisconnect interfaceController: CPInterfaceController) {
        timer?.invalidate()
        timer = nil
        self.interfaceController = nil
        model.trip.save()
    }

    private func confirmReset() {
        let alert = CPAlertTemplate(titleVariants: ["Aktuelle Fahrt zurücksetzen?"], actions: [
            CPAlertAction(title: "Zurücksetzen", style: .destructive) { [weak self] _ in
                self?.model.trip.reset()
                self?.refresh()
                self?.interfaceController?.dismissTemplate(animated: true, completion: nil)
            },
            CPAlertAction(title: "Abbrechen", style: .cancel) { [weak self] _ in
                self?.interfaceController?.dismissTemplate(animated: true, completion: nil)
            },
        ])
        interfaceController?.presentTemplate(alert, animated: true, completion: nil)
    }

    private func refresh() {
        let s = model.settings
        let accent = s.accent.uiColor
        let auth = model.location.authorization

        // Cockpit
        if auth == .notDetermined || auth == .denied || auth == .restricted {
            speedItem.setText("Standort am iPhone freigeben")
            speedItem.setDetailText("DriveDeck auf dem iPhone öffnen")
        } else {
            speedItem.setText("\(model.speedText) \(s.speedUnit.label)")
            speedItem.setDetailText(model.isOverSpeedLimit
                ? "⚠︎ Über \(Int(s.speedWarningLimit)) \(s.speedUnit.label)"
                : "Ø \(model.tripAverageText) · Max \(model.tripMaxText)")
        }
        speedItem.setImage(GaugeRenderer.speed(fraction: model.speedValue / s.speedUnit.gaugeMax,
                                               accent: accent, warning: model.isOverSpeedLimit))

        headingItem.setText(model.headingText)
        headingItem.setImage(GaugeRenderer.compass(heading: model.location.displayHeading, accent: accent))

        altitudeItem.setText(model.altitudeText)
        altitudeItem.setDetailText(model.altitudeAccuracyText.map { "Höhe \($0)" } ?? "Höhe")

        let now = Date()
        clockItem.setText(Fmt.time.string(from: now))
        clockItem.setDetailText(Fmt.date.string(from: now))

        placeItem.setText(model.location.street ?? "–")
        placeItem.setDetailText(model.location.city ?? "Standort wird ermittelt…")

        // Wetter
        if let w = model.weather.current {
            weatherItem.setText("\(model.temperatureText(w.temperature)) · \(w.description)")
            weatherItem.setDetailText("Gefühlt \(model.temperatureText(w.apparentTemperature))")
            weatherItem.setImage(GaugeRenderer.symbol(w.symbol))
            weatherRangeItem.setText("↑ \(model.temperatureText(w.todayMax))   ↓ \(model.temperatureText(w.todayMin))")
            weatherWindItem.setText("\(Fmt.number(w.windSpeed.rounded())) km/h · \(Int(w.humidity.rounded())) %")
        } else {
            weatherItem.setText(model.weather.lastError ?? "Wetter wird geladen…")
            weatherItem.setImage(GaugeRenderer.symbol("cloud.sun.fill"))
        }

        // Fahrt
        tripDistanceItem.setText(model.tripDistanceText)
        tripTimeItem.setText(model.tripTimeText)
        tripAvgItem.setText(model.tripAverageText)
        tripMaxItem.setText(model.tripMaxText)
        odometerItem.setText(model.odometerText)
    }
}
