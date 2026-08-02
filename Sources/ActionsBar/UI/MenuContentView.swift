import AppKit
import SwiftUI

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

            HStack(spacing: 8) {
                Toggle("Auto-fetch", isOn: $appState.settings.autoFetchEnabled)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .labelsHidden()
                Text("Auto-fetch")
                    .font(.caption)
                Spacer()
                Text(lastFetchedText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)

            Divider()

            VStack(spacing: 2) {
                MenuRow(icon: "arrow.clockwise", title: "Refresh", shortcutLabel: "⌘R", keyboardShortcut: KeyboardShortcut("r", modifiers: .command)) {
                    appState.refreshNow()
                }
                MenuRow(icon: "gearshape", title: "Settings…", shortcutLabel: "⌘,", keyboardShortcut: KeyboardShortcut(",", modifiers: .command)) {
                    NSApp.activate(ignoringOtherApps: true)
                    openSettings()
                }
                MenuRow(icon: "info.circle", title: "About ActionsBar") {
                    NSApp.activate(ignoringOtherApps: true)
                    NSApp.orderFrontStandardAboutPanel(nil)
                }
                MenuRow(icon: "power", title: "Quit", shortcutLabel: "⌘Q", keyboardShortcut: KeyboardShortcut("q", modifiers: .command)) {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .padding(12)
        .frame(minWidth: 280)
    }

    private var lastFetchedText: String {
        guard let last = appState.poller.lastFetched else { return "Never fetched" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: last, relativeTo: Date())
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
