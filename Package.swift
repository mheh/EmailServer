// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "email-server",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .executable(
            name: "email-server-vapor",
            targets: ["email-server-vapor"]
        ),
        .executable(
            name: "email-server-hummingbird",
            targets: ["email-server-hummingbird"]
        )
    ],
    dependencies: [
            .package(url: "https://github.com/Cocoanetics/SwiftMail", revision: "1a5f874"),
            .package(url: "https://github.com/mheh/EmailServerAPI.git", branch: "master"),
            .package(url: "https://github.com/apple/swift-openapi-runtime", exact: "1.8.2"),
            
            .package(url: "https://github.com/vapor/vapor.git", from: "4.115.0"),
            .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
            .package(url: "https://github.com/swift-server/swift-openapi-vapor", exact: "1.0.1"),
            
            .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.5.0"),
            .package(url: "https://github.com/swift-server/swift-openapi-hummingbird.git", from: "2.0.1"),
    ],
    targets: [
        .executableTarget(
            name: "email-server-vapor",
            dependencies: [
                .product(name: "SwiftMail", package: "SwiftMail"),
                .product(name: "email-server-api", package: "EmailServerAPI"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIVapor", package: "swift-openapi-vapor"),
            ]
        ),
        .executableTarget(
            name: "email-server-hummingbird",
            dependencies: [
                .product(name: "SwiftMail", package: "SwiftMail"),
                .product(name: "email-server-api", package: "EmailServerAPI"),
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIHummingbird", package: "swift-openapi-hummingbird"),
            ]
        ),
        .testTarget(
            name: "MailServerVaporTests",
            dependencies: [
                .target(name: "email-server-vapor"),
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
