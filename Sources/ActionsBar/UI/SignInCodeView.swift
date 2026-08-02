import SwiftUI
import AppKit

/// Shown in its own real window (not the menu bar popover) because the popover
/// auto-dismisses the instant focus shifts to the browser during device flow.
struct SignInCodeView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            if let info = appState.auth.codeInfo, appState.auth.state != .success {
                VStack(spacing: 8) {
                    Text("Enter this code on GitHub")
                        .foregroundStyle(.secondary)
                    Text(info.userCode)
                        .font(.system(.largeTitle, design: .monospaced))
                        .bold()
                        .textSelection(.enabled)
                    Text("Copied to your clipboard")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Open github.com/login/device") {
                        NSWorkspace.shared.open(info.verificationURL)
                    }
                }
            }

            switch appState.auth.state {
            case .idle:
                if appState.auth.codeInfo == nil {
                    ProgressView("Requesting code…")
                }
            case .polling:
                ProgressView("Waiting for you to authorize…")
            case .success:
                Label("Signed in!", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            case .failed(let message):
                Label(message, systemImage: "xmark.circle.fill")
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                Button("Try again") { appState.auth.start() }
            }

            Button("Cancel") { dismiss() }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(28)
        .frame(width: 340)
        .onChange(of: appState.isSignedIn) { _, signedIn in
            if signedIn { dismiss() }
        }
    }
}
