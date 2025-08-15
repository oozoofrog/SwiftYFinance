# ``SwiftYFinance``

Yahoo Finance API를 위한 완전한 Swift 네이티브 라이브러리

## Overview

SwiftYFinance는 Python의 yfinance 라이브러리를 Swift로 완전히 포팅한 금융 데이터 라이브러리입니다. Yahoo Finance API를 통해 주식, ETF, 암호화폐, 통화 등 다양한 금융 상품의 데이터를 실시간으로 가져올 수 있습니다.

### 주요 기능

- **실시간 시세**: 주식, ETF, 암호화폐 등의 실시간 가격 정보
- **과거 가격 데이터**: 다양한 기간과 간격의 OHLCV 데이터
- **재무제표**: 손익계산서, 대차대조표, 현금흐름표
- **옵션 거래**: 옵션 체인, Greeks, 만료일 분석
- **기술적 분석**: SMA, EMA, RSI, MACD, 볼린저밴드 등
- **뉴스 & 감성분석**: 종목 관련 뉴스와 AI 감성 분석
- **종목 스크리닝**: 복합 조건 기반 종목 검색

### Swift의 장점

- **타입 안전성**: 컴파일 타임에 에러 발견
- **Async/Await**: 현대적인 비동기 프로그래밍
- **메모리 안전성**: ARC를 통한 자동 메모리 관리
- **성능**: 네이티브 코드의 빠른 실행 속도
- **멀티플랫폼**: iOS, macOS, tvOS, watchOS 지원

## Topics

### Essentials

라이브러리를 시작하고 기본 기능을 익히기 위한 필수 가이드입니다.

- <doc:GettingStarted>
- <doc:BasicUsage>
- <doc:Authentication>

### Core API

SwiftYFinance의 핵심 클래스와 인터페이스입니다.

- ``YFClient``
- ``YFTicker``
- ``YFError``

### Data Models

금융 데이터를 표현하는 모든 모델 타입들입니다.

#### Quote Data
- ``YFQuote``
- ``YFPrice``
- ``YFHistoricalData``

#### Financial Statements
- ``YFFinancials``
- ``YFBalanceSheet``
- ``YFCashFlow``
- ``YFEarnings``

#### Chart & Technical Data
- ``ChartResponse``
- ``ChartResult``
- ``YFTechnicalIndicators``

#### Options & Advanced
- ``YFOptionsChain``
- ``YFFinancialsAdvanced``
- ``YFNewsArticle``

### Advanced Features

고급 기능과 특화된 도구들입니다.

- <doc:AdvancedFeatures>
- <doc:TechnicalAnalysis>
- <doc:OptionsTrading>
- ``YFScreener``

### Network & Authentication

네트워크 통신과 인증을 담당하는 내부 구조입니다.

- ``YFSession``
- ``YFRequestBuilder``
- ``YFResponseParser``
- ``YFBrowserImpersonator``

### Best Practices

효율적이고 안전한 사용을 위한 가이드입니다.

- <doc:BestPractices>
- <doc:PerformanceOptimization>
- <doc:ErrorHandling>
- <doc:FAQ>

## 시작하기

SwiftYFinance를 사용하여 주식 데이터를 가져오는 기본 예제:

```swift
import SwiftYFinance

// 클라이언트 생성
let client = YFClient()

// 종목 생성
let ticker = try YFTicker(symbol: "AAPL")

// 현재 시세 조회
let quote = try await client.fetchQuote(ticker: ticker)
print("현재 가격: \(quote.regularMarketPrice)")

// 과거 가격 데이터 조회
let history = try await client.fetchHistory(ticker: ticker, period: .oneMonth)
print("지난 30일간 \(history.prices.count)개의 데이터")

// 재무제표 조회
let financials = try await client.fetchFinancials(ticker: ticker)
for report in financials.annualReports {
    print("매출: \(report.totalRevenue / 1_000_000_000)B")
}
```

## 설치

### Swift Package Manager

Package.swift에 다음을 추가:

```swift
dependencies: [
    .package(url: "https://github.com/your-org/SwiftYFinance.git", from: "1.0.0")
]
```

### Xcode

1. File → Add Package Dependencies...
2. `https://github.com/your-org/SwiftYFinance.git` 입력
3. 최신 버전 선택

## 라이선스

SwiftYFinance는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 LICENSE 파일을 참조하세요.

## 기여

프로젝트에 기여하고 싶으시면 GitHub Issues나 Pull Request를 통해 참여해주세요. 모든 기여를 환영합니다!

## 지원

- **GitHub Issues**: 버그 리포트 및 기능 요청
- **Documentation**: 이 문서를 통한 API 레퍼런스
- **Examples**: 샘플 코드와 사용 예제

---

*SwiftYFinance는 Yahoo Finance API를 사용하여 금융 데이터를 제공합니다. 실제 거래나 투자 결정에 사용하기 전에 데이터의 정확성을 반드시 확인하시기 바랍니다.*