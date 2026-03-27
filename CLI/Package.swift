// swift-tools-version: 6.2
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
            path: "Sources/SwiftYFinanceCLI",
            swiftSettings: [
                // Swift 6 엄격 동시성 모드 — Sendable, actor isolation 컴파일 타임 검증
                .swiftLanguageMode(.v6),
                // NonisolatedNonsendingByDefault: Swift 6.2 Approachable Concurrency 핵심 기능
                // nonisolated async 함수가 기본적으로 호출자의 actor 컨텍스트에서 실행되도록 설정
                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
            ]
        ),
    ]
)
