import SwiftUI

@main
struct DriveDeckApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var model = DashboardModel.shared
    @StateObject private var settings = AppSettings.shared

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environmentObject(model)
                .environmentObject(settings)
                .preferredColorScheme(.dark)
                .tint(settings.accent.color)
                .onAppear { model.start() }
        }
        .onChange(of: scenePhase) { phase in
            UIApplication.shared.isIdleTimerDisabled = phase == .active && settings.keepScreenOn
            if phase == .background { model.trip.save() }
        }
    }
}
