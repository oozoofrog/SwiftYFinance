# Screener

복잡한 스크리너 쿼리 구성을 위한 전용 모델들을 정의합니다.

## 📋 포함된 모델

### Query System
- **`YFScreenerQuery`** - 스크리너 쿼리 핵심 구조
- **`YFScreenerOperator`** - 쿼리 연산자 (EQ, GT, LT, BETWEEN 등)
- **`YFScreenerValue`** - 쿼리 값 타입 (문자열, 숫자, 중첩 쿼리)
- **`YFScreenerCondition`** - 개별 조건 정의
- **`YFScreenerQueryProtocol`** - 쿼리 프로토콜

## 🎯 목적

Yahoo Finance Screener API를 위한 복잡한 논리 연산과 조건 조합을 처리합니다.

## ✨ 특징

- **복잡한 논리**: AND, OR, 범위, 포함 등 다양한 연산 지원
- **Python 호환**: yfinance QueryBase와 동일한 구조
- **타입 안전성**: enum 기반 연산자 및 값 타입
- **편의 메서드**: 자주 사용되는 조건들 미리 정의

## 📖 사용 예시

```swift
// 기본 조건
let largeCap = YFScreenerQuery.gte("marketCap", 10_000_000_000)
let technology = YFScreenerQuery.eq("sector", "Technology")
let lowPE = YFScreenerQuery.lte("peRatio", 15.0)

// 복합 조건 (AND 연산)
let techLargeCaps = YFScreenerQuery.and([
    technology,
    largeCap,
    lowPE
])

// 범위 조건
let priceRange = YFScreenerQuery.between(
    "intradayprice", 
    min: 50.0, 
    max: 200.0
)

// 미리 정의된 조건들
let conditions = [
    YFScreenerQuery.usEquities,      // 미국 주식
    YFScreenerQuery.largeCap,        // 대형주
    YFScreenerQuery.technology,      // 기술주
    YFScreenerQuery.highVolume       // 고거래량
]

let query = YFScreenerQuery.and(conditions)

// JSON 변환
let jsonData = try query.toJSONData()
```

## 🔍 지원 조건

- **가격**: 주가, 변동률, 52주 최고/최저가
- **규모**: 시가총액, 거래량, 평균 거래량
- **밸류에이션**: PER, PBR, PSR, PEG 비율
- **수익성**: ROE, ROA, 영업이익률
- **분류**: 섹터, 지역, 거래소