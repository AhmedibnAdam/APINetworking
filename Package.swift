// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "APINetworking",
    platforms: [
           .iOS(.v15),  // Minimum target set to iOS 13
           .macOS(.v10_15)  // You can also specify other platforms if needed
       ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "APINetworking",
            targets: ["APINetworking"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "APINetworking"),
        .testTarget(
            name: "APINetworkingTests",
            dependencies: ["APINetworking"]
        ),
    ]
)
