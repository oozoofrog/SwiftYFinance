// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftYFinance",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v11)
    ],
    products: [
        .library(
            name: "SwiftYFinance",
            targets: ["SwiftYFinance"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.31.0")
    ],
    targets: [
        .target(
            name: "SwiftYFinance",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf")
            ],
            resources: [
                .process("Protobuf/PricingData.proto"),
                .process("Resources"),
                .process("Models/Network/Quote/Documentation")
            ]
        ),
        .testTarget(
            name: "SwiftYFinanceTests",
            dependencies: ["SwiftYFinance"]
        ),
    ]
)
