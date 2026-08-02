import Foundation

enum GitHubError: Error, LocalizedError {
    case unauthorized
    case http(Int)
    case decoding

    var errorDescription: String? {
        switch self {
        case .unauthorized: "Unauthorized — sign in again"
        case let .http(code): "GitHub API error (\(code))"
        case .decoding: "Failed to parse GitHub response"
        }
    }
}

/// Thin async REST client for the GitHub Actions API.
struct GitHubClient {
    var token: () -> String?

    private var decoder: JSONDecoder {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .iso8601
        return jsonDecoder
    }

    func latestRuns(for repo: RepoRef, perPage: Int = 10) async throws -> [WorkflowRun] {
        let base = Config.apiBase
            .appendingPathComponent("repos")
            .appendingPathComponent(repo.owner)
            .appendingPathComponent(repo.name)
            .appendingPathComponent("actions/runs")
        let url = base.appending(queryItems: [URLQueryItem(name: "per_page", value: "\(perPage)")])

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        if let token = token() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw GitHubError.decoding }
        guard http.statusCode == 200 else {
            if http.statusCode == 401 { throw GitHubError.unauthorized }
            throw GitHubError.http(http.statusCode)
        }

        // swiftlint:disable:next identifier_name
        struct Envelope: Decodable { let workflow_runs: [WorkflowRun] }
        do {
            return try decoder.decode(Envelope.self, from: data).workflow_runs
        } catch {
            throw GitHubError.decoding
        }
    }
}
