import Foundation
import Combine

/// Per-repo notification override.
struct RepoNotificationRule: Codable {
    var muted: Bool = false
    var onlyFailures: Bool = false
}

/// User-facing preferences, persisted via UserDefaults.
@MainActor
final class AppSettings: ObservableObject {
    @Published var watchedRepos: [RepoRef] {
        didSet { persist(watchedRepos, key: .watchedRepos) }
    }
    @Published var pollInterval: TimeInterval {
        didSet { UserDefaults.standard.set(pollInterval, forKey: Keys.pollInterval.rawValue) }
    }
    @Published var enabledEvents: Set<NotificationEvent> {
        didSet { persist(Array(enabledEvents), key: .enabledEvents) }
    }
    @Published var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: Keys.soundEnabled.rawValue) }
    }
    @Published private var repoRules: [String: RepoNotificationRule] {
        didSet { persist(repoRules, key: .repoRules) }
    }

    private enum Keys: String {
        case watchedRepos, pollInterval, enabledEvents, soundEnabled, repoRules
    }

    init() {
        let defaults = UserDefaults.standard
        watchedRepos = Self.load([RepoRef].self, key: .watchedRepos) ?? []
        pollInterval = defaults.object(forKey: Keys.pollInterval.rawValue) as? TimeInterval ?? Config.defaultPollInterval
        let events = Self.load([NotificationEvent].self, key: .enabledEvents) ?? [.failure, .fixed]
        enabledEvents = Set(events)
        soundEnabled = defaults.object(forKey: Keys.soundEnabled.rawValue) as? Bool ?? true
        repoRules = Self.load([String: RepoNotificationRule].self, key: .repoRules) ?? [:]
    }

    func isEventEnabled(_ event: NotificationEvent) -> Bool { enabledEvents.contains(event) }

    func repoRule(for repo: RepoRef) -> RepoNotificationRule {
        repoRules[repo.id] ?? RepoNotificationRule()
    }

    func setRepoRule(_ rule: RepoNotificationRule, for repo: RepoRef) {
        repoRules[repo.id] = rule
    }

    func addRepo(_ repo: RepoRef) {
        guard !watchedRepos.contains(repo) else { return }
        watchedRepos.append(repo)
    }

    func removeRepo(_ repo: RepoRef) {
        watchedRepos.removeAll { $0.id == repo.id }
        repoRules.removeValue(forKey: repo.id)
    }

    private func persist<T: Codable>(_ value: T, key: Keys) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key.rawValue)
    }

    private static func load<T: Codable>(_ type: T.Type, key: Keys) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key.rawValue) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
