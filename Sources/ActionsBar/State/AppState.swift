import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {
    var settings = AppSettings()
    var auth = DeviceFlowAuth()
    @Published private(set) var isSignedIn: Bool

    private(set) lazy var poller: RunsPoller = RunsPoller(
        client: GitHubClient(token: { KeychainStore.loadToken() }),
        onTransition: { [weak self] repo, from, to in
            guard let self else { return }
            NotificationManager.shared.notifyIfNeeded(repo: repo, from: from, to: to, settings: self.settings)
        }
    )

    private var cancellables: Set<AnyCancellable> = []

    var aggregateStatus: RunStatus {
        isSignedIn ? poller.aggregateStatus : .unknown
    }

    init() {
        isSignedIn = KeychainStore.loadToken() != nil
        NotificationManager.shared.requestAuthorization()

        auth.$state
            .sink { [weak self] state in
                guard let self, state == .success else { return }
                self.isSignedIn = true
                self.restartPolling()
            }
            .store(in: &cancellables)

        settings.$watchedRepos
            .combineLatest(settings.$pollInterval)
            .sink { [weak self] _, _ in self?.restartPolling() }
            .store(in: &cancellables)

        // settings/auth/poller are separate ObservableObjects; views only hold
        // this AppState as their @EnvironmentObject, so forward their change
        // notifications or the UI never redraws when nested state mutates.
        settings.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)

        auth.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)

        poller.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)

        if isSignedIn {
            restartPolling()
        }
    }

    func signOut() {
        KeychainStore.clear()
        isSignedIn = false
        poller.stop()
    }

    private func restartPolling() {
        guard isSignedIn else { return }
        poller.start(repos: settings.watchedRepos, interval: settings.pollInterval)
    }
}
