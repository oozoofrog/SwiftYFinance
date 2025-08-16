# FAQ

SwiftYFinance 사용 시 자주 묻는 질문들

## Overview

SwiftYFinance를 사용하면서 자주 궁금해하는 질문들과 그 해답을 정리했습니다. 문제 해결이나 최적화에 도움이 되길 바랍니다.

## 설치 및 설정

### Q: Swift Package Manager로 설치할 때 빌드 에러가 발생합니다

**A:** 다음 사항들을 확인해보세요:

```swift
// Package.swift에서 플랫폼 버전 확인
.platforms([
    .macOS(.v15),  // macOS 15.0 이상 필요
    .iOS(.v18)     // iOS 18.0 이상 필요
])
```

**일반적인 해결 방법:**
1. Xcode 버전이 최신인지 확인 (Xcode 16+)
2. Swift 6.0 이상 사용 확인
3. 패키지 캐시 정리: `File → Packages → Reset Package Caches`

### Q: Xcode에서 "Cannot find 'SwiftYFinance' in scope" 에러가 발생합니다

**A:** import 문과 타겟 설정을 확인하세요:

```swift
// 파일 상단에 올바른 import
import SwiftYFinance

// 타겟에 SwiftYFinance 의존성이 추가되었는지 확인
// Project Settings → Target → Frameworks, Libraries, and Embedded Content
```

## API 사용

### Q: "Invalid Symbol" 에러가 자주 발생합니다

**A:** 심볼 형식을 확인하고 정규화를 사용하세요:

```swift
// ✅ 올바른 심볼 형식들
let symbols = [
    "AAPL",      // 미국 주식
    "BTC-USD",   // 암호화폐
    "USDKRW=X",  // 환율
    "GC=F",      // 선물
    "^GSPC",     // 지수 (S&P 500)
    "SAMSUNG.KS" // 한국 주식 (삼성전자)
]

// ❌ 잘못된 형식들
let invalidSymbols = [
    "apple",     // 회사명 사용 불가
    "AAPL US",   // 공백 포함 불가
    "삼성전자",   // 한글 불가
    ""           // 빈 문자열 불가
]

// 심볼 검증 함수 사용
func validateAndFetch(_ input: String) async {
    do {
        let ticker = YFTicker(symbol: input.uppercased().trimmingCharacters(in: .whitespacesAndNewlines))
        let quote = try await client.fetchQuote(ticker: ticker)
        print("✅ \(quote.symbol): $\(quote.regularMarketPrice)")
        
    } catch YFError.networkError {
        print("❌ 네트워크 오류: \(input)")
        
    } catch {
        print("❌ 기타 에러: \(error)")
    }
}
```

### Q: Rate Limiting에 자주 걸립니다

**A:** 요청 간격을 늘리고 배치 처리를 사용하세요:

```swift
// ✅ 권장 방법
func fetchMultipleQuotes(symbols: [String]) async {
    for symbol in symbols {
        do {
            let ticker = YFTicker(symbol: symbol)
            let quote = try await client.fetchQuote(ticker: ticker)
            print("\(symbol): $\(quote.regularMarketPrice)")
            
            // 중요: 각 요청 사이에 충분한 딜레이
            try await Task.sleep(nanoseconds: 300_000_000) // 0.3초
            
        } catch {
            print("❌ \(symbol): \(error)")
        }
    }
}

// 대량 처리시 배치 단위로 나누기
let allSymbols = ["AAPL", "GOOGL", "MSFT", /* ... 100개 */]
let batches = allSymbols.chunked(into: 10) // 10개씩 배치

for batch in batches {
    await fetchMultipleQuotes(symbols: batch)
    
    // 배치 간 긴 휴식
    try await Task.sleep(nanoseconds: 2_000_000_000) // 2초
}
```

### Q: 일부 종목에서 데이터가 비어있거나 오래된 것 같습니다

**A:** 시장 상태와 데이터 품질을 확인하세요:

