# Screening Models

스크리너 결과 데이터를 위한 응답 모델들입니다.

## 📋 포함된 모델

- **`YFScreenResult`** - 스크리너 검색 결과
- **`YFCustomScreenerResponse`** - 커스텀 스크리너 응답

## 🎯 사용 용도

- 조건부 종목 검색 결과
- 대량 종목 필터링
- 투자 전략별 종목 선별

## ✨ 핵심 기능

```swift
// 미국 기술주 대형주 검색
let query = YFScreenerQuery.and([
    .usEquities,
    .technology, 
    .largeCap
])

let results = try await client.screener.fetch(query: query)

for stock in results {
    print("심볼: \(stock.symbol)")
    print("시가총액: $\(stock.marketCap ?? 0)")
    print("PER: \(stock.peRatio ?? 0)")
}
```