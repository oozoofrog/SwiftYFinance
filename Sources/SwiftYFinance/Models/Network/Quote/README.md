# Quote Models

실시간 주식 시세 데이터를 위한 계층적 모델 구조입니다.

## 📁 폴더 구조

```
Quote/
├── ResponseWrappers/     # API 응답 래퍼들
├── CompositeModels/      # 복합 데이터 컨테이너
├── ModularComponents/    # 원자적 모듈 구성요소
├── Core/                # 메인 모델 & 확장
└── Documentation/       # 관계도 & 사용법
```

## 🏗️ 아키텍처 개요

### 1. ResponseWrappers/
Yahoo Finance API 응답을 직접 매핑하는 최상위 래퍼들
- `YFQuoteSummaryResponse` - quoteSummary API 래퍼
- `YFQuoteResponse` - query1 API 래퍼 (custom decoding)
- `YFQuoteSummary` - API 데이터 컨테이너

### 2. CompositeModels/
여러 데이터 소스를 조합한 복합 모델들
- `YFQuoteResult` - price + summaryDetail 조합
- `YFQuoteSummaryDetail` - 상세 재무/거래 지표

### 3. ModularComponents/
단일 책임 원칙을 따르는 원자적 모델들
- `YFQuoteBasicInfo` - 종목 식별 정보
- `YFQuoteMarketData` - 실시간 시세 데이터
- `YFQuoteVolumeInfo` - 거래량/시장 상태
- `YFQuoteExtendedHoursData` - 장전/장후 거래
- `YFQuoteExchangeInfo` - 거래소/통화 정보  
- `YFQuoteMetadata` - 시간/출처 메타데이터

### 4. Core/
메인 모델과 확장 기능
- `YFQuote` - 모든 ModularComponent 통합
- `YFQuote+Extensions` - 편의 기능 & 계산된 속성

## ✨ 핵심 기능

### 모듈형 접근
```swift
let quote = try await client.quote.fetch(ticker: ticker)

// 도메인별 데이터 접근
print("회사명: \(quote.basicInfo.longName ?? "")")
print("현재가: $\(quote.marketData.regularMarketPrice ?? 0)")  
print("거래량: \(quote.volumeInfo.regularMarketVolume ?? 0)")
```

### 스마트 확장 기능
```swift
// 시장 상태별 자동 가격 선택
let currentPrice = quote.currentPrice
let changePercent = quote.currentChangePercent

// 핵심 데이터 간편 추출
let (symbol, price, change, changePercent) = quote.essentialData
```

## 📖 자세한 정보

- **[모델 관계도](Documentation/ModelRelationships.md)** - 전체 아키텍처 다이어그램
- **[사용 예제](Documentation/UsageExamples.md)** - 실제 코드 예제 및 패턴
- 각 폴더의 README.md - 세부 모델 설명