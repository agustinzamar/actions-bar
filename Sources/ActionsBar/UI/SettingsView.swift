import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var newRepoText = ""

    var body: some View {
        TabView {
            reposTab.tabItem { Text("Repos") }
            notificationsTab.tabItem { Text("Notifications") }
            accountTab.tabItem { Text("Account") }
        }
        .padding(20)
        .frame(width: 420, height: 340)
    }

    private var reposTab: some View {
        VStack(alignment: .leading) {
            HStack {
                TextField("owner/repo", text: $newRepoText)
                    .onSubmit(addRepo)
                Button("Add", action: addRepo)
            }
            List {
                ForEach(appState.settings.watchedRepos) { repo in
                    HStack {
                        Text(repo.fullName)
                        Spacer()
                        Button(role: .destructive) {
                            appState.settings.removeRepo(repo)
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            HStack {
                Text("Poll every")
                Stepper(
                    value: $appState.settings.pollInterval,
                    in: Config.minPollInterval...Config.maxPollInterval,
                    step: 15
                ) {
                    Text("\(Int(appState.settings.pollInterval))s")
                }
            }
        }
    }

    private func addRepo() {
        guard let repo = RepoRef(fullName: newRepoText) else { return }
        appState.settings.addRepo(repo)
        newRepoText = ""
    }

    private var notificationsTab: some View {
        Form {
            Section("Events") {
                ForEach(NotificationEvent.allCases, id: \.self) { event in
                    Toggle(event.rawValue.capitalized, isOn: Binding(
                        get: { appState.settings.isEventEnabled(event) },
                        set: { enabled in
                            if enabled { appState.settings.enabledEvents.insert(event) }
                            else { appState.settings.enabledEvents.remove(event) }
                        }
                    ))
                }
            }
            Section("Delivery") {
                Toggle("Play sound", isOn: $appState.settings.soundEnabled)
            }
            Section("Per-repo overrides") {
                ForEach(appState.settings.watchedRepos) { repo in
                    RepoRuleRow(repo: repo)
                }
            }
        }
    }

    private var accountTab: some View {
        VStack {
            if appState.isSignedIn {
                Button("Sign out", role: .destructive) { appState.signOut() }
            } else {
                Button("Sign in with GitHub") { appState.auth.start() }
            }
        }
    }
}

private struct RepoRuleRow: View {
    @EnvironmentObject var appState: AppState
    let repo: RepoRef

    var body: some View {
        let rule = appState.settings.repoRule(for: repo)
        HStack {
            Text(repo.fullName)
            Spacer()
            Toggle("Only failures", isOn: Binding(
                get: { rule.onlyFailures },
                set: { appState.settings.setRepoRule(RepoNotificationRule(muted: rule.muted, onlyFailures: $0), for: repo) }
            ))
            Toggle("Mute", isOn: Binding(
                get: { rule.muted },
                set: { appState.settings.setRepoRule(RepoNotificationRule(muted: $0, onlyFailures: rule.onlyFailures), for: repo) }
            ))
        }
    }
}
