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
    dependencies: [
        .package(url: "https://github.com/SemanticKit/IRIKit.git", branch: "wp/03a-iri-normalization")
    ],
    targets: [
        .target(
            name: "URIKit",
            dependencies: [
                .product(name: "IRIKit", package: "IRIKit")
            ]
        ),
        .testTarget(
            name: "URIKitTests",
            dependencies: ["URIKit"]
        )
    ]
)
