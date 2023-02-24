// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ITunesClient",
    platforms: [.iOS(.v15), .macOS(.v12), .watchOS(.v8)],
    products: [
        .library(
            name: "ITunesClient",
            targets: ["ITunesClient"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", exact: "0.47.0"),
    ],
    targets: [
        .target(
            name: "ITunesClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-composable-architecture"),
            ]
        ),
        .testTarget(
            name: "ITunesClientTests",
            dependencies: ["ITunesClient"]
        ),
    ]
)