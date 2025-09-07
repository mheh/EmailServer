// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "EmailServer",
    platforms: [
       .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.115.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
        .package(url: "https://github.com/mheh/EmailServerAPI.git", branch: "master"),
        .package(url: "https://github.com/vapor-community/sendgrid-kit.git", from: "3.1.0"),
        .package(url: "https://github.com/vapor/queues.git", exact: "1.17.2"),
        .package(url: "https://github.com/vapor/queues-redis-driver.git", exact: "1.1.2"),
        .package(url: "https://github.com/apple/swift-openapi-runtime", exact: "1.8.2"),
        .package(url: "https://github.com/swift-server/swift-openapi-vapor", exact: "1.0.1"),
        .package(url: "https://github.com/swift-server/swift-openapi-async-http-client", from: "1.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", exact: "1.9.3"),
        .package(url: "https://github.com/Cocoanetics/SwiftMail", revision: "1a5f874"),
    ],
    targets: [
        .executableTarget(
            name: "EmailServer",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "email-server-api", package: "EmailServerAPI"),
                .product(name: "SendGridKit", package: "sendgrid-kit"),
                .product(name: "Queues", package: "queues"),
                .product(name: "QueuesRedisDriver", package: "queues-redis-driver"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIVapor", package: "swift-openapi-vapor"),
                .product(name: "OpenAPIAsyncHTTPClient", package: "swift-openapi-async-http-client"),
                .product(name: "SwiftMail", package: "SwiftMail"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "EmailServerTests",
            dependencies: [
                .target(name: "EmailServer"),
                .product(name: "VaporTesting", package: "vapor"),
            ],
            swiftSettings: swiftSettings
        )
    ]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("ExistentialAny"),
] }
