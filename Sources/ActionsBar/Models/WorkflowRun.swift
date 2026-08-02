import Foundation

/// Subset of GitHub's workflow run object we care about.
/// https://docs.github.com/en/rest/actions/workflow-runs
struct WorkflowRun: Codable, Identifiable {
    let id: Int
    let name: String?
    let status: String
    let conclusion: String?
    let htmlURL: String
    let headBranch: String
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, status, conclusion
        case htmlURL = "html_url"
        case headBranch = "head_branch"
        case updatedAt = "updated_at"
    }

    var runStatus: RunStatus {
        RunStatus(status: status, conclusion: conclusion)
    }
}

/// Latest known state for one watched repo, tracked by the poller.
struct RepoRunState: Identifiable {
    let repo: RepoRef
    var latestRun: WorkflowRun?
    var lastError: String?

    var id: String {
        repo.id
    }

    var status: RunStatus {
        latestRun?.runStatus ?? .unknown
    }
}
