import Combine
import Foundation

/// Polls watched repos on a timer and publishes latest run state + status transitions.
@MainActor
final class RunsPoller: ObservableObject {
    @Published private(set) var repoStates: [String: RepoRunState] = [:]
    @Published private(set) var lastFetched: Date?

    private var timer: Timer?
    private let client: GitHubClient
    private let onTransition: (RepoRef, RunStatus, RunStatus) -> Void

    init(client: GitHubClient, onTransition: @escaping (RepoRef, RunStatus, RunStatus) -> Void) {
        self.client = client
        self.onTransition = onTransition
    }

    func start(repos: [RepoRef], interval: TimeInterval) {
        stop()
        repoStates = repoStates.filter { key, _ in repos.contains { $0.id == key } }

        Task { await pollOnce(repos: repos) }
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { await self?.pollOnce(repos: repos) }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    var aggregateStatus: RunStatus {
        repoStates.values.map(\.status).max() ?? .unknown
    }

    private func pollOnce(repos: [RepoRef]) async {
        for repo in repos {
            let previousStatus = repoStates[repo.id]?.status ?? .unknown
            do {
                let runs = try await client.latestRuns(for: repo)
                let latest = runs.first
                repoStates[repo.id] = RepoRunState(repo: repo, latestRun: latest, lastError: nil)

                let newStatus = latest?.runStatus ?? .unknown
                if newStatus != previousStatus, previousStatus != .unknown {
                    onTransition(repo, previousStatus, newStatus)
                }
            } catch {
                repoStates[repo.id] = RepoRunState(
                    repo: repo,
                    latestRun: repoStates[repo.id]?.latestRun,
                    lastError: error.localizedDescription
                )
            }
        }
        lastFetched = Date()
    }
}
