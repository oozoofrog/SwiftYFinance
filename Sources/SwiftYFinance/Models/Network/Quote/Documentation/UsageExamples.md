# Quote Models Usage Examples

Quote 모델들의 실제 사용 예제와 패턴을 제공합니다.

## 🚀 기본 사용법

### 1. API 호출 및 응답 처리

```swift
import SwiftYFinance

// Quote Service 사용
let quoteService = YFQuoteService()
let ticker = YFTicker(symbol: "AAPL")

do {
    let response = try await quoteService.fetch(ticker: ticker)
    
    // 응답 검증
    guard let quotes = response.result, !quotes.isEmpty else {
        if let error = response.error {
            print("API Error: \(error)")
        }
        return
    }
    
    let quote = quotes[0]
    // quote 사용...
    
} catch {
    print("Request failed: \(error)")
}
```

### 2. 모듈별 데이터 접근

```swift
func displayQuoteInfo(_ quote: YFQuote) {
    // 기본 정보 모듈
    if let basicInfo = quote.basicInfo {
        print("=== 기본 정보 ===")
        print("심볼: \(basicInfo.symbol ?? "N/A")")
        print("회사명: \(basicInfo.longName ?? "N/A")")
        print("종목 타입: \(basicInfo.quoteType ?? "N/A")")
    }
    
    // 거래소 정보 모듈
    if let exchangeInfo = quote.exchangeInfo {
        print("\n=== 거래소 정보 ===")
        print("거래소: \(exchangeInfo.exchangeName ?? "N/A")")
        print("통화: \(exchangeInfo.currency ?? "N/A")")
    }
    
    // 시세 데이터 모듈
    if let marketData = quote.marketData {
        print("\n=== 현재 시세 ===")
        print("현재가: $\(marketData.regularMarketPrice ?? 0)")
        print("등락폭: $\(marketData.regularMarketChange ?? 0)")
        print("등락률: \(String(format: "%.2f", (marketData.regularMarketChangePercent ?? 0) * 100))%")
    }
    
    // 거래량 정보 모듈
    if let volumeInfo = quote.volumeInfo {
        print("\n=== 거래 정보 ===")
        print("거래량: \(formatNumber(volumeInfo.regularMarketVolume))")
        print("시가총액: $\(formatLargeNumber(volumeInfo.marketCap))")
        print("시장 상태: \(volumeInfo.marketState ?? "N/A")")
    }
}
```

## 📊 고급 사용 패턴

### 3. 시장 상태별 가격 처리

```swift
func getCurrentPriceInfo(_ quote: YFQuote) -> (price: Double, change: Double, source: String) {
    let marketState = quote.volumeInfo.marketState
    
    switch marketState {
    case "PRE":
        // 장전 거래 우선
        if let prePrice = quote.extendedHours.preMarketPrice,
           let preChange = quote.extendedHours.preMarketChange {
            return (prePrice, preChange, "Pre-Market")
        }
        
    case "POST":
        // 장후 거래 우선
        if let postPrice = quote.extendedHours.postMarketPrice,
           let postChange = quote.extendedHours.postMarketChange {
            return (postPrice, postChange, "After-Hours")
        }
        
    default:
        break
    }
    
    // 정규 시장 기본값
    return (
        quote.marketData.regularMarketPrice ?? 0,
        quote.marketData.regularMarketChange ?? 0,
        "Regular Market"
    )
}

// 사용
let (currentPrice, priceChange, source) = getCurrentPriceInfo(quote)
print("\(source): $\(currentPrice) (\(priceChange >= 0 ? "+" : "")\(priceChange))")
```

### 4. 확장 기능 활용

