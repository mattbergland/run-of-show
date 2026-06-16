// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "RunOfShow",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "RunOfShowKit",
            targets: ["RunOfShowKit"]
        )
    ],
    targets: [
        .target(
            name: "RunOfShowKit",
            path: "Sources/RunOfShowKit"
        ),
        .testTarget(
            name: "RunOfShowKitTests",
            dependencies: ["RunOfShowKit"],
            path: "Tests/RunOfShowKitTests"
        )
    ]
)
