import SwiftUI

struct LaunchAtLoginRow: View {
    @StateObject private var manager = LaunchAtLoginManager()

    var body: some View {
        HStack(spacing: 12) {
            Text("Launch at login")
                .font(.headline)

            Spacer()

            Toggle("", isOn: $manager.isEnabled)
                .toggleStyle(.switch)
                .controlSize(.small)
        }
        .padding(.vertical, 8)
    }
}
