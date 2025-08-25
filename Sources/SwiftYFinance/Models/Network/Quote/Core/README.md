# Core Models

메인 YFQuote 모델과 확장 기능을 포함하는 핵심 모델들입니다.

## 📋 포함된 모델

### YFQuote
- **역할**: 모든 ModularComponents를 통합한 완전한 Quote 객체
- **구성**: 6개의 ModularComponent 통합
  - basicInfo: YFQuoteBasicInfo
  - exchangeInfo: YFQuoteExchangeInfo  
  - marketData: YFQuoteMarketData
  - volumeInfo: YFQuoteVolumeInfo
  - extendedHours: YFQuoteExtendedHoursData
  - metadata: YFQuoteMetadata
- **특징**: Custom Decoding으로 단일 JSON에서 모든 모듈 생성

### YFQuote+Extensions  
- **역할**: YFQuote의 편의 기능 및 계산된 속성
- **제공 기능**:
  - `essentialData`: 핵심 시세 데이터 튜플
  - `currentPrice`: 시장 상태별 적절한 가격
  - `currentChangePercent`: 시간대별 변동률
  - `lastUpdateTime`: 최신 업데이트 시간

## 🏗️ 아키텍처

### Composition Pattern
```
YFQuote (Composite Root)
├── basicInfo: YFQuoteBasicInfo
├── exchangeInfo: YFQuoteExchangeInfo
├── marketData: YFQuoteMarketData
├── volumeInfo: YFQuoteVolumeInfo  
├── extendedHours: YFQuoteExtendedHoursData
└── metadata: YFQuoteMetadata
```

### Custom Decoding Strategy
```swift
public init(from decoder: Decoder) throws {
    // 같은 decoder를 사용하여 각 모듈을 독립적으로 디코딩
    self.basicInfo = try YFQuoteBasicInfo(from: decoder)
    self.exchangeInfo = try YFQuoteExchangeInfo(from: decoder)
    self.marketData = try YFQuoteMarketData(from: decoder)
    self.volumeInfo = try YFQuoteVolumeInfo(from: decoder)
    self.extendedHours = try YFQuoteExtendedHoursData(from: decoder)
    self.metadata = try YFQuoteMetadata(from: decoder)
}
```

## ✨ 핵심 기능

### 모듈별 접근
```swift
let quote: YFQuote = ...

// 도메인별 데이터 접근
print("회사명: \(quote.basicInfo.longName ?? "")")
print("현재가: $\(quote.marketData.regularMarketPrice ?? 0)")
print("거래량: \(quote.volumeInfo.regularMarketVolume ?? 0)")
```

### 스마트 계산 속성
```swift
// 시장 상태에 따른 적절한 가격 자동 선택
let currentPrice = quote.currentPrice
// PRE 시장: preMarketPrice 우선
// POST 시장: postMarketPrice 우선  
// REGULAR: regularMarketPrice
```

### 간소화된 접근
```swift
// 핵심 데이터만 빠르게 추출
let (symbol, price, change, changePercent) = quote.essentialData
```

## 🔗 의존성

- **의존 대상**: ModularComponents의 모든 6개 모델
- **의존 방향**: Core → ModularComponents (단방향)
- **결합도**: 컴파일 타임에만 결합, 런타임 독립성 유지