```swift
func analyzeDataQuality(quote: YFQuote) {
    let now = Date()
    let dataAge = now.timeIntervalSince(quote.regularMarketTime)
    
    print("=== 데이터 품질 분석 ===")
    print("심볼: \(quote.symbol)")
    print("데이터 시점: \(quote.regularMarketTime)")
    print("데이터 나이: \(String(format: "%.1f", dataAge / 3600))시간 전")
    
    // 시장 상태 확인
    let calendar = Calendar.current
    let hour = calendar.component(.hour, from: quote.regularMarketTime)
    let weekday = calendar.component(.weekday, from: quote.regularMarketTime)
    
    if weekday == 1 || weekday == 7 {
        print("⚠️ 주말 데이터 - 최신 거래일 데이터")
    } else if hour < 9 || hour > 16 {
        print("⚠️ 장외 시간 데이터")
    } else {
        print("✅ 정규 거래시간 데이터")
    }
    
    // 거래량 확인
    if let volume = quote.regularMarketVolume {
        if volume < 1000 {
            print("⚠️ 매우 낮은 거래량: \(volume)")
        } else {
            print("✅ 정상 거래량: \(volume)")
        }
    }
    
    // 가격 일관성 확인
    if let open = quote.regularMarketOpen,
       let high = quote.regularMarketDayHigh,
       let low = quote.regularMarketDayLow {
        
        let change = quote.regularMarketPrice - open
        let range = high - low
        
        print("일일 변동폭: $\(String(format: "%.2f", range)) (\(String(format: "%.2f", (range/open)*100))%)")
        print("일일 변화: $\(String(format: "%.2f", change)) (\(String(format: "%.2f", (change/open)*100))%)")
    }
}
```

## 성능 최적화

### Q: 대량의 종목 데이터를 빠르게 처리하려면 어떻게 해야 하나요?

**A:** 비동기 처리와 캐싱을 조합하세요:

```swift
// 1. 캐싱 활용
class SmartQuoteManager {
    private let cache = QuoteCache()
    private let client = YFClient()
    
    func fetchQuotes(symbols: [String], maxAge: TimeInterval = 300) async -> [String: YFQuote] {
        var results: [String: YFQuote] = [:]
        var symbolsToFetch: [String] = []
        
        // 1단계: 캐시에서 먼저 확인
        for symbol in symbols {
            if let cachedQuote = cache.get(symbol: symbol) {
                results[symbol] = cachedQuote
            } else {
                symbolsToFetch.append(symbol)
            }
        }
        
        print("💾 캐시에서 \(results.count)개, API에서 \(symbolsToFetch.count)개 조회 예정")
        
        // 2단계: 필요한 것만 API 호출
        for symbol in symbolsToFetch {
            do {
                let ticker = YFTicker(symbol: symbol)
                let quote = try await client.fetchQuote(ticker: ticker)
                results[symbol] = quote
                cache.set(symbol: symbol, quote: quote, ttl: maxAge)
                
                try await Task.sleep(nanoseconds: 200_000_000) // 0.2초
                
            } catch {
                print("❌ \(symbol): \(error)")
            }
        }
        
        return results
    }
}

// 2. 동시성 제어
func fetchQuotesConcurrently(symbols: [String], maxConcurrent: Int = 3) async -> [String: YFQuote] {
    return await withTaskGroup(of: (String, YFQuote?).self) { group in
        var results: [String: YFQuote] = [:]
        let semaphore = AsyncSemaphore(value: maxConcurrent)
        
        for symbol in symbols {
            group.addTask {
                await semaphore.wait()
                defer { semaphore.signal() }
                
                do {
                    let ticker = YFTicker(symbol: symbol)
                    let quote = try await client.fetchQuote(ticker: ticker)
                    return (symbol, quote)
                } catch {
                    print("❌ \(symbol): \(error)")
                    return (symbol, nil)
                }
            }
        }
        
        for await (symbol, quote) in group {
            if let quote = quote {
                results[symbol] = quote
            }
        }
        
        return results
    }
}
```

### Q: 메모리 사용량이 너무 높습니다

