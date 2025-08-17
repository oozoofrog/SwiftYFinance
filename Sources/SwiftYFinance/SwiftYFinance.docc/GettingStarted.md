# Getting Started

SwiftYFinance를 시작하기 위한 기본 가이드

## Overview

SwiftYFinance는 Yahoo Finance API를 통해 금융 데이터를 가져오는 Swift 라이브러리입니다. 이 가이드에서는 라이브러리를 설치하고 첫 번째 API 호출을 하는 방법을 설명합니다.

## Installation

### Swift Package Manager

가장 권장하는 설치 방법입니다. Package.swift 파일에 다음 의존성을 추가하세요:

```swift
// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "YourProject",
    platforms: [
        .macOS(.v15),
        .iOS(.v18)
    ],
    dependencies: [
        .package(url: "https://github.com/your-org/SwiftYFinance.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "YourProject",
            dependencies: ["SwiftYFinance"]
        )
    ]
)
```

### Xcode Project

1. Xcode에서 프로젝트를 엽니다
2. **File** → **Add Package Dependencies...** 선택
3. URL 입력란에 `https://github.com/your-org/SwiftYFinance.git` 입력
4. **Add Package** 클릭
5. 최신 버전을 선택하고 프로젝트에 추가

## First Steps

### 1. 라이브러리 Import

Swift 파일 상단에 SwiftYFinance를 import합니다:

```swift
import SwiftYFinance
```

### 2. 클라이언트 생성

모든 API 호출은 `YFClient`를 통해 이루어집니다:

```swift
let client = YFClient()
```

### 3. 첫 번째 API 호출

Apple(AAPL) 주식의 현재 시세를 가져와보겠습니다:

```swift
import SwiftYFinance

func fetchAppleStock() async {
    let client = YFClient()
    
    do {
        // 종목 심볼 생성
        let ticker = YFTicker(symbol: "AAPL")
        
        // 현재 시세 조회
        let quote = try await client.fetchQuote(ticker: ticker)
        
        print("Apple 현재 가격: $\(quote.regularMarketPrice)")
        print("시가총액: $\(quote.marketCap ?? 0)")
        print("거래량: \(quote.regularMarketVolume ?? 0)")
        
    } catch {
        print("에러 발생: \(error)")
    }
}

// async 함수 호출
Task {
    await fetchAppleStock()
}
```

## Error Handling

SwiftYFinance는 구조화된 에러 처리를 제공합니다:

```swift
do {
    let quote = try await client.fetchQuote(ticker: ticker)
    // 성공적으로 데이터를 가져온 경우
} catch YFError.networkError {
    print("네트워크 연결을 확인해주세요")
} catch YFError.rateLimited {
    print("너무 많은 요청을 보냈습니다. 잠시 후 다시 시도해주세요")
} catch {
    print("알 수 없는 에러: \(error)")
}
```

## Common Patterns

### 여러 종목 조회

```swift
let symbols = ["AAPL", "GOOGL", "MSFT", "TSLA"]

for symbolString in symbols {
    do {
        let ticker = YFTicker(symbol: symbolString)
        let quote = try await client.fetchQuote(ticker: ticker)
        
        print("\(symbolString): $\(quote.regularMarketPrice)")
        
        // Rate limiting을 위한 잠시 대기
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1초
        
    } catch {
        print("\(symbolString) 에러: \(error)")
    }
}
```

### 과거 데이터 조회

```swift
let ticker = YFTicker(symbol: "AAPL")

// 지난 1개월 일별 데이터
let history = try await client.fetchHistory(ticker: ticker, period: .oneMonth)

print("지난 30일간 \(history.prices.count)개의 데이터")

for price in history.prices.prefix(5) {
    print("날짜: \(price.date), 종가: $\(price.close)")
}
```

## Rate Limiting

Yahoo Finance API는 요청 수 제한이 있습니다. SwiftYFinance는 자동으로 이를 처리하지만, 대량의 요청을 보낼 때는 주의해야 합니다:

```swift
// 좋은 예: 요청 사이에 지연 추가
for symbol in symbols {
    let quote = try await client.fetchQuote(ticker: ticker)
    // ... 데이터 처리
    
    try await Task.sleep(nanoseconds: 100_000_000) // 0.1초 대기
}
```

## Next Steps

기본 사용법을 익혔다면 다음 가이드들을 확인해보세요:

- <doc:BasicUsage> - 다양한 데이터 타입 조회
- <doc:Authentication> - 인증 및 고급 설정
- <doc:AdvancedFeatures> - 옵션, 기술적 분석, 뉴스 등 고급 기능

## Troubleshooting

### 일반적인 문제들

**Invalid Symbol 에러**
- 종목 심볼이 정확한지 확인
- Yahoo Finance에서 실제로 거래되는 종목인지 확인

**Network Error**
- 인터넷 연결 상태 확인
- 방화벽 설정 확인

**Rate Limited**
- 요청 간격을 늘려서 재시도
- 동시에 너무 많은 요청을 보내지 않도록 조정

더 자세한 도움이 필요하면 GitHub Issues에 문의해주세요.