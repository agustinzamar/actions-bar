import AppKit
import SwiftUI

struct MenuContentView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.openSettings) private var openSettings
    @State private var tokenText = ""

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
    private var signedOutView: some View {
        VStack(spacing: 14) {
            GitHubMarkIcon(size: 32)
                .foregroundStyle(.secondary)
                .padding(.top, 8)

            Text("Sign in with a GitHub token")
                .font(.headline)

            SecureField("Personal access token", text: $tokenText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 240)
                .onSubmit(signIn)

            Button("Sign In", action: signIn)
                .buttonStyle(.borderedProminent)
                .disabled(tokenText.isEmpty || appState.auth.state == .validating)

            switch appState.auth.state {
            case .validating:
                ProgressView().controlSize(.small)
            case let .failed(message):
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            case .idle, .success:
                EmptyView()
            }

            Button("Create a token on GitHub") {
                NSWorkspace.shared.open(URL(string: "https://github.com/settings/tokens/new?scopes=repo,workflow&description=ActionsBar")!)
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundStyle(.secondary)

            Divider()

            Button("Quit") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(width: 300)
    }

    private func signIn() {
        appState.auth.signIn(token: tokenText)
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
