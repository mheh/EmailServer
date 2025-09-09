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
        .executable(
            name: "EmailServer",
            targets: ["EmailServer"]
        ),
        .library(
            name: "EmailSessions",
            targets: ["EmailSessions"]
        ),
    ],
    dependencies: [
            .package(url: "https://github.com/Cocoanetics/SwiftMail", revision: "1a5f874"),
            .package(url: "https://github.com/Cocoanetics/SwiftMCP", revision: "ba18d8d"),
            .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
    ],
    targets: [
        .executableTarget(
            name: "EmailServer",
            dependencies: [
                .product(name: "SwiftMail", package: "SwiftMail"),
                .product(name: "SwiftMCP", package: "SwiftMCP"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .target(
            name: "EmailSessions",
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
