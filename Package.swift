// swift-tools-version: 6.1
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
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftYFinance",
            targets: ["SwiftYFinance"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.30.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SwiftYFinance",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf")
            ],
            resources: [
                .process("Protobuf/PricingData.proto"),  // .proto 파일을 리소스로 명시
                .process("Resources")  // Resources 디렉토리를 리소스로 명시
            ]
        ),
        .testTarget(
            name: "SwiftYFinanceTests",
            dependencies: ["SwiftYFinance"]
        ),
    ]
)
