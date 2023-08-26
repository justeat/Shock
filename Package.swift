// swift-tools-version: 5.5

import PackageDescription

let package = Package(
    name: "Shock",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "Shock",
            targets: ["Shock"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio",
                 from: "2.40.0"),
        .package(url: "https://github.com/groue/GRMustache.swift",
                 from: "4.0.1"),
        .package(url: "https://github.com/justeat/JustLog",
                 from: "4.0.2")
    ],
    targets: [
        .target(
            name: "Shock",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOConcurrencyHelpers", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "Mustache", package: "GRMustache.swift")
            ],
            path: "Framework/Sources"),
        .testTarget(
            name: "UnitTests",
            dependencies: [
                .byName(name: "Shock"),
                .product(name: "JustLog", package: "JustLog")
            ],
            path: "Tests/Sources",
            resources: [
                .process("Resources")
            ])
    ]
)
