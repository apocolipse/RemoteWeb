// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RemoteWeb",
    platforms: [ .macOS(.v10_12) ],
    dependencies: [
        .package(url: "https://github.com/apocolipse/swifter", from: "1.4.7"),
        .package(url: "git@github.com:apocolipse/SwiftLIRC.git", from: "0.2.5")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "RemoteWeb",
            dependencies: ["Swifter", "LIRC"]),
        .testTarget(
            name: "RemoteWebTests",
            dependencies: ["RemoteWeb"]),
    ]
)
