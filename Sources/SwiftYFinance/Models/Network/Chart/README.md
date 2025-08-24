# Chart Models

차트 및 과거 가격 데이터를 위한 응답 모델들입니다.

## 📋 포함된 모델

- **`YFHistoricalData`** - 과거 OHLCV 가격 데이터
- **`YFChartModels`** - 차트 응답 구조 및 메타데이터

## 🎯 사용 용도

- 과거 주가 데이터 조회
- 차트 그리기용 데이터
- 기술적 분석 데이터
- 가격 변동 추세 분석

## ✨ 핵심 기능

```swift
let history = try await client.chart.fetch(
    ticker: ticker, 
    period: .oneMonth
)

// 가격 데이터 접근
for price in history.prices {
    print("\(price.date): O:\(price.open) H:\(price.high) L:\(price.low) C:\(price.close)")
}

// 통계 정보
let totalVolume = history.prices.reduce(0) { $0 + $1.volume }
let avgPrice = history.prices.map(\.close).reduce(0, +) / Double(history.prices.count)
```