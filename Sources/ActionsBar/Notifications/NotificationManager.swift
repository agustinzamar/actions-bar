import Foundation
import UserNotifications

enum NotificationEvent: String, CaseIterable, Codable {
    case failure, fixed, success, cancelled
}

/// Fires native notifications for workflow run transitions, honoring global + per-repo rules.
final class NotificationManager {
    static let shared = NotificationManager()

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    @MainActor
    func notifyIfNeeded(repo: RepoRef, from: RunStatus, to: RunStatus, settings: AppSettings) {
        guard settings.notificationsEnabled else { return }
        guard let event = event(from: from, to: to) else { return }

        let rule = settings.repoRule(for: repo)
        if rule.muted { return }
        if rule.onlyFailures && event != .failure { return }
        guard settings.isEventEnabled(event) else { return }

        let content = UNMutableNotificationContent()
        content.title = repo.fullName
        content.body = body(for: event)
        if settings.soundEnabled {
            content.sound = UNNotificationSound(named: UNNotificationSoundName("\(settings.soundName).aiff"))
        }
        content.interruptionLevel = settings.respectFocusMode ? (event == .failure ? .timeSensitive : .active) : .timeSensitive

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func event(from: RunStatus, to: RunStatus) -> NotificationEvent? {
        switch (from, to) {
        case (_, .failure) where from != .failure: .failure
        case (.failure, .success): .fixed
        case (_, .success) where from != .success: .success
        case (_, .cancelled) where from != .cancelled: .cancelled
        default: nil
        }
    }

    private func body(for event: NotificationEvent) -> String {
        switch event {
        case .failure: "Workflow run failed"
        case .fixed: "Workflow run fixed"
        case .success: "Workflow run succeeded"
        case .cancelled: "Workflow run cancelled"
        }
    }
}