**A:** 스트리밍 처리와 명시적 메모리 관리를 사용하세요:

```swift
// ✅ 메모리 효율적인 대량 처리
func processLargeDataset(symbols: [String]) async {
    let batchSize = 20
    
    for batch in symbols.chunked(into: batchSize) {
        autoreleasepool {
            // 배치 처리
            Task {
                await processBatch(batch)
            }
        }
        
        // 명시적 메모리 정리 시점 제공
        try? await Task.sleep(nanoseconds: 100_000_000)
    }
}

// ❌ 메모리 비효율적
func processLargeDatasetBad(symbols: [String]) async {
    var allQuotes: [YFQuote] = [] // 모든 데이터를 메모리에 보관
    
    for symbol in symbols {
        let quote = try? await fetchQuote(symbol)
        if let quote = quote {
            allQuotes.append(quote) // 계속 축적
        }
    }
    
    // 마지막에 한번에 처리 - 메모리 사용량 최대
    processAllQuotes(allQuotes)
}
```

## 에러 처리

### Q: 네트워크 에러가 자주 발생합니다

**A:** 재시도 로직과 회복 전략을 구현하세요:

```swift
func robustFetch<T>(
    operation: @escaping () async throws -> T,
    maxRetries: Int = 3,
    baseDelay: TimeInterval = 1.0
) async throws -> T {
    
    var lastError: Error?
    
    for attempt in 1...maxRetries {
        do {
            return try await operation()
            
        } catch let error as YFError {
            lastError = error
            
            switch error {
            case .networkError:
                if attempt < maxRetries {
                    let delay = baseDelay * pow(2.0, Double(attempt - 1)) // 지수 백오프
                    print("🌐 네트워크 에러. \(delay)초 후 재시도... (\(attempt)/\(maxRetries))")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                } else {
                    throw error
                }
                
            case .rateLimited:
                if attempt < maxRetries {
                    let delay = baseDelay * Double(attempt) * 3 // Rate limit은 더 긴 대기
                    print("⏰ Rate limit. \(delay)초 후 재시도... (\(attempt)/\(maxRetries))")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                } else {
                    throw error
                }
                
            case .invalidSymbol:
                // 심볼 에러는 재시도하지 않음
                throw error
                
            default:
                if attempt == maxRetries {
                    throw error
                }
            }
            
        } catch {
            lastError = error
            if attempt == maxRetries {
                throw error
            }
        }
    }
    
    throw lastError ?? YFError.unknown
}

// 사용 예제
let quote = try await robustFetch {
    let ticker = YFTicker(symbol: "AAPL")
    return try await client.fetchQuote(ticker: ticker)
}
```

### Q: CSRF 인증 에러가 발생합니다

**A:** 인증 상태를 확인하고 재인증을 시도하세요:

```swift
func handleCSRFError() async throws {
    let session = YFSession()
    
    do {
        // 기존 쿠키 정리
        session.clearCookies()
        
        // 새로운 인증 시도
        try await session.authenticateCSRF()
        print("✅ CSRF 재인증 성공")
        
        // 인증 후 원래 요청 재시도
        let ticker = YFTicker(symbol: "AAPL")
        let quote = try await client.fetchQuote(ticker: ticker)
        
    } catch {
        print("❌ CSRF 재인증 실패: \(error)")
        // 기본 API로 폴백
        throw YFError.authenticationFailed
    }
}
```

## 데이터 해석

### Q: 옵션 데이터에서 Greeks가 nil인 경우가 많습니다

**A:** Greeks는 특정 조건에서만 계산됩니다:

