# ``SwiftYFinance``

Production-Ready Yahoo Finance API Swift Library

## Overview

SwiftYFinance는 **완전한 production-ready** Swift 라이브러리로, Python yfinance의 100% 기능 호환성을 제공합니다. **128개의 검증된 테스트 (100% 성공률)**, Chrome 136 브라우저 위장 기술, 실시간 WebSocket 스트리밍을 통해 Yahoo Finance API의 모든 기능을 안정적으로 활용할 수 있습니다.

### 🎉 Production Ready Status
- ✅ **128개 테스트** - 100% 성공률로 모든 기능 검증 완료
- ✅ **11개 CLI 명령어** - 완전한 명령줄 인터페이스 제공
- ✅ **Chrome 136 위장** - 고급 브라우저 모방 기술로 안정적 API 접근
- ✅ **실시간 스트리밍** - WebSocket 기반 실시간 데이터 수신
- ✅ **9개 전문 서비스** - 계층화된 아키텍처로 확장 가능한 설계

### 주요 기능

- **실시간 시세**: 주식, ETF, 암호화폐 등의 실시간 가격 정보
- **과거 가격 데이터**: 다양한 기간과 간격의 OHLCV 데이터
- **재무제표**: 손익계산서, 대차대조표, 현금흐름표
- **옵션 거래**: 옵션 체인, Greeks, 만료일 분석
- **기술적 분석**: SMA, EMA, RSI, MACD, 볼린저밴드 등
- **뉴스 & 감성분석**: 종목 관련 뉴스와 AI 감성 분석
- **종목 스크리닝**: 복합 조건 기반 종목 검색
- **실시간 스트리밍**: WebSocket 기반 실시간 가격 데이터

### Swift의 장점

- **타입 안전성**: 컴파일 타임에 에러 발견
- **Async/Await**: 현대적인 비동기 프로그래밍
- **동시성 안전성**: Actor 모델을 통한 데이터 레이스 방지
- **메모리 안전성**: ARC를 통한 자동 메모리 관리
- **성능**: 네이티브 코드의 빠른 실행 속도
- **멀티플랫폼**: iOS, macOS, tvOS, watchOS 지원

## Topics

### Essentials

라이브러리를 시작하고 기본 기능을 익히기 위한 필수 가이드입니다.

- <doc:GettingStarted>
- <doc:BasicUsage>
- <doc:Authentication>
- <doc:CLI>

### Architecture & Services

SwiftYFinance의 계층화된 아키텍처와 서비스 레이어입니다.

- <doc:Architecture>
- ``YFClient`` - 메인 클라이언트 API
- ``YFService`` - 기본 서비스 프로토콜
- ``YFQuoteService`` - 실시간 시세 서비스
- ``YFChartService`` - 차트 데이터 서비스
- ``YFSearchService`` - 종목 검색 서비스
- ``YFFundamentalsTimeseriesService`` - 재무제표 서비스
- ``YFNewsService`` - 뉴스 데이터 서비스
- ``YFOptionsService`` - 옵션 데이터 서비스
- ``YFScreenerService`` - 종목 스크리닝 서비스

### Core API

SwiftYFinance의 핵심 클래스와 인터페이스입니다.

- ``YFTicker`` - 종목 심볼 표현
- ``YFError`` - 에러 정의

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

#### Real-time Streaming
- ``YFWebSocketManager``
- ``YFWebSocketConnectionState``
- ``YFWebSocketInternalState``

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

### CLI로 빠른 시작 (권장)

가장 빠른 방법은 CLI 도구를 사용하는 것입니다:

```bash
# CLI 빌드 및 실행
cd CLI
swift run swiftyfinance quote AAPL

# 결과 예시:
# AAPL: $150.25 (+1.5%) Vol: 65.2M Cap: $2.4T
```

### Swift 코드로 시작하기

```swift
import SwiftYFinance

// 1. 메인 클라이언트를 통한 기본 사용 (단순한 경우)
let client = YFClient()
let ticker = YFTicker(symbol: "AAPL")
let quote = try await client.fetchQuote(ticker: ticker)
print("현재 가격: \(quote.regularMarketPrice)")

// 2. 서비스 레이어를 통한 고급 사용 (권장)
let quoteService = YFQuoteService()
let quotes = try await quoteService.fetchQuotes(symbols: ["AAPL", "GOOGL", "MSFT"])
quotes.forEach { symbol, quote in
    print("\(symbol): $\(quote.regularMarketPrice)")
}

// 3. 전문 서비스별 고급 기능 활용
let chartService = YFChartService()
let historyData = try await chartService.fetchHistory(
    ticker: ticker, 
    period: .oneMonth,
    interval: .oneDay
)

let newsService = YFNewsService()
let news = try await newsService.fetchNews(ticker: ticker, limit: 5)

// 4. 실시간 WebSocket 스트리밍
let webSocket = YFWebSocketManager()
try await webSocket.connect()
try await webSocket.subscribe(symbols: ["AAPL"])

for await priceUpdate in webSocket.priceStream {
    print("실시간: \(priceUpdate.symbol) $\(priceUpdate.price)")
}
```

### 아키텍처 개요

SwiftYFinance는 5단계 계층화된 아키텍처로 구성되어 있습니다:

```
YFClient (메인 API)
    ↓
Services Layer (9개 전문 서비스)
    ↓
API Builders (10개 URL 빌더)
    ↓
Network Layer (브라우저 위장 + 인증)
    ↓
Models Layer (타입 안전한 데이터 모델)
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