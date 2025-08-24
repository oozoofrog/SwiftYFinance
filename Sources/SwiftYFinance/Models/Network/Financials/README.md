# Financials Models

재무 데이터 응답을 위한 모델들입니다.

## 📋 포함된 모델

- **`YFBalanceSheetResponse`** - 대차대조표 API 응답
- **`YFFundamentalsTimeseriesResponse`** - 재무 시계열 데이터 응답

## 🎯 사용 용도

- 재무제표 원시 데이터
- 시계열 재무 지표
- API 응답 파싱 및 변환

## ✨ 핵심 기능

```swift
let balanceSheet = try await client.financials.fetchBalanceSheet(ticker: ticker)

// 최신 대차대조표
let latest = balanceSheet.balanceSheetHistory?.first
print("총자산: $\(latest?.totalAssets ?? 0)")
print("총부채: $\(latest?.totalLiab ?? 0)")

// 시계열 데이터
let timeseries = try await client.financials.fetchTimeseries(ticker: ticker)
for data in timeseries.timeseries {
    print("기간: \(data.asOfDate) - 매출: $\(data.reportedValue)")
}
```