```swift
func analyzeOptionsData(options: YFOptionsData) {
    let callsWithGreeks = options.calls.filter { $0.delta != nil }
    let putsWithGreeks = options.puts.filter { $0.delta != nil }
    
    print("=== 옵션 데이터 분석 ===")
    print("전체 콜 옵션: \(options.calls.count)개")
    print("Greeks 있는 콜: \(callsWithGreeks.count)개 (\(String(format: "%.1f", Double(callsWithGreeks.count)/Double(options.calls.count)*100))%)")
    
    print("전체 풋 옵션: \(options.puts.count)개")
    print("Greeks 있는 풋: \(putsWithGreeks.count)개 (\(String(format: "%.1f", Double(putsWithGreeks.count)/Double(options.puts.count)*100))%)")
    
    // Greeks가 없는 이유들
    let lowVolumeOptions = options.calls.filter { $0.volume < 10 }
    let deepITMOptions = options.calls.filter { $0.strike < currentPrice * 0.8 }
    let deepOTMOptions = options.calls.filter { $0.strike > currentPrice * 1.2 }
    
    print("\n가능한 이유들:")
    print("• 낮은 거래량 (<10): \(lowVolumeOptions.count)개")
    print("• 깊은 ITM 옵션: \(deepITMOptions.count)개")
    print("• 깊은 OTM 옵션: \(deepOTMOptions.count)개")
    
    // 권장사항
    print("\n💡 Greeks 분석을 위한 권장사항:")
    print("• ATM 근처 옵션 사용 (±20% 범위)")
    print("• 거래량 100 이상 옵션 선택")
    print("• 만료일이 1주일 이상 남은 옵션 선택")
}
```

### Q: 과거 데이터에서 조정 가격(Adjusted Close)을 어떻게 사용하나요?

**A:** 배당과 분할을 고려한 조정 가격을 사용하세요:

```swift
func analyzeAdjustedPrices(history: YFHistoricalData) {
    print("=== 조정 가격 분석 ===")
    
    for (index, price) in history.prices.enumerated() {
        let adjustment = price.adjustedClose / price.close
        
        if abs(adjustment - 1.0) > 0.01 { // 1% 이상 차이
            print("📅 \(price.date): 조정 발생")
            print("   종가: $\(String(format: "%.2f", price.close))")
            print("   조정종가: $\(String(format: "%.2f", price.adjustedClose))")
            print("   조정비율: \(String(format: "%.4f", adjustment))")
            
            if adjustment < 1.0 {
                print("   → 배당 지급으로 인한 조정")
            } else {
                print("   → 주식 분할/합병으로 인한 조정")
            }
        }
    }
    
    // 수익률 계산 시 조정 가격 사용
    if history.prices.count >= 2 {
        let startPrice = history.prices.first!.adjustedClose
        let endPrice = history.prices.last!.adjustedClose
        let totalReturn = (endPrice - startPrice) / startPrice * 100
        
        print("\n총 수익률 (조정 가격 기준): \(String(format: "%.2f", totalReturn))%")
    }
}

// 기술적 분석 시에도 조정 가격 사용
func calculateMAWithAdjustedPrices(history: YFHistoricalData, period: Int) -> [Double] {
    let adjustedPrices = history.prices.map { $0.adjustedClose }
    return calculateSimpleMovingAverage(prices: adjustedPrices, period: period)
}
```

## 고급 사용법

### Q: 실시간 데이터 스트리밍이 가능한가요?

**A:** Yahoo Finance는 실시간 스트리밍을 제공하지 않습니다. 폴링 방식을 사용하세요:

```swift
class RealTimeQuoteMonitor {
    private let client = YFClient()
    private var isMonitoring = false
    private var monitoringTask: Task<Void, Never>?
    
    func startMonitoring(symbols: [String], interval: TimeInterval = 15.0) {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        monitoringTask = Task {
            while isMonitoring {
                for symbol in symbols {
                    do {
                        let ticker = YFTicker(symbol: symbol)
                        let quote = try await client.fetchQuote(ticker: ticker)
                        
                        await MainActor.run {
                            notifyQuoteUpdate(quote)
                        }
                        
                    } catch {
                        print("❌ \(symbol) 모니터링 에러: \(error)")
                    }
                    
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1초
                }
                
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
        }
    }
    
    func stopMonitoring() {
        isMonitoring = false
        monitoringTask?.cancel()
        monitoringTask = nil
    }
    
    private func notifyQuoteUpdate(_ quote: YFQuote) {
        // UI 업데이트 또는 알림 발송
        print("📈 \(quote.symbol): $\(quote.regularMarketPrice)")
    }
}

// 사용 예제
let monitor = RealTimeQuoteMonitor()
monitor.startMonitoring(symbols: ["AAPL", "GOOGL"], interval: 30.0) // 30초마다 업데이트

// 앱 종료 시
monitor.stopMonitoring()
```

