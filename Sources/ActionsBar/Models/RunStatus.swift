import Foundation

/// Simplified status derived from a workflow run's `status` + `conclusion`.
enum RunStatus: String, Codable, Comparable {
    case success
    case inProgress
    case failure
    case cancelled
    case unknown

    /// Ordering used to pick the "worst" status across repos for the menu bar icon.
    private var severity: Int {
        switch self {
        case .failure: return 4
        case .inProgress: return 3
        case .cancelled: return 2
        case .unknown: return 1
        case .success: return 0
        }
    }

    static func < (lhs: RunStatus, rhs: RunStatus) -> Bool {
        lhs.severity < rhs.severity
    }

    init(status: String, conclusion: String?) {
        switch status {
        case "completed":
            switch conclusion {
            case "success": self = .success
            case "cancelled": self = .cancelled
            case "failure", "timed_out", "action_required", "startup_failure": self = .failure
            default: self = .unknown
            }
        case "in_progress", "queued", "waiting", "requested", "pending":
            self = .inProgress
        default:
            self = .unknown
        }
    }
}
