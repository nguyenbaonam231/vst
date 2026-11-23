// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VideoStarToolLocal",
    platforms: [.iOS("17.2")],
    products: [
        .library(name: "VideoStarToolLocal", type: .dynamic, targets: ["VideoStarToolLocal"])
    ],
    targets: [
        .target(
            name: "VideoStarToolLocal",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "VideoStarToolLocalTests",
            dependencies: ["VideoStarToolLocal"]
        )
    ]
)