### Q: 커스텀 지표를 계산하려면 어떻게 하나요?

**A:** 기존 가격 데이터를 활용해 커스텀 지표를 구현하세요:

```swift
extension YFTechnicalIndicators {
    // 커스텀 지표 1: Stochastic Oscillator
    func stochasticOscillator(kPeriod: Int = 14, dPeriod: Int = 3) -> (kPercent: [Double], dPercent: [Double]) {
        guard prices.count >= kPeriod else { return ([], []) }
        
        var kPercent: [Double] = []
        
        for i in (kPeriod - 1)..<prices.count {
            let period = Array(prices[(i - kPeriod + 1)...i])
            let high = period.map { $0.high }.max()!
            let low = period.map { $0.low }.min()!
            let close = period.last!.close
            
            let k = ((close - low) / (high - low)) * 100
            kPercent.append(k)
        }
        
        // %D는 %K의 단순이동평균
        let dPercent = simpleMovingAverage(values: kPercent, period: dPeriod)
        
        return (kPercent, dPercent)
    }
    
    // 커스텀 지표 2: Williams %R
    func williamsR(period: Int = 14) -> [Double] {
        guard prices.count >= period else { return [] }
        
        var williamsR: [Double] = []
        
        for i in (period - 1)..<prices.count {
            let periodPrices = Array(prices[(i - period + 1)...i])
            let high = periodPrices.map { $0.high }.max()!
            let low = periodPrices.map { $0.low }.min()!
            let close = periodPrices.last!.close
            
            let wr = ((high - close) / (high - low)) * -100
            williamsR.append(wr)
        }
        
        return williamsR
    }
    
    // 커스텀 지표 3: Commodity Channel Index (CCI)
    func commodityChannelIndex(period: Int = 20) -> [Double] {
        guard prices.count >= period else { return [] }
        
        // Typical Price 계산
        let typicalPrices = prices.map { ($0.high + $0.low + $0.close) / 3.0 }
        
        var cci: [Double] = []
        
        for i in (period - 1)..<typicalPrices.count {
            let periodTP = Array(typicalPrices[(i - period + 1)...i])
            let smaTP = periodTP.reduce(0, +) / Double(period)
            
            // Mean Deviation 계산
            let meanDeviation = periodTP.map { abs($0 - smaTP) }.reduce(0, +) / Double(period)
            
            let currentTP = typicalPrices[i]
            let cciValue = (currentTP - smaTP) / (0.015 * meanDeviation)
            
            cci.append(cciValue)
        }
        
        return cci
    }
    
    // 유틸리티: 단순이동평균 계산
    private func simpleMovingAverage(values: [Double], period: Int) -> [Double] {
        guard values.count >= period else { return [] }
        
        var sma: [Double] = []
        
        for i in (period - 1)..<values.count {
            let sum = Array(values[(i - period + 1)...i]).reduce(0, +)
            sma.append(sum / Double(period))
        }
        
        return sma
    }
}

// 사용 예제
let history = try await client.fetchHistory(ticker: ticker, period: .oneYear)
let indicators = YFTechnicalIndicators(prices: history.prices)

let (kPercent, dPercent) = indicators.stochasticOscillator()
let williamsR = indicators.williamsR()
let cci = indicators.commodityChannelIndex()

print("최신 Stochastic %K: \(String(format: "%.2f", kPercent.last ?? 0))")
print("최신 Williams %R: \(String(format: "%.2f", williamsR.last ?? 0))")
print("최신 CCI: \(String(format: "%.2f", cci.last ?? 0))")
```

