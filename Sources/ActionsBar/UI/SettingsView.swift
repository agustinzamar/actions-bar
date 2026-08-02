import SwiftUI

private struct EventMetadata {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
}

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var newRepoText = ""

    var body: some View {
        TabView {
            reposTab.tabItem { Label("Repos", systemImage: "folder.fill") }
            notificationsTab.tabItem { Label("Notifications", systemImage: "bell.fill") }
            accountTab.tabItem { Label("Account", systemImage: "person.crop.circle.fill") }
        }
        .padding(20)
        .frame(width: 440, height: 520)
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
            .frame(maxHeight: 260)

            HStack {
                Text("Poll every")
                Stepper(
                    value: $appState.settings.pollInterval,
                    in: Config.minPollInterval ... Config.maxPollInterval,
                    step: 15
                ) {
                    Text("\(Int(appState.settings.pollInterval))s")
                }
            }
            .padding(.top, 4)
        }
    }

    private func addRepo() {
        guard let repo = RepoRef(fullName: newRepoText) else { return }
        appState.settings.addRepo(repo)
        newRepoText = ""
    }

    private var overriddenRepos: [RepoRef] {
        appState.settings.watchedRepos.filter { appState.settings.hasOverride(for: $0) }
    }

    private var addableRepos: [RepoRef] {
        appState.settings.watchedRepos.filter { !appState.settings.hasOverride(for: $0) }
    }

    private var notificationsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Allow notifications")
                                .font(.headline)
                            Text("Notifying you about failure, success.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $appState.settings.notificationsEnabled)
                            .toggleStyle(.switch)
                            .controlSize(.small)
                    }
                }
                .padding(14)
                .background(Color.gray.opacity(0.15))
                .cornerRadius(10)

                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("EVENTS")
                            .font(.caption)
                            .textCase(.uppercase)
                            .foregroundStyle(.secondary)
                        Text("Pick the run outcomes worth interrupting you.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 0) {
                        ForEach(Array(NotificationEvent.allCases.enumerated()), id: \.element) { index, event in
                            if index > 0 { Divider() }
                            eventRow(event)
                        }
                    }
                    .padding(14)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(10)
                }
                .disabled(!appState.settings.notificationsEnabled)
                .opacity(appState.settings.notificationsEnabled ? 1 : 0.4)

                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("DELIVERY")
                            .font(.caption)
                            .textCase(.uppercase)
                            .foregroundStyle(.secondary)
                        Text("How alerts show up on this Mac.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 0) {
                        soundRow
                        Divider()
                        focusModeRow
                    }
                    .padding(14)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(10)
                }
                .disabled(!appState.settings.notificationsEnabled)
                .opacity(appState.settings.notificationsEnabled ? 1 : 0.4)

                if !appState.settings.watchedRepos.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("PER-REPO OVERRIDES")
                                    .font(.caption)
                                    .textCase(.uppercase)
                                    .foregroundStyle(.secondary)
                                Text("These repositories ignore the settings above.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Menu {
                                ForEach(addableRepos) { repo in
                                    Button(repo.fullName) {
                                        appState.settings.setRepoRule(RepoNotificationRule(), for: repo)
                                    }
                                }
                            } label: {
                                Label("Add repo", systemImage: "plus")
                                    .font(.caption)
                            }
                            .disabled(addableRepos.isEmpty)
                            .menuStyle(.borderlessButton)
                            .fixedSize()
                        }

                        if !overriddenRepos.isEmpty {
                            VStack(spacing: 0) {
                                ForEach(Array(overriddenRepos.enumerated()), id: \.element.id) { index, repo in
                                    if index > 0 { Divider() }
                                    RepoRuleRow(repo: repo) {
                                        appState.settings.removeRepoRule(for: repo)
                                    }
                                }
                            }
                            .padding(14)
                            .background(Color.gray.opacity(0.15))
                            .cornerRadius(10)
                        }
                    }
                    .disabled(!appState.settings.notificationsEnabled)
                    .opacity(appState.settings.notificationsEnabled ? 1 : 0.4)
                }

                HStack {
                    Text("Changes apply immediately.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(action: { appState.settings.resetToDefaults() }) {
                        Label("Reset to defaults", systemImage: "arrow.counterclockwise")
                            .font(.caption)
                    }
                }
                .padding(.top, 8)
            }
            .padding(.vertical, 4)
        }
    }

    private func eventRow(_ event: NotificationEvent) -> some View {
        let meta = eventMetadata[event]!
        return HStack(spacing: 12) {
            Image(systemName: meta.icon)
                .foregroundStyle(meta.color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(meta.title)
                    .font(.headline)
                Text(meta.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { appState.settings.isEventEnabled(event) },
                set: { enabled in
                    if enabled { appState.settings.enabledEvents.insert(event) }
                    else { appState.settings.enabledEvents.remove(event) }
                }
            ))
            .toggleStyle(.switch)
            .controlSize(.small)
        }
        .padding(.vertical, 8)
    }

    private var soundRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "speaker.wave.2")
                .frame(width: 20)

            Text("Play sound")
                .font(.headline)

            Spacer()

            Picker("", selection: $appState.settings.soundName) {
                ForEach(["Basso", "Blow", "Bottle", "Frog", "Funk", "Glass", "Hero", "Morse", "Ping", "Pop", "Purr", "Sosumi", "Submarine", "Tink"], id: \.self) { sound in
                    Text(sound).tag(sound)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 110)

            Toggle("", isOn: $appState.settings.soundEnabled)
                .toggleStyle(.switch)
                .controlSize(.small)
        }
        .padding(.vertical, 8)
    }

    private var focusModeRow: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Respect Focus mode")
                    .font(.headline)
                Text("Hold notifications while Do Not Disturb is on.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: $appState.settings.respectFocusMode)
                .toggleStyle(.switch)
                .controlSize(.small)
        }
        .padding(.vertical, 8)
    }

    private var eventMetadata: [NotificationEvent: EventMetadata] {
        [
            .failure: EventMetadata(icon: "xmark.circle", color: .red, title: "Failure", subtitle: "A workflow run finishes with a failing job."),
            .fixed: EventMetadata(icon: "wrench.fill", color: .blue, title: "Fixed", subtitle: "A previously failing workflow passes again."),
            .success: EventMetadata(icon: "checkmark.circle", color: .green, title: "Success", subtitle: "Every run that completes without errors."),
            .cancelled: EventMetadata(icon: "minus.circle", color: .gray, title: "Cancelled", subtitle: "A run is stopped manually or superseded."),
        ]
    }

    private var accountTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SyncStatusRow()
                Divider()
                AppearanceRow()
                Divider()
                LaunchAtLoginRow()
                Divider()
                ShowMenuBarIconRow()
            }
            .padding(14)
            .background(Color.gray.opacity(0.15))
            .cornerRadius(10)

            VStack {
                if appState.isSignedIn {
                    Button("Sign out", role: .destructive) { appState.signOut() }
                } else {
                    Text("Not signed in — sign in from the menu bar icon.")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 14)
        }
    }
}

