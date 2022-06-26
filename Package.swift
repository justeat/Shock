// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Shock",
    products: [
        .library(
            name: "Shock",
            targets: ["Shock"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio",
                 from: "2.40.0"),
        .package(name: "Mustache",
                 url: "https://github.com/groue/GRMustache.swift",
                 from: "4.0.1")
    ],
    targets: [
        .target(
            name: "Shock",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                "Mustache"
            ],
            path: "Shock/Classes/"),
        .testTarget(
            name: "Shock-Tests",
            dependencies: ["Shock"],
            path: "Example/Tests"),
    ]
)
