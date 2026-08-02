import Combine
import Foundation

/// Validates a GitHub Personal Access Token against the API and stores it in Keychain.
@MainActor
final class PATAuth: ObservableObject {
    enum State: Equatable {
        case idle
        case validating
        case success
        case failed(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var token: String?

    func signIn(token: String) {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            state = .failed("Paste a token first")
            return
        }
        state = .validating
        Task {
            do {
                var request = URLRequest(url: Config.apiBase.appendingPathComponent("user"))
                request.setValue("Bearer \(trimmed)", forHTTPHeaderField: "Authorization")
                request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
                let (_, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse else {
                    state = .failed("No response from GitHub")
                    return
                }
                guard http.statusCode == 200 else {
                    state = .failed(http.statusCode == 401 ? "Invalid or expired token" : "GitHub error (\(http.statusCode))")
                    return
                }
                KeychainStore.save(token: trimmed)
                self.token = trimmed
                state = .success
            } catch {
                state = .failed(error.localizedDescription)
            }
        }
    }
}
