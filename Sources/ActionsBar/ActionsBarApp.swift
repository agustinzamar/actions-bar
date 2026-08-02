import SwiftUI

@main
struct ActionsBarApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra(isInserted: Binding(
            get: { appState.settings.showMenuBarIcon },
            set: { appState.settings.showMenuBarIcon = $0 }
        )) {
            MenuContentView()
                .environmentObject(appState)
        } label: {
            StatusIcon(status: appState.aggregateStatus)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}
