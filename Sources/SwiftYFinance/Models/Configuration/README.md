# Configuration

API 호출 설정 및 쿼리 구성을 위한 설정 모델들을 정의합니다.

## 📋 포함된 모델

### API Configuration
- **`YFDomain`** - 섹터, 산업, 시장 도메인 타입 정의 (11개 섹터, 9개 시장)
- **`YFQuoteSummaryModule`** - QuoteSummary API의 60개 모듈 정의
- **`YFSearchQuery`** - 검색 쿼리 파라미터 구성

## 🎯 목적

Yahoo Finance API 호출에 필요한 설정과 파라미터를 관리합니다.

## ✨ 특징

- **포괄적 지원**: Python yfinance와 100% 호환성
- **타입 안전성**: enum을 활용한 컴파일 타임 검증
- **편의 기능**: 자주 사용되는 모듈 조합 미리 정의
- **유효성 검사**: 쿼리 파라미터 자동 검증

## 📖 사용 예시

```swift
// 도메인 검색
let techSector = YFSector.technology
print(techSector.displayName) // "기술"

// QuoteSummary 모듈 설정
let modules = YFQuoteSummaryModule.essential
// [summaryDetail, financialData, defaultKeyStatistics, price, quoteType]

// 검색 쿼리 구성
let query = YFSearchQuery(
    term: "Apple",
    maxResults: 20,
    quoteTypes: [.equity, .etf]
)

// 복합 모듈 설정
let comprehensive = YFQuoteSummaryModule.comprehensive
// 포괄적 분석용 모듈들
```

## 🔧 설정 카테고리

- **Domain Types**: 섹터/산업/시장 분류
- **API Modules**: QuoteSummary API 모듈 선택
- **Query Parameters**: 검색 및 필터 조건