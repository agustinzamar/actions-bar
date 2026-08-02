import SwiftUI

@main
struct ActionsBarApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuContentView()
                .environmentObject(appState)
        } label: {
            StatusIcon(status: appState.aggregateStatus)
        }
        .menuBarExtraStyle(.window)

        Window("Sign in with GitHub", id: "sign-in") {
            SignInCodeView()
                .environmentObject(appState)
        }
        .windowResizability(.contentSize)

        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}
