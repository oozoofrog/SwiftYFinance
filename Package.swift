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
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.31.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SwiftYFinance",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf")
            ],
            exclude: [
                // README 문서들은 리소스로 포함하지 않고 제외하여 중복 리소스 이름 문제 방지
                "Models/README.md",
                "Models/Primitives/README.md",
                "Models/Streaming/README.md",
                "Models/Business/README.md",
                "Models/Network/README.md",
                "Models/Network/Domain/README.md",
                "Models/Network/News/README.md",
                "Models/Network/Search/README.md",
                "Models/Network/Options/README.md",
                "Models/Network/Chart/README.md",
                "Models/Network/Financials/README.md",
                "Models/Network/Screening/README.md",
                "Models/Screener/README.md",
                "Models/Network/Quote/README.md",
                "Models/Network/Quote/Core/README.md",
                "Models/Network/Quote/CompositeModels/README.md",
                "Models/Network/Quote/ModularComponents/README.md",
                "Models/Network/Quote/ResponseWrappers/README.md",
                "Models/Configuration/README.md"
            ],
            resources: [
                .process("Protobuf/PricingData.proto"),  // .proto 파일을 리소스로 명시
                .process("Resources"),  // Resources 디렉토리를 리소스로 명시
                // Quote 문서 파일은 리소스로 포함
                .process("Models/Network/Quote/Documentation")
            ]
        ),
        .testTarget(
            name: "SwiftYFinanceTests",
            dependencies: ["SwiftYFinance"]
        ),
    ]
)
