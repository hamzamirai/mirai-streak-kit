// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "mirai-streak-kit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "MiraiStreakKit",
            targets: ["MiraiStreakKit"]
        )
    ],
    targets: [
        .target(
            name: "MiraiStreakKit"
        ),
        .testTarget(
            name: "MiraiStreakKitTests",
            dependencies: ["MiraiStreakKit"]
        )
    ]
)
