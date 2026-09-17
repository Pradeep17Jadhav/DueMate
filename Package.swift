// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "DueMate",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(name: "DueMateCore", targets: ["DueMateCore"]),
        .library(name: "DueMateUI", targets: ["DueMateUI"]),
        .executable(name: "DueMate", targets: ["DueMateApp"]),
    ],
    targets: [
        .target(name: "DueMateCore"),
        .target(name: "DueMateUI", dependencies: ["DueMateCore"]),
        .executableTarget(name: "DueMateApp", dependencies: ["DueMateUI"]),
    ]
)
