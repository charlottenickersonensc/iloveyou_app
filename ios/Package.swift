// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "iLoveYouApp",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "iLoveYouAppCore", targets: ["iLoveYouAppCore"])
    ],
    targets: [
        .target(
            name: "iLoveYouAppCore",
            path: "iLoveYouApp",
            exclude: [
                "App/iLoveYouApp.swift",
                "Resources"
            ]
        ),
        .testTarget(
            name: "iLoveYouAppTests",
            dependencies: ["iLoveYouAppCore"],
            path: "iLoveYouAppTests"
        )
    ]
)
