import Foundation

enum Config {
    /// GitHub OAuth App client ID (Device Flow).
    /// Create at https://github.com/settings/developers -> "New OAuth App",
    /// enable "Device Flow" on the app's page, then paste the Client ID here.
    static let clientID = "Ov23liFAXzvu3Pgzcgu1"

    static let oauthScope = "repo"
    static let apiBase = URL(string: "https://api.github.com")!

    static let defaultPollInterval: TimeInterval = 45
    static let minPollInterval: TimeInterval = 30
    static let maxPollInterval: TimeInterval = 300
}
