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
        ),
        .executable(
            name: "swiftyfinance-mcp",
            targets: ["SwiftYFinanceMCP"]
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
        // MCP 서버 타겟 — Yahoo Finance 데이터를 JSON-RPC 2.0 stdio 프로토콜로 제공
        // 외부 MCP SDK 없이 순수 Swift 표준 라이브러리만으로 구현
        .executableTarget(
            name: "SwiftYFinanceMCP",
            dependencies: [
                .product(name: "SwiftYFinance", package: "SwiftYFinance")
            ],
            path: "Sources/SwiftYFinanceMCP",
            swiftSettings: [
                // Swift 6 엄격 동시성 모드 — SwiftYFinanceCLI와 동일한 설정
                .swiftLanguageMode(.v6),
                // NonisolatedNonsendingByDefault: Swift 6.2 Approachable Concurrency 핵심 기능
                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
            ]
        ),
        // MCP 서버 단위 테스트 — 순수 로직 테스트, 네트워크 호출 없음
        .testTarget(
            name: "MCPTests",
            dependencies: ["SwiftYFinanceMCP"],
            path: "Tests/MCPTests",
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
    ]
)
