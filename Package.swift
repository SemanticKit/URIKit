// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "URIKit",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .visionOS(.v26)
    ],
    products: [
        .library(
            name: "URIKit",
            targets: ["URIKit"]
        )
    ],
    targets: [
        .target(
            name: "URIKit"
        ),
        .testTarget(
            name: "URIKitTests",
            dependencies: ["URIKit"]
        )
    ]
)
