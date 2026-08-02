import SwiftUI

@main
struct ActionsBarApp: App {
    @StateObject private var appState = AppState()
    @AppStorage("showMenuBarIcon") private var showMenuBarIcon = true

    var body: some Scene {
        MenuBarExtra(isInserted: $showMenuBarIcon) {
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
