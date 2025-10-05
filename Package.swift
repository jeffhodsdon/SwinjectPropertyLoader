// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwinjectPropertyLoader",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(
            name: "SwinjectPropertyLoader",
            targets: ["SwinjectPropertyLoader"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Swinject/Swinject.git", from: "2.9.1"),
        .package(url: "https://github.com/LebJe/TOMLKit.git", from: "0.6.0")
    ],
    targets: [
        .target(
            name: "SwinjectPropertyLoader",
            dependencies: ["Swinject", "TOMLKit"],
            path: "Sources"),
        .testTarget(
            name: "SwinjectPropertyLoaderTests",
            dependencies: ["SwinjectPropertyLoader"],
            path: "Tests",
            resources: [
                .process("Resources")
            ]),
    ],
    swiftLanguageVersions: [.v5, .version("6")]
)