private struct RepoRuleRow: View {
    @EnvironmentObject var appState: AppState
    let repo: RepoRef
    let onRemove: () -> Void

    var body: some View {
        let rule = appState.settings.repoRule(for: repo)
        let ruleState = RepoRuleState.from(rule)

        HStack(spacing: 12) {
            Text(repo.fullName)
                .font(.subheadline)

            Spacer()

            Picker("", selection: Binding(
                get: { ruleState },
                set: { newState in
                    let newRule = newState.toRule()
                    appState.settings.setRepoRule(newRule, for: repo)
                }
            )) {
                Text("All").tag(RepoRuleState.all)
                Text("Failures").tag(RepoRuleState.failures)
                Text("Muted").tag(RepoRuleState.muted)
            }
            .pickerStyle(.segmented)
            .frame(width: 200)

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
    }
}

private enum RepoRuleState: Hashable {
    case all
    case failures
    case muted

    static func from(_ rule: RepoNotificationRule) -> RepoRuleState {
        if rule.muted { return .muted }
        if rule.onlyFailures { return .failures }
        return .all
    }

    func toRule() -> RepoNotificationRule {
        switch self {
        case .all: RepoNotificationRule(muted: false, onlyFailures: false)
        case .failures: RepoNotificationRule(muted: false, onlyFailures: true)
        case .muted: RepoNotificationRule(muted: true, onlyFailures: false)
        }
    }
}
