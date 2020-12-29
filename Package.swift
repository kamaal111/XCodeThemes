// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "XCodeThemes",
    products: [
        .library(
            name: "XCodeThemes",
            targets: ["XCodeThemes"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "XCodeThemes",
            dependencies: []),
        .testTarget(
            name: "XCodeThemesTests",
            dependencies: ["XCodeThemes"]),
    ]
)
