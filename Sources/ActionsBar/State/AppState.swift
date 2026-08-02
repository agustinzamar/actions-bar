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
