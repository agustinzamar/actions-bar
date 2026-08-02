import Foundation

/// A repo the user watches, in "owner/name" form.
struct RepoRef: Codable, Identifiable, Hashable {
    var owner: String
    var name: String

    var id: String { fullName }
    var fullName: String { "\(owner)/\(name)" }

    /// Parses "owner/name". Returns nil if malformed.
    init?(fullName raw: String) {
        let parts = raw.trimmingCharacters(in: .whitespaces).split(separator: "/")
        guard parts.count == 2, !parts[0].isEmpty, !parts[1].isEmpty else { return nil }
        owner = String(parts[0])
        name = String(parts[1])
    }

    init(owner: String, name: String) {
        self.owner = owner
        self.name = name
    }
}
