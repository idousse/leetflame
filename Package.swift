// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "LeetCodeStreakWidget",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "LeetCodeStreakWidget",
            path: "Sources/LeetCodeStreakWidget",
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
