// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EmailServer",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .executable(
            name: "MailServer",
            targets: ["MailServer"]
        )
    ],
    dependencies: [
            .package(url: "https://github.com/Cocoanetics/SwiftMail", revision: "1a5f874"),
            .package(url: "https://github.com/vapor/vapor.git", from: "4.115.0"),
            .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
            .package(url: "https://github.com/mheh/EmailServerAPI.git", branch: "streaming"),
    ],
    targets: [
        .executableTarget(
            name: "MailServer",
            dependencies: [
                .product(name: "SwiftMail", package: "SwiftMail"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "email-server-api", package: "EmailServerAPI"),
            ]
        ),
        .testTarget(
            name: "EmailServerTests",
            dependencies: [
                .target(name: "MailServer"),
                .product(name: "XCTVapor", package: "vapor"),
            ],
            swiftSettings: swiftSettings
        ),
    ]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("StrictConcurrency")
] }
