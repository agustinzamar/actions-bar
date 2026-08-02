import SwiftUI
import AppKit

struct MenuContentView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.openSettings) private var openSettings
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Group {
            if appState.isSignedIn {
                signedInView
            } else {
                signedOutView
            }
        }
    }

    private var signedInView: some View {
        VStack(alignment: .leading, spacing: 8) {
            if appState.settings.watchedRepos.isEmpty {
                Text("No repos watched yet. Add one in Settings.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(appState.settings.watchedRepos) { repo in
                    repoRow(repo)
                }
            }

            Divider()

            Button("Settings…") {
                NSApp.activate(ignoringOtherApps: true)
                openSettings()
            }
            Button("Quit") { NSApplication.shared.terminate(nil) }
        }
        .padding(12)
        .frame(minWidth: 260)
    }

    /// No settings or repo picker here on purpose — nothing to configure until signed in.
    /// Sign-in itself happens in a separate real window (see SignInCodeView) because
    /// this popover auto-dismisses the instant focus shifts to the browser.
    private var signedOutView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
                .padding(.top, 8)

            GitHubSignInButton {
                appState.auth.start()
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "sign-in")
            }

            Divider()

            Button("Quit") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(width: 300)
    }

    private func repoRow(_ repo: RepoRef) -> some View {
        let state = appState.poller.repoStates[repo.id]
        return HStack {
            StatusIcon(status: state?.status ?? .unknown)
            VStack(alignment: .leading) {
                Text(repo.fullName)
                if let run = state?.latestRun {
                    Text(run.headBranch).font(.caption).foregroundStyle(.secondary)
                } else if let error = state?.lastError {
                    Text(error).font(.caption).foregroundStyle(.red)
                }
            }
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if let urlString = state?.latestRun?.htmlURL, let url = URL(string: urlString) {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
