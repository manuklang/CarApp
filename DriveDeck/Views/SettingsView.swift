import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var model: DashboardModel
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        WidgetEditorView().environmentObject(settings)
                    } label: {
                        LabeledContent {
                            Text("\(settings.widgets.count) aktiv")
                        } label: {
                            Label("Widgets anordnen", systemImage: "square.grid.2x2")
                        }
                    }
                }

                Section("Darstellung") {
                    Picker("Akzentfarbe", selection: $settings.accent) {
                        ForEach(AccentTheme.allCases) { t in
                            Label(t.name, systemImage: "circle.fill").tint(t.color).tag(t)
                        }
                    }
                    Toggle("Bildschirm anlassen", isOn: $settings.keepScreenOn)
                        .onChange(of: settings.keepScreenOn) { on in
                            UIApplication.shared.isIdleTimerDisabled = on
                        }
                }

                Section("Einheiten") {
                    Picker("Geschwindigkeit", selection: $settings.speedUnit) {
                        ForEach(SpeedUnit.allCases) { Text($0.label).tag($0) }
                    }
                    Picker("Höhe", selection: $settings.altitudeUnit) {
                        ForEach(AltitudeUnit.allCases) { Text($0.label).tag($0) }
                    }
                    Picker("Temperatur", selection: $settings.temperatureUnit) {
                        ForEach(TemperatureUnit.allCases) { Text($0.label).tag($0) }
                    }
                }

                Section {
                    Toggle("Tempo-Warnung", isOn: $settings.speedWarningEnabled)
                    if settings.speedWarningEnabled {
                        Stepper(value: $settings.speedWarningLimit, in: 10...300, step: 5) {
                            Text("Ab \(Int(settings.speedWarningLimit)) \(settings.speedUnit.label)")
                        }
                    }
                } footer: {
                    Text("Der Tacho wird rot, sobald du schneller fährst.")
                }

                Section("Fahrt") {
                    LabeledContent("Strecke", value: model.tripDistanceText)
                    LabeledContent("Fahrzeit", value: model.tripTimeText)
                    LabeledContent("Gesamt", value: model.odometerText)
                    Button("Fahrt zurücksetzen", role: .destructive) { confirmReset = true }
                }

                Section {
                    Text("Geschwindigkeit, Richtung und Höhe stammen vom GPS des iPhones und können von der Tachoanzeige des Autos abweichen. Wetterdaten: Open-Meteo.com.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Fertig") { dismiss() } }
            }
            .confirmationDialog("Fahrt zurücksetzen?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Zurücksetzen", role: .destructive) { model.trip.reset() }
            }
        }
    }
}

struct WidgetEditorView: View {
    @EnvironmentObject var settings: AppSettings

    private var hiddenWidgets: [WidgetKind] {
        WidgetKind.allCases.filter { !settings.widgets.contains($0) }
    }

    var body: some View {
        List {
            Section {
                ForEach(settings.widgets) { kind in
                    Label(kind.title, systemImage: kind.symbol)
                }
                .onMove { settings.widgets.move(fromOffsets: $0, toOffset: $1) }
                .onDelete { settings.widgets.remove(atOffsets: $0) }

                ForEach(hiddenWidgets) { kind in
                    Button {
                        settings.widgets.append(kind)
                    } label: {
                        Label("\(kind.title) hinzufügen", systemImage: "plus.circle.fill")
                    }
                }
            } header: {
                Text("Widgets")
            } footer: {
                Text("Am Griff ziehen zum Sortieren, auf das rote Minus tippen zum Ausblenden.")
            }

            Section {
                Button("Standard wiederherstellen") { settings.widgets = AppSettings.defaultWidgets }
            }
        }
        .environment(\.editMode, .constant(.active))
        .navigationTitle("Widgets")
        .navigationBarTitleDisplayMode(.inline)
    }
}
