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
            ],
            swiftSettings: [
                // Swift 6 엄격 동시성 모드 — Sendable, actor isolation 컴파일 타임 검증
                .swiftLanguageMode(.v6),
                // NonisolatedNonsendingByDefault: Swift 6.2 Approachable Concurrency 핵심 기능
                // nonisolated async 함수가 기본적으로 호출자의 actor 컨텍스트에서 실행되도록 설정
                // 라이브러리에서 defaultIsolation: MainActor 없이 안전한 concurrency 제공
                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
            ]
        ),
        .testTarget(
            name: "SwiftYFinanceTests",
            dependencies: ["SwiftYFinance"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
    ]
)
