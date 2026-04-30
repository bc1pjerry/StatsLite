import SwiftUI

@main
struct StatsLiteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(settings: appDelegate.settings, statsState: appDelegate.statsState)
        }
    }
}
