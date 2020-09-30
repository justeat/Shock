// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Shock",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "Shock",
            targets: ["Shock"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(name: "Swifter",
                 url: "git@github.com:httpswift/swifter.git",
                 from: "1.5.0"),
        .package(name: "Mustache",
                 url: "git@github.com:groue/GRMustache.swift.git",
                 from: "4.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Shock",
            dependencies: ["Swifter", "Mustache"],
            path: "Shock/Classes/"),
        .testTarget(
            name: "Shock-Tests",
            dependencies: ["Shock"],
            path: "Example/Tests"),
    ]
)