## 문제 해결

### Q: 특정 종목에서만 계속 에러가 발생합니다

**A:** 종목별 문제 진단을 수행하세요:

```swift
func diagnoseSymbol(_ symbol: String) async {
    print("=== \(symbol) 진단 ===")
    
    // 1. 심볼 형식 검증
    if !SymbolValidator.isValid(symbol) {
        print("❌ 잘못된 심볼 형식")
        let suggestions = SymbolValidator.suggestCorrection(symbol)
        if !suggestions.isEmpty {
            print("💡 제안: \(suggestions.joined(separator: ", "))")
        }
        return
    }
    
    // 2. 기본 Quote 테스트
    do {
        let ticker = YFTicker(symbol: symbol)
        let quote = try await client.fetchQuote(ticker: ticker)
        print("✅ Quote 조회 성공")
        
        // 데이터 품질 체크
        let issues = DataQualityChecker.validateQuote(quote)
        if !issues.isEmpty {
            print("⚠️ 데이터 품질 이슈:")
            issues.forEach { print("  - \($0)") }
        }
        
    } catch {
        print("❌ Quote 조회 실패: \(error)")
        return
    }
    
    // 3. 과거 데이터 테스트
    do {
        let ticker = YFTicker(symbol: symbol)
        let history = try await client.fetchHistory(ticker: ticker, period: .oneMonth)
        print("✅ History 조회 성공 (\(history.prices.count)개 데이터)")
        
    } catch {
        print("❌ History 조회 실패: \(error)")
    }
    
    // 4. 고급 데이터 테스트
    for test in ["Financials", "Options", "News"] {
        do {
            switch test {
            case "Financials":
                let ticker = YFTicker(symbol: symbol)
                _ = try await client.fetchFinancials(ticker: ticker)
                print("✅ Financials 사용 가능")
                
            case "Options":
                let ticker = YFTicker(symbol: symbol)
                _ = try await client.fetchOptionsChain(ticker: ticker)
                print("✅ Options 사용 가능")
                
            case "News":
                let ticker = YFTicker(symbol: symbol)
                _ = try await client.fetchNews(ticker: ticker)
                print("✅ News 사용 가능")
                
            default:
                break
            }
            
        } catch {
            print("❌ \(test) 사용 불가: \(error)")
        }
    }
}

// 사용 예제
await diagnoseSymbol("AAPL")  // 정상 종목
await diagnoseSymbol("INVALID") // 잘못된 종목
```

### Q: 앱이 백그라운드에서 에러가 발생합니다

**A:** 앱 라이프사이클을 고려한 처리를 구현하세요:

```swift
class BackgroundSafeYFManager: ObservableObject {
    private let client = YFClient()
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    func fetchDataSafely() async {
        // 백그라운드 태스크 시작
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "YFDataFetch") {
            self.endBackgroundTask()
        }
        
        defer {
            endBackgroundTask()
        }
        
        do {
            // 백그라운드에서는 단순한 작업만
            let ticker = YFTicker(symbol: "AAPL")
            let quote = try await client.fetchQuote(ticker: ticker)
            
            await MainActor.run {
                // UI 업데이트는 메인 스레드에서
                updateUI(with: quote)
            }
            
        } catch {
            print("백그라운드 데이터 페치 실패: \(error)")
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    
    private func updateUI(with quote: YFQuote) {
        // UI 업데이트 로직
    }
}
```

## 추가 도움

더 자세한 도움이 필요하면:

1. **GitHub Issues**: 버그 리포트나 기능 요청
2. **Documentation**: 이 DocC 문서의 다른 섹션들
3. **Sample Code**: GitHub 저장소의 예제 프로젝트
4. **Community**: 개발자 커뮤니티 포럼

### 관련 문서

- <doc:GettingStarted> - 기본 설치 및 설정
- <doc:BestPractices> - 성능 최적화 및 모범 사례  
- <doc:ErrorHandling> - 고급 에러 처리 패턴
- <doc:TechnicalAnalysis> - 기술적 분석 가이드