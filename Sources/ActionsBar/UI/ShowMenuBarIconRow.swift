import SwiftUI

struct ShowMenuBarIconRow: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Show icon in menu bar")
                    .font(.headline)
                Text("Keep run status one click away.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: $appState.settings.showMenuBarIcon)
                .toggleStyle(.switch)
                .controlSize(.small)
        }
        .padding(.vertical, 8)
    }
}
