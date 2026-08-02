import SwiftUI

func relativeSyncLabel(from: Date?, to: Date) -> String {
    guard let from else { return "Never synced" }
    let seconds = Int(to.timeIntervalSince(from))
    if seconds < 60 { return "Last synced just now" }
    if seconds < 3600 {
        let minutes = seconds / 60
        return "Last synced \(minutes) minute\(minutes == 1 ? "" : "s") ago"
    }
    let hours = seconds / 3600
    return "Last synced \(hours) hour\(hours == 1 ? "" : "s") ago"
}

struct SyncStatusRow: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Sync status")
                    .font(.headline)
                Text(relativeSyncLabel(from: appState.poller.lastFetched, to: Date()))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: { appState.refreshNow() }) {
                Label("Sync now", systemImage: "arrow.clockwise")
            }
        }
        .padding(.vertical, 8)
    }
}
