// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "smart-dial",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "DialCore", targets: ["DialCore"]),
        .library(name: "DialUI", targets: ["DialUI"]),
    ],
    targets: [
        .target(
            name: "DialCore",
            path: "Sources/DialCore"
        ),
        .target(
            name: "DialUI",
            dependencies: ["DialCore"],
            path: "Sources/DialUI"
        ),
        .testTarget(
            name: "DialCoreTests",
            dependencies: ["DialCore"],
            path: "Tests/DialCoreTests"
        )
    ]
)
