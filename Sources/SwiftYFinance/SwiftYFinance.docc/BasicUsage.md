# Basic Usage

SwiftYFinance의 핵심 기능들을 사용하는 방법

## Overview

이 가이드에서는 SwiftYFinance의 주요 기능들을 실제 예제와 함께 설명합니다. 실시간 시세, 과거 데이터, 재무제표 등 다양한 금융 데이터를 가져오는 방법을 배워보겠습니다.

## Real-time Quotes

현재 주식 시세를 가져오는 것은 가장 기본적인 기능입니다:

```swift
import SwiftYFinance

let client = YFClient()
let ticker = try YFTicker(symbol: "AAPL")

let quote = try await client.fetchQuote(ticker: ticker)

print("현재 가격: $\(quote.regularMarketPrice)")
print("변동: $\(quote.regularMarketChange ?? 0) (\(quote.regularMarketChangePercent ?? 0)%)")
print("시가: $\(quote.regularMarketOpen ?? 0)")
print("고가: $\(quote.regularMarketDayHigh ?? 0)")
print("저가: $\(quote.regularMarketDayLow ?? 0)")
print("거래량: \(quote.regularMarketVolume ?? 0)")
print("시가총액: $\(quote.marketCap ?? 0)")
```

### Extended Hours Trading

장외 시간 거래 정보도 가져올 수 있습니다:

```swift
let quote = try await client.fetchQuote(ticker: ticker)

// 장전 거래 (Pre-market)
if let preMarketPrice = quote.preMarketPrice,
   let preMarketChange = quote.preMarketChangePercent {
    print("장전 거래: $\(preMarketPrice) (\(preMarketChange)%)")
}

// 장후 거래 (After-hours)
if let postMarketPrice = quote.postMarketPrice,
   let postMarketChange = quote.postMarketChangePercent {
    print("장후 거래: $\(postMarketPrice) (\(postMarketChange)%)")
}
```

## Historical Data

과거 가격 데이터를 다양한 기간과 간격으로 가져올 수 있습니다:

### 기본 사용법

```swift
let ticker = try YFTicker(symbol: "AAPL")

// 지난 1개월 일별 데이터
let history = try await client.fetchHistory(ticker: ticker, period: .oneMonth)

print("총 \(history.prices.count)개의 데이터")

// 최근 5일 데이터 출력
for price in history.prices.prefix(5) {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    
    print("\(formatter.string(from: price.date)): $\(price.close)")
    print("  시가: $\(price.open), 고가: $\(price.high), 저가: $\(price.low)")
    print("  거래량: \(price.volume)")
    print("---")
}
```

### 커스텀 기간 설정

```swift
let calendar = Calendar.current
let endDate = Date()
let startDate = calendar.date(byAdding: .year, value: -1, to: endDate)!

let yearlyHistory = try await client.fetchHistory(
    ticker: ticker,
    startDate: startDate,
    endDate: endDate,
    interval: .oneDay
)

print("1년간 \(yearlyHistory.prices.count)일의 데이터")
```

### 인트라데이 데이터

분 단위 데이터도 가져올 수 있습니다:

```swift
// 지난 5일간의 5분 간격 데이터
let intradayHistory = try await client.fetchHistory(
    ticker: ticker,
    period: .fiveDays,
    interval: .fiveMinutes
)

print("5분 간격 데이터: \(intradayHistory.prices.count)개")

// 오늘의 첫 거래와 마지막 거래
if let firstTrade = intradayHistory.prices.first,
   let lastTrade = intradayHistory.prices.last {
    print("첫 거래: \(firstTrade.date) - $\(firstTrade.open)")
    print("마지막 거래: \(lastTrade.date) - $\(lastTrade.close)")
}
```

## Financial Statements

재무제표 데이터를 가져올 수 있습니다:

### 손익계산서

```swift
let financials = try await client.fetchFinancials(ticker: ticker)

print("=== \(ticker.symbol) 손익계산서 ===")

for (index, report) in financials.annualReports.enumerated() {
    let year = Calendar.current.component(.year, from: report.reportDate)
    
    print("\n\(year)년:")
    print("매출: $\(report.totalRevenue / 1_000_000_000)B")
    print("영업이익: $\(report.operatingIncome / 1_000_000_000)B")
    print("순이익: $\(report.netIncome / 1_000_000_000)B")
    print("EPS: $\(report.earningsPerShare)")
    
    if index >= 2 { break } // 최근 3년만 출력
}
```

### 대차대조표

```swift
let balanceSheet = try await client.fetchBalanceSheet(ticker: ticker)

for report in balanceSheet.annualReports.prefix(3) {
    let year = Calendar.current.component(.year, from: report.reportDate)
    
    print("\n\(year)년 대차대조표:")
    print("총 자산: $\(report.totalAssets! / 1_000_000_000)B")
    print("총 부채: $\(report.totalLiabilities! / 1_000_000_000)B")
    print("자기자본: $\(report.totalStockholderEquity / 1_000_000_000)B")
    
    let debtRatio = Double(report.totalLiabilities!) / Double(report.totalAssets!)
    print("부채비율: \(String(format: "%.1f", debtRatio * 100))%")
}
```

### 현금흐름표

