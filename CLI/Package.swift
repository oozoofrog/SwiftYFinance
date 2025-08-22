// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftYFinanceCLI",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(
            name: "swiftyfinance",
            targets: ["SwiftYFinanceCLI"]
        )
    ],
    dependencies: [
        .package(path: "../"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0")
    ],
    targets: [
        .executableTarget(
            name: "SwiftYFinanceCLI",
            dependencies: [
                .product(name: "SwiftYFinance", package: "SwiftYFinance"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/SwiftYFinanceCLI"
        ),
    ]
)
