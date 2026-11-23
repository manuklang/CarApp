import SwiftUI
import CoreLocation

struct DashboardView: View {
    @EnvironmentObject var model: DashboardModel
    @EnvironmentObject var settings: AppSettings
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let landscape = geo.size.width > geo.size.height
                ScrollView {
                    VStack(spacing: 12) {
                        if model.location.authorization == .denied || model.location.authorization == .restricted {
                            PermissionBanner()
                        }
                        LazyVGrid(columns: columns(landscape: landscape), spacing: 12) {
                            ForEach(settings.widgets) { kind in
                                WidgetCard(kind: kind, landscape: landscape)
                                    .gridCellColumns(kind.isWide && !landscape ? 2 : 1)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 24)
                }
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("DriveDeck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: { Image(systemName: "slider.horizontal.3") }
                        .accessibilityLabel("Einstellungen")
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(model)
                    .environmentObject(settings)
                    .preferredColorScheme(.dark)
                    .tint(settings.accent.color)
            }
        }
    }

    private func columns(landscape: Bool) -> [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: landscape ? 3 : 2)
    }
}

private struct PermissionBanner: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "location.slash.fill").foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 6) {
                Text("Standortzugriff fehlt").font(.headline)
                Text("Ohne Standort kann DriveDeck weder Geschwindigkeit noch Richtung anzeigen.")
                    .font(.subheadline).foregroundStyle(.secondary)
                Button("Einstellungen öffnen") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                }
                .font(.subheadline.weight(.semibold))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.orange.opacity(0.15)))
    }
}

struct WidgetCard: View {
    let kind: WidgetKind
    let landscape: Bool
    @EnvironmentObject var model: DashboardModel
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(kind.title, systemImage: kind.symbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .labelStyle(.titleAndIcon)
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(14)
        .frame(minHeight: minHeight)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(white: 0.09))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(borderColor, lineWidth: 1))
        )
    }

    private var borderColor: Color {
        kind == .speed && model.isOverSpeedLimit ? .red : Color.white.opacity(0.06)
    }

    private var minHeight: CGFloat {
        switch kind {
        case .speed: return landscape ? 240 : 320
        case .compass: return 190
        case .trip: return 150
        default: return 140
        }
    }

    @ViewBuilder private var content: some View {
        let accent = settings.accent.color
        switch kind {
        case .speed:
            SpeedGauge(value: model.speedValue,
                       maxValue: settings.speedUnit.gaugeMax,
                       unit: settings.speedUnit.label,
                       accent: accent,
                       warning: model.isOverSpeedLimit)
                .padding(.horizontal, 8)

        case .compass:
            VStack(spacing: 6) {
                CompassDial(heading: model.location.displayHeading, accent: accent)
                    .frame(maxHeight: 110)
                Text(model.headingText).font(.title3.weight(.bold)).monospacedDigit()
            }

        case .altitude:
            BigValue(value: model.altitudeText, caption: model.altitudeAccuracyText ?? "GPS-Höhe")

        case .clock:
            TimelineView(.periodic(from: .now, by: 1)) { ctx in
                BigValue(value: Fmt.time.string(from: ctx.date), caption: Fmt.date.string(from: ctx.date))
            }

        case .weather:
            if let w = model.weather.current {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Image(systemName: w.symbol).symbolRenderingMode(.multicolor).font(.title)
                        Text(model.temperatureText(w.temperature))
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                    }
                    Text(w.description).font(.subheadline.weight(.medium))
                    Text("↑\(model.temperatureText(w.todayMax))  ↓\(model.temperatureText(w.todayMin))  · \(Fmt.number(w.windSpeed.rounded())) km/h")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                BigValue(value: "–", caption: model.weather.lastError ?? "Wird geladen…")
            }

        case .trip:
            VStack(spacing: 10) {
                HStack {
                    TripStat(title: "Strecke", value: model.tripDistanceText)
                    TripStat(title: "Fahrzeit", value: model.tripTimeText)
                }
                HStack {
                    TripStat(title: "Ø", value: model.tripAverageText)
                    TripStat(title: "Max", value: model.tripMaxText)
                }
            }

        case .location:
            VStack(alignment: .leading, spacing: 4) {
                Text(model.location.street ?? "–")
                    .font(.headline).lineLimit(2).minimumScaleFactor(0.7)
                Text(model.location.city ?? "Standort wird ermittelt…")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

        case .battery:
            BigValue(value: model.batteryText,
                     caption: model.batteryState == .charging || model.batteryState == .full ? "Lädt" : "Akku")

        case .coordinates:
            if let c = model.location.location?.coordinate {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Fmt.coordinate(c.latitude, positive: "N", negative: "S"))
                    Text(Fmt.coordinate(c.longitude, positive: "O", negative: "W"))
                }
                .font(.system(.subheadline, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                BigValue(value: "–", caption: "Kein GPS")
            }
        }
    }
}

private struct BigValue: View {
    let value: String
    let caption: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(caption).font(.caption).foregroundStyle(.secondary).lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TripStat: View {
    let title: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title3.weight(.bold)).monospacedDigit().lineLimit(1).minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
