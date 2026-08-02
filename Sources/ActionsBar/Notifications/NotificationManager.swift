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
        guard let event = event(from: from, to: to) else { return }

        let rule = settings.repoRule(for: repo)
        if rule.muted { return }
        if rule.onlyFailures && event != .failure { return }
        guard settings.isEventEnabled(event) else { return }

        let content = UNMutableNotificationContent()
        content.title = repo.fullName
        content.body = body(for: event)
        if settings.soundEnabled {
            content.sound = .default
        }
        content.interruptionLevel = event == .failure ? .timeSensitive : .active

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func event(from: RunStatus, to: RunStatus) -> NotificationEvent? {
        switch (from, to) {
        case (_, .failure) where from != .failure: return .failure
        case (.failure, .success): return .fixed
        case (_, .success) where from != .success: return .success
        case (_, .cancelled) where from != .cancelled: return .cancelled
        default: return nil
        }
    }

    private func body(for event: NotificationEvent) -> String {
        switch event {
        case .failure: return "Workflow run failed"
        case .fixed: return "Workflow run fixed"
        case .success: return "Workflow run succeeded"
        case .cancelled: return "Workflow run cancelled"
        }
    }
}
