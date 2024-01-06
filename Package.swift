// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "XCodeThemes",
    platforms: [.macOS(.v12)],
    dependencies: [
        .package(url: "https://github.com/Kamaalio/KamaalSwift", .upToNextMajor(from: "1.6.1"))
    ],
    targets: [
        .executableTarget(
            name: "XCodeThemes",
            dependencies: [
                .product(name: "KamaalExtensions", package: "KamaalSwift")
            ]
        ),
    ]
)
