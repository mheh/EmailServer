// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EmailServer",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "EmailServerAPI",
            targets: ["EmailServerAPI"]),
        .executable(
            name: "EmailServer",
            targets: ["EmailServer"],
        ),
    ],
    dependencies: [
            .package(url: "https://github.com/Cocoanetics/SwiftMail", revision: "1a5f874"),
            .package(url: "https://github.com/modelcontextprotocol/swift-sdk", exact: "0.10.1"),
            .package(url: "https://github.com/swift-server/swift-service-lifecycle.git", from: "2.3.0"),
            .package(url: "https://github.com/vapor/console-kit", exact: "4.15.2"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "EmailServer",
            dependencies: [
                .target(name: "EmailServerAPI"),
                .product(name: "MCP", package: "swift-sdk"),
                .product(name: "ServiceLifecycle", package: "swift-service-lifecycle"),
                .product(name: "ConsoleKit", package: "console-kit"),
            ],
        ),
        .target(
            name: "EmailServerAPI",
            dependencies: [
                .product(name: "SwiftMail", package: "SwiftMail"),
            ]
        ),
        .testTarget(
            name: "EmailServerTests",
            dependencies: ["EmailServer"]
        ),
    ]
)
