import Combine
import Foundation

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

    @Published var notificationsEnabled: Bool {
        didSet { UserDefaults.standard.set(notificationsEnabled, forKey: Keys.notificationsEnabled.rawValue) }
    }

    @Published var soundName: String {
        didSet { UserDefaults.standard.set(soundName, forKey: Keys.soundName.rawValue) }
    }

    @Published var respectFocusMode: Bool {
        didSet { UserDefaults.standard.set(respectFocusMode, forKey: Keys.respectFocusMode.rawValue) }
    }

    @Published var autoFetchEnabled: Bool {
        didSet { UserDefaults.standard.set(autoFetchEnabled, forKey: Keys.autoFetchEnabled.rawValue) }
    }

    @Published var appearance: AppearanceMode {
        didSet { UserDefaults.standard.set(appearance.rawValue, forKey: Keys.appearance.rawValue) }
    }

    @Published var showMenuBarIcon: Bool {
        didSet { UserDefaults.standard.set(showMenuBarIcon, forKey: Keys.showMenuBarIcon.rawValue) }
    }

    @Published private var repoRules: [String: RepoNotificationRule] {
        didSet { persist(repoRules, key: .repoRules) }
    }

    private enum Keys: String {
        case watchedRepos, pollInterval, enabledEvents, soundEnabled, notificationsEnabled, soundName, respectFocusMode, repoRules, autoFetchEnabled, appearance, showMenuBarIcon
    }

    init() {
        let defaults = UserDefaults.standard
        watchedRepos = Self.load([RepoRef].self, key: .watchedRepos) ?? []
        pollInterval = defaults.object(forKey: Keys.pollInterval.rawValue) as? TimeInterval ?? Config.defaultPollInterval
        let events = Self.load([NotificationEvent].self, key: .enabledEvents) ?? [.failure, .fixed]
        enabledEvents = Set(events)
        soundEnabled = defaults.object(forKey: Keys.soundEnabled.rawValue) as? Bool ?? true
        notificationsEnabled = defaults.object(forKey: Keys.notificationsEnabled.rawValue) as? Bool ?? true
        soundName = defaults.object(forKey: Keys.soundName.rawValue) as? String ?? "Pop"
        respectFocusMode = defaults.object(forKey: Keys.respectFocusMode.rawValue) as? Bool ?? true
        autoFetchEnabled = defaults.object(forKey: Keys.autoFetchEnabled.rawValue) as? Bool ?? true
        appearance = AppearanceMode(rawValue: defaults.string(forKey: Keys.appearance.rawValue) ?? "") ?? .system
        showMenuBarIcon = defaults.object(forKey: Keys.showMenuBarIcon.rawValue) as? Bool ?? true
        repoRules = Self.load([String: RepoNotificationRule].self, key: .repoRules) ?? [:]
    }

    func isEventEnabled(_ event: NotificationEvent) -> Bool {
        enabledEvents.contains(event)
    }

    func repoRule(for repo: RepoRef) -> RepoNotificationRule {
        repoRules[repo.id] ?? RepoNotificationRule()
    }

    func hasOverride(for repo: RepoRef) -> Bool {
        repoRules[repo.id] != nil
    }

    func setRepoRule(_ rule: RepoNotificationRule, for repo: RepoRef) {
        repoRules[repo.id] = rule
    }

    func removeRepoRule(for repo: RepoRef) {
        repoRules.removeValue(forKey: repo.id)
    }

    func addRepo(_ repo: RepoRef) {
        guard !watchedRepos.contains(repo) else { return }
        watchedRepos.append(repo)
    }

    func removeRepo(_ repo: RepoRef) {
        watchedRepos.removeAll { $0.id == repo.id }
        repoRules.removeValue(forKey: repo.id)
    }

    func resetToDefaults() {
        notificationsEnabled = true
        enabledEvents = [.failure, .fixed]
        soundEnabled = true
        soundName = "Pop"
        respectFocusMode = true
        repoRules = [:]
    }

    private func persist(_ value: some Codable, key: Keys) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key.rawValue)
    }

    private static func load<T: Codable>(_: T.Type, key: Keys) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key.rawValue) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
