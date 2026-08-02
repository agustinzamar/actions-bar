import Combine
import Foundation

@MainActor
final class AppState: ObservableObject {
    var settings = AppSettings()
    var auth = PATAuth()
    @Published private(set) var isSignedIn: Bool
    private var cachedToken: String?

    private(set) lazy var poller: RunsPoller = .init(
        client: GitHubClient(token: { [weak self] in self?.cachedToken }),
        onTransition: { [weak self] repo, from, to in
            guard let self else { return }
            NotificationManager.shared.notifyIfNeeded(repo: repo, from: from, to: to, settings: settings)
        }
    )

    private var cancellables: Set<AnyCancellable> = []

    var aggregateStatus: RunStatus {
        isSignedIn ? poller.aggregateStatus : .unknown
    }

    init() {
        cachedToken = KeychainStore.loadToken()
        isSignedIn = cachedToken != nil
        NotificationManager.shared.requestAuthorization()

        auth.$state
            .sink { [weak self] state in
                guard let self, state == .success else { return }
                cachedToken = auth.token
                isSignedIn = true
                restartPolling()
            }
            .store(in: &cancellables)

        settings.$watchedRepos
            .combineLatest(settings.$pollInterval)
            .sink { [weak self] _, _ in self?.restartPolling() }
            .store(in: &cancellables)

        settings.$autoFetchEnabled
            .sink { [weak self] _ in self?.restartPolling() }
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

    func refreshNow() {
        guard isSignedIn else { return }
        poller.refreshNow(repos: settings.watchedRepos)
    }

    func signOut() {
        KeychainStore.clear()
        cachedToken = nil
        isSignedIn = false
        poller.stop()
    }

    private func restartPolling() {
        guard isSignedIn, settings.autoFetchEnabled else {
            poller.stop()
            return
        }
        poller.start(repos: settings.watchedRepos, interval: settings.pollInterval)
    }
}
