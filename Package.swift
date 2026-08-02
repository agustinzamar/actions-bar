// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "ActionsBar",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "ActionsBar",
            path: "Sources/ActionsBar",
            resources: [.copy("Resources/GitHubMark.png")]
        )
    ]
)
