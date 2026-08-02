import Foundation

enum Config {
    static let apiBase = URL(string: "https://api.github.com")!

    static let defaultPollInterval: TimeInterval = 45
    static let minPollInterval: TimeInterval = 30
    static let maxPollInterval: TimeInterval = 300
}