```swift
let cashFlow = try await client.fetchCashFlow(ticker: ticker)

for report in cashFlow.annualReports.prefix(3) {
    let year = Calendar.current.component(.year, from: report.reportDate)
    
    print("\n\(year)년 현금흐름:")
    print("영업 현금흐름: $\(report.operatingCashFlow / 1_000_000_000)B")
    if let freeCashFlow = report.freeCashFlow {
        print("잉여 현금흐름: $\(freeCashFlow / 1_000_000_000)B")
    }
    if let capex = report.capitalExpenditure {
        print("자본 지출: $\(abs(capex) / 1_000_000_000)B")
    }
}
```

## Multiple Symbols

여러 종목을 동시에 조회할 때는 적절한 딜레이를 추가하세요:

```swift
let symbols = ["AAPL", "GOOGL", "MSFT", "AMZN", "TSLA"]
var quotes: [String: YFQuote] = [:]

for symbolString in symbols {
    do {
        let ticker = try YFTicker(symbol: symbolString)
        let quote = try await client.fetchQuote(ticker: ticker)
        quotes[symbolString] = quote
        
        print("\(symbolString): $\(quote.regularMarketPrice)")
        
        // Rate limiting을 위한 딜레이
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2초
        
    } catch {
        print("\(symbolString) 조회 실패: \(error)")
    }
}
```

## Different Asset Types

SwiftYFinance는 다양한 자산 타입을 지원합니다:

### ETF

```swift
let etf = try YFTicker(symbol: "SPY") // S&P 500 ETF
let etfQuote = try await client.fetchQuote(ticker: etf)

print("SPY ETF: $\(etfQuote.regularMarketPrice)")
print("52주 최고가: $\(etfQuote.fiftyTwoWeekHigh ?? 0)")
print("52주 최저가: $\(etfQuote.fiftyTwoWeekLow ?? 0)")
```

### 암호화폐

```swift
let bitcoin = try YFTicker(symbol: "BTC-USD")
let bitcoinQuote = try await client.fetchQuote(ticker: bitcoin)

print("Bitcoin: $\(bitcoinQuote.regularMarketPrice)")
```

### 통화

```swift
let usdKrw = try YFTicker(symbol: "USDKRW=X")
let exchangeRate = try await client.fetchQuote(ticker: usdKrw)

print("USD/KRW: \(exchangeRate.regularMarketPrice)")
```

### 원자재

```swift
let gold = try YFTicker(symbol: "GC=F") // Gold Futures
let goldQuote = try await client.fetchQuote(ticker: gold)

print("Gold: $\(goldQuote.regularMarketPrice)")
```

## Error Handling Best Practices

실제 애플리케이션에서는 다양한 에러 상황을 적절히 처리해야 합니다:

```swift
func fetchQuoteSafely(symbol: String) async -> YFQuote? {
    do {
        let ticker = try YFTicker(symbol: symbol)
        let quote = try await client.fetchQuote(ticker: ticker)
        return quote
        
    } catch YFError.invalidSymbol {
        print("❌ 잘못된 종목 심볼: \(symbol)")
        return nil
        
    } catch YFError.rateLimited {
        print("⏰ Rate limit 도달. 5초 후 재시도...")
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        return await fetchQuoteSafely(symbol: symbol)
        
    } catch YFError.networkError {
        print("🌐 네트워크 에러. 연결을 확인해주세요.")
        return nil
        
    } catch {
        print("❓ 알 수 없는 에러: \(error)")
        return nil
    }
}

// 사용 예제
if let quote = await fetchQuoteSafely(symbol: "AAPL") {
    print("Apple 가격: $\(quote.regularMarketPrice)")
} else {
    print("Apple 데이터를 가져올 수 없습니다.")
}
```

## Performance Tips

### 1. 적절한 딜레이 사용

```swift
// 좋은 예
for symbol in symbols {
    let quote = try await fetchQuote(symbol)
    // 처리...
    try await Task.sleep(nanoseconds: 200_000_000) // 0.2초
}
```

### 2. 병렬 처리 (주의해서 사용)

```swift
// 소수의 요청에만 사용
let symbols = ["AAPL", "GOOGL", "MSFT"]

await withTaskGroup(of: (String, YFQuote?).self) { group in
    for symbol in symbols {
        group.addTask {
            let quote = await fetchQuoteSafely(symbol: symbol)
            return (symbol, quote)
        }
    }
    
    for await (symbol, quote) in group {
        if let quote = quote {
            print("\(symbol): $\(quote.regularMarketPrice)")
        }
    }
}
```

### 3. 데이터 캐싱

자주 사용하는 데이터는 로컬에 캐싱하여 API 호출을 줄이세요:

```swift
class QuoteCache {
    private var cache: [String: (quote: YFQuote, timestamp: Date)] = [:]
    private let cacheTimeout: TimeInterval = 60 // 1분
    
    func getCachedQuote(symbol: String) -> YFQuote? {
        if let cached = cache[symbol],
           Date().timeIntervalSince(cached.timestamp) < cacheTimeout {
            return cached.quote
        }
        return nil
    }
    
    func setCachedQuote(symbol: String, quote: YFQuote) {
        cache[symbol] = (quote, Date())
    }
}
```

## Next Steps

기본 사용법을 익혔다면 다음 가이드들을 확인해보세요:

- <doc:Authentication> - 고급 인증 및 설정
- <doc:AdvancedFeatures> - 옵션, 기술적 분석, 뉴스 등
- <doc:BestPractices> - 모범 사례 및 성능 최적화