```swift
extension YFQuote {
    // 간편한 핵심 정보 추출
    var displaySummary: String {
        let (symbol, price, change, changePercent) = self.essentialData
        let direction = (change ?? 0) >= 0 ? "📈" : "📉"
        
        return """
        \(direction) \(symbol ?? "N/A")
        Price: $\(String(format: "%.2f", price ?? 0))
        Change: \(String(format: "%+.2f (%.2f%%)", change ?? 0, (changePercent ?? 0) * 100))
        Updated: \(lastUpdateTime?.formatted() ?? "Unknown")
        """
    }
    
    // 투자 분석 지표
    var isPositiveMovement: Bool {
        return (marketData.regularMarketChange ?? 0) > 0
    }
    
    var priceRange: (low: Double, high: Double)? {
        guard let low = marketData.regularMarketDayLow,
              let high = marketData.regularMarketDayHigh else {
            return nil
        }
        return (low, high)
    }
}

// 사용
print(quote.displaySummary)

if quote.isPositiveMovement {
    print("✅ 상승 추세")
} else {
    print("🔻 하락 추세")
}

if let range = quote.priceRange {
    print("일일 변동폭: $\(range.low) - $\(range.high)")
}
```

## 🔄 배치 처리 및 비교

### 5. 여러 종목 동시 처리

```swift
func fetchMultipleQuotes(_ symbols: [String]) async throws -> [String: YFQuote] {
    var results: [String: YFQuote] = [:]
    
    // 동시 요청으로 성능 최적화
    try await withThrowingTaskGroup(of: (String, YFQuote?).self) { group in
        for symbol in symbols {
            group.addTask {
                let ticker = YFTicker(symbol: symbol)
                let response = try await quoteService.fetch(ticker: ticker)
                return (symbol, response.result?.first)
            }
        }
        
        for try await (symbol, quote) in group {
            if let quote = quote {
                results[symbol] = quote
            }
        }
    }
    
    return results
}

// 사용
let symbols = ["AAPL", "MSFT", "GOOGL", "TSLA"]
let quotes = try await fetchMultipleQuotes(symbols)

for (symbol, quote) in quotes {
    print("\(symbol): $\(quote.marketData.regularMarketPrice ?? 0)")
}
```

### 6. 종목 간 비교 분석

```swift
struct QuoteComparison {
    let quotes: [YFQuote]
    
    var bestPerformer: YFQuote? {
        return quotes.max { a, b in
            let aChange = a.marketData.regularMarketChangePercent ?? 0
            let bChange = b.marketData.regularMarketChangePercent ?? 0
            return aChange < bChange
        }
    }
    
    var worstPerformer: YFQuote? {
        return quotes.min { a, b in
            let aChange = a.marketData.regularMarketChangePercent ?? 0
            let bChange = b.marketData.regularMarketChangePercent ?? 0
            return aChange < bChange
        }
    }
    
    var marketCapLeader: YFQuote? {
        return quotes.max { a, b in
            let aCap = a.volumeInfo.marketCap ?? 0
            let bCap = b.volumeInfo.marketCap ?? 0
            return aCap < bCap
        }
    }
}

// 사용
let comparison = QuoteComparison(quotes: Array(quotes.values))

if let best = comparison.bestPerformer {
    print("최고 수익률: \(best.basicInfo.symbol ?? "N/A") - \(String(format: "%.2f%%", (best.marketData.regularMarketChangePercent ?? 0) * 100))")
}

if let marketLeader = comparison.marketCapLeader {
    print("시가총액 1위: \(marketLeader.basicInfo.longName ?? "N/A")")
}
```

## 🛠️ 유틸리티 함수

```swift
// 숫자 포맷팅 헬퍼
func formatNumber(_ number: Int?) -> String {
    guard let number = number else { return "N/A" }
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
}

func formatLargeNumber(_ number: Double?) -> String {
    guard let number = number else { return "N/A" }
    
    switch number {
    case 1_000_000_000_000...: // 조
        return String(format: "%.2fT", number / 1_000_000_000_000)
    case 1_000_000_000...: // 십억
        return String(format: "%.2fB", number / 1_000_000_000)
    case 1_000_000...: // 백만
        return String(format: "%.2fM", number / 1_000_000)
    case 1_000...: // 천
        return String(format: "%.2fK", number / 1_000)
    default:
        return String(format: "%.2f", number)
    }
}

// 시간 포맷팅
extension Date {
    func marketTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone(identifier: "America/New_York") // 미국 동부시간
        return formatter.string(from: self)
    }
}
```

이러한 예제들은 Quote 모델의 모듈형 설계를 활용하여 효율적이고 유연한 금융 데이터 처리를 보여줍니다.