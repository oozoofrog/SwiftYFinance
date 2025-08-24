# Business

비즈니스 도메인별 핵심 데이터 모델들을 정의합니다.

## 📋 포함된 모델

### Financial Models
- **`YFFinancials`** - 종합 재무제표 (연간/분기별 리포트)
- **`YFBalanceSheet`** - 대차대조표 (자산, 부채, 자본)
- **`YFCashFlow`** - 현금흐름표 (영업, 투자, 재무 활동)
- **`YFEarnings`** - 실적 데이터 (매출, 순이익, EPS)
- **`YFFinancialsAdvanced`** - 고급 재무 지표 (비율, 성장률)
- **`YFTechnicalIndicators`** - 기술적 지표 (이동평균, RSI, MACD)

## 🎯 목적

순수한 비즈니스 로직 데이터를 API 응답과 분리하여 관리합니다.

## ✨ 특징

- **도메인 중심**: 금융 분석에 필요한 핵심 개념 모델링
- **구조화된 데이터**: 연간/분기별 시계열 데이터 지원
- **계산된 지표**: 파생 지표 자동 계산 기능
- **분석 친화적**: 투자 분석 워크플로우 최적화

## 📖 사용 예시

```swift
// 종합 재무 분석
let client = YFClient()
let ticker = YFTicker(symbol: "AAPL")

// 재무제표 조회
let financials = try await client.fetchFinancials(ticker: ticker)

// 연간 수익 추이 분석
for report in financials.annualReports.prefix(3) {
    let year = Calendar.current.component(.year, from: report.reportDate)
    let revenueB = report.totalRevenue / 1_000_000_000
    let netIncomeB = report.netIncome / 1_000_000_000
    
    print("\(year): 매출 $\(revenueB)B, 순이익 $\(netIncomeB)B")
}

// 재무 비율 계산
let latestReport = financials.annualReports.first!
let roa = latestReport.netIncome / latestReport.totalAssets * 100
let debtRatio = latestReport.totalLiabilities / latestReport.totalAssets * 100

print("ROA: \(String(format: "%.2f", roa))%")
print("부채비율: \(String(format: "%.2f", debtRatio))%")

// 기술적 지표 분석
let indicators = try await client.fetchTechnicalIndicators(ticker: ticker)
if let sma20 = indicators.sma20,
   let currentPrice = indicators.currentPrice {
    let trend = currentPrice > sma20 ? "상승" : "하락"
    print("20일 이평선 대비 \(trend) 추세")
}
```

## 💡 분석 활용

- **재무 건전성**: 부채비율, 유동비율, 자기자본비율
- **수익성 분석**: ROE, ROA, 영업이익률, 순이익률  
- **성장성 평가**: 매출성장률, 이익성장률, 자산성장률
- **기술적 분석**: 추세, 모멘텀, 변동성 지표