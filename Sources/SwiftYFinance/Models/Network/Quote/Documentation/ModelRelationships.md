# Quote Models Relationship Diagram

Quote 모델들 간의 관계와 데이터 흐름을 시각화한 문서입니다.

## 📊 전체 아키텍처 다이어그램

```
┌─────────────────────────────────────────────────────────────┐
│                    Yahoo Finance API                        │
└─────────────────────┬───────────────────────────────────────┘
                     │ HTTP Response
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                ResponseWrappers/                            │
├─────────────────────────────────────────────────────────────┤
│  YFQuoteSummaryResponse                                     │
│  ├── quoteSummary: YFQuoteSummary                          │
│      └── result: [YFQuoteResult]                           │
│                                                             │
│  YFQuoteResponse                                            │
│  ├── result: [YFQuote]                                     │
│  └── error: String?                                        │
└─────────────────────┬───────────────────────────────────────┘
                     │ Parsed Data
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                CompositeModels/                             │
├─────────────────────────────────────────────────────────────┤
│  YFQuoteResult                                              │
│  ├── price: YFQuote ────────────────────┐                  │
│  └── summaryDetail: YFQuoteSummaryDetail│                  │
│                                        │                  │
│  YFQuoteSummaryDetail                  │                  │
│  └── [150+ detailed fields]           │                  │
└────────────────────────────────────────┼───────────────────┘
                                        │
                     ┌──────────────────┘
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                     Core/                                   │
├─────────────────────────────────────────────────────────────┤
│  YFQuote (Main Model)                                       │
│  ├── basicInfo: YFQuoteBasicInfo ──────────┐               │
│  ├── exchangeInfo: YFQuoteExchangeInfo ────┼─┐             │
│  ├── marketData: YFQuoteMarketData ────────┼─┼─┐           │
│  ├── volumeInfo: YFQuoteVolumeInfo ────────┼─┼─┼─┐         │
│  ├── extendedHours: YFQuoteExtendedHours ──┼─┼─┼─┼─┐       │
│  └── metadata: YFQuoteMetadata ────────────┼─┼─┼─┼─┼─┐     │
│                                           │ │ │ │ │ │     │
│  YFQuote+Extensions                       │ │ │ │ │ │     │
│  ├── essentialData (computed)              │ │ │ │ │ │     │
│  ├── currentPrice (computed)               │ │ │ │ │ │     │
│  └── lastUpdateTime (computed)             │ │ │ │ │ │     │
└───────────────────────────────────────────┼─┼─┼─┼─┼─┼─────┘
                                           │ │ │ │ │ │
                     ┌─────────────────────┘ │ │ │ │ │
                     ▼                       │ │ │ │ │
┌─────────────────────────────────────────────┼─┼─┼─┼─┼─────┐
│              ModularComponents/             │ │ │ │ │     │
├─────────────────────────────────────────────┼─┼─┼─┼─┼─────┤
│  YFQuoteBasicInfo ◄─────────────────────────┘ │ │ │ │     │
│  ├── symbol: String?                          │ │ │ │     │
│  ├── longName: String?                        │ │ │ │     │
│  └── shortName: String?                       │ │ │ │     │
│                                               │ │ │ │     │
│  YFQuoteExchangeInfo ◄────────────────────────┘ │ │ │     │
│  ├── exchange: String?                          │ │ │     │
│  ├── currency: String?                          │ │ │     │
│  └── exchangeName: String?                      │ │ │     │
│                                                 │ │ │     │
│  YFQuoteMarketData ◄────────────────────────────┘ │ │     │
│  ├── regularMarketPrice: Double?                  │ │     │
│  ├── regularMarketChange: Double?                 │ │     │
│  └── regularMarketChangePercent: Double?          │ │     │
│                                                   │ │     │
│  YFQuoteVolumeInfo ◄──────────────────────────────┘ │     │
│  ├── regularMarketVolume: Int?                      │     │
│  ├── marketCap: Double?                             │     │
│  └── marketState: String?                           │     │
│                                                     │     │
│  YFQuoteExtendedHoursData ◄─────────────────────────┘     │
│  ├── preMarketPrice: Double?                              │
│  ├── postMarketPrice: Double?                             │
│  └── preMarket/postMarket change data                     │
│                                                           │
│  YFQuoteMetadata ◄────────────────────────────────────────┘
│  ├── regularMarketTime: Int?                              │
│  ├── maxAge: Int?                                         │
│  └── quoteSourceName: String?                             │
└───────────────────────────────────────────────────────────┘
```

## 🔄 데이터 흐름

### 1. API → Response Wrappers
```
Yahoo Finance API
    ↓ HTTP JSON Response
YFQuoteResponse/YFQuoteSummaryResponse
    ↓ Custom Decoding
Parsed Structure
```

### 2. Response Wrappers → Core/Composite
```
YFQuoteResponse.result: [YFQuote]
    ↓ Array Element
YFQuote (Core Model)

YFQuoteSummary.result: [YFQuoteResult]  
    ↓ Array Element
YFQuoteResult.price: YFQuote + YFQuoteResult.summaryDetail
```

### 3. Core → Modular Components
```
YFQuote.init(from decoder: Decoder)
    ├── YFQuoteBasicInfo(from: decoder)
    ├── YFQuoteExchangeInfo(from: decoder)
    ├── YFQuoteMarketData(from: decoder)
    ├── YFQuoteVolumeInfo(from: decoder)
    ├── YFQuoteExtendedHoursData(from: decoder)
    └── YFQuoteMetadata(from: decoder)
```

## 🎯 계층별 책임

| 계층 | 책임 | 특징 |
|------|------|------|
| **ResponseWrappers** | API 응답 매핑 | JSON 구조 대응, 에러 처리 |
| **CompositeModels** | 데이터 조합 | 비즈니스 로직, 복합 정보 |
| **Core** | 메인 모델 | 통합 인터페이스, 확장 기능 |
| **ModularComponents** | 원자적 데이터 | 단일 책임, 재사용성 |

## 🚀 사용 패턴

### Pattern 1: Direct API Response
```swift
let response: YFQuoteResponse = try await api.fetchQuote()
let quotes = response.result ?? []
```

### Pattern 2: Modular Access
```swift
let quote: YFQuote = quotes.first!
print("Symbol: \(quote.basicInfo.symbol)")
print("Price: \(quote.marketData.regularMarketPrice)")
```

### Pattern 3: Smart Extensions
```swift
let currentPrice = quote.currentPrice // 시장 상태별 자동 선택
let updateTime = quote.lastUpdateTime // Date 변환
```