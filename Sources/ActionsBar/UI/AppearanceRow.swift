import AppKit
import SwiftUI

struct AppearanceRow: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "paintbrush.fill")
                .frame(width: 20)

            Text("Appearance")
                .font(.headline)

            Spacer()

            Picker("", selection: $appState.settings.appearance) {
                Text("System").tag(AppearanceMode.system)
                Text("Light").tag(AppearanceMode.light)
                Text("Dark").tag(AppearanceMode.dark)
            }
            .pickerStyle(.segmented)
            .frame(width: 160)
        }
        .padding(.vertical, 8)
        .onAppear {
            applyAppearance(appState.settings.appearance)
        }
        .onChange(of: appState.settings.appearance) { _, newValue in
            applyAppearance(newValue)
        }
    }

    private func applyAppearance(_ mode: AppearanceMode) {
        switch mode {
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        case .system:
            NSApp.appearance = nil
        }
    }
}
