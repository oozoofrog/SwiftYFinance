# Best Practices

SwiftYFinance를 효율적이고 안전하게 사용하기 위한 모범 사례

## Overview

SwiftYFinance를 사용할 때 성능, 안정성, 그리고 Yahoo Finance API 정책을 고려한 모범 사례들을 소개합니다. 이 가이드를 따르면 더 나은 성능과 안정적인 동작을 얻을 수 있습니다.

## Rate Limiting & API Usage

### 적절한 요청 간격

Yahoo Finance API는 무료 서비스이지만 과도한 요청을 제한합니다:

```swift
// ✅ 좋은 예: 적절한 딜레이를 포함한 요청
func fetchMultipleQuotes(symbols: [String]) async throws -> [String: YFQuote] {
    var quotes: [String: YFQuote] = [:]
    
    for symbol in symbols {
        do {
            let ticker = YFTicker(symbol: symbol)
            let quote = try await client.fetchQuote(ticker: ticker)
            quotes[symbol] = quote
            
            // 각 요청 사이에 적절한 딜레이
            try await Task.sleep(nanoseconds: 200_000_000) // 0.2초
            
        } catch {
            print("❌ \(symbol) 실패: \(error)")
        }
    }
    
    return quotes
}
```

```swift
// ❌ 나쁜 예: 연속적인 요청
func fetchMultipleQuotesBad(symbols: [String]) async throws -> [String: YFQuote] {
    var quotes: [String: YFQuote] = [:]
    
    // 딜레이 없이 연속 요청 - Rate Limit에 걸림
    for symbol in symbols {
        let ticker = YFTicker(symbol: symbol)
        let quote = try await client.fetchQuote(ticker: ticker)
        quotes[symbol] = quote
    }
    
    return quotes
}
```

### 배치 처리

대량 데이터를 처리할 때는 배치 단위로 나누어 처리하세요:

```swift
func processBatches<T>(
    items: [T],
    batchSize: Int = 10,
    delayBetweenBatches: TimeInterval = 2.0,
    processor: (T) async throws -> Void
) async throws {
    
    let batches = items.chunked(into: batchSize)
    
    for (index, batch) in batches.enumerated() {
        print("📦 배치 \(index + 1)/\(batches.count) 처리 중... (\(batch.count)개 항목)")
        
        for item in batch {
            try await processor(item)
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1초
        }
        
        // 배치 간 긴 딜레이
        if index < batches.count - 1 {
            print("⏱️ \(delayBetweenBatches)초 대기 중...")
            try await Task.sleep(nanoseconds: UInt64(delayBetweenBatches * 1_000_000_000))
        }
    }
}

// 사용 예제
let symbols = Array(1...100).map { "STOCK\($0)" }

try await processBatches(items: symbols, batchSize: 15) { symbol in
    let ticker = YFTicker(symbol: symbol)
    let quote = try await client.fetchQuote(ticker: ticker)
    print("\(symbol): $\(quote.regularMarketPrice)")
}
```

## Error Handling Strategies

### 재시도 로직

네트워크 에러나 일시적인 실패에 대한 재시도 로직을 구현하세요:

```swift
func withRetry<T>(
    maxAttempts: Int = 3,
    baseDelay: TimeInterval = 1.0,
    operation: () async throws -> T
) async throws -> T {
    
    var lastError: Error?
    
    for attempt in 1...maxAttempts {
        do {
            return try await operation()
            
        } catch let error as YFError {
            lastError = error
            
            switch error {
            case .rateLimited:
                // Rate limit의 경우 더 긴 딜레이
                let delay = baseDelay * Double(attempt) * 2
                print("⏰ Rate limit. \(delay)초 후 재시도... (\(attempt)/\(maxAttempts))")
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
            case .networkError:
                // 네트워크 에러의 경우 지수 백오프
                let delay = baseDelay * pow(2.0, Double(attempt - 1))
                print("🌐 네트워크 에러. \(delay)초 후 재시도... (\(attempt)/\(maxAttempts))")
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
            case .invalidSymbol:
                // 잘못된 심볼은 재시도하지 않음
                throw error
                
            default:
                if attempt == maxAttempts {
                    throw error
                } else {
                    let delay = baseDelay * Double(attempt)
                    print("❓ 알 수 없는 에러. \(delay)초 후 재시도... (\(attempt)/\(maxAttempts))")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
            
        } catch {
            lastError = error
            if attempt == maxAttempts {
                throw error
            }
        }
    }
    
    throw lastError ?? YFError.unknown
}

// 사용 예제
let quote = try await withRetry {
    let ticker = YFTicker(symbol: "AAPL")
    return try await client.fetchQuote(ticker: ticker)
}
```

### 부분 실패 처리

일부 데이터 조회가 실패해도 전체 프로세스가 중단되지 않도록 하세요:

```swift
struct QuoteResult {
    let symbol: String
    let quote: YFQuote?
    let error: Error?
}

func fetchQuotesRobustly(symbols: [String]) async -> [QuoteResult] {
    var results: [QuoteResult] = []
    
    for symbol in symbols {
        do {
            let ticker = YFTicker(symbol: symbol)
            let quote = try await withRetry {
                try await client.fetchQuote(ticker: ticker)
            }
            results.append(QuoteResult(symbol: symbol, quote: quote, error: nil))
            
        } catch {
            results.append(QuoteResult(symbol: symbol, quote: nil, error: error))
            print("⚠️ \(symbol) 실패, 계속 진행: \(error)")
        }
        
        try? await Task.sleep(nanoseconds: 200_000_000)
    }
    
    return results
}

// 결과 분석
let results = await fetchQuotesRobustly(symbols: ["AAPL", "INVALID", "GOOGL"])
let successful = results.compactMap { $0.quote }
let failed = results.filter { $0.error != nil }

print("✅ 성공: \(successful.count)개")
print("❌ 실패: \(failed.count)개")
```

## Caching Strategies

### 메모리 캐싱

자주 조회하는 데이터는 메모리에 캐싱하여 API 호출을 줄이세요:

```swift
class QuoteCache {
    private struct CacheEntry {
        let quote: YFQuote
        let timestamp: Date
        let ttl: TimeInterval
        
        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > ttl
        }
    }
    
    private var cache: [String: CacheEntry] = [:]
    private let lock = NSLock()
    
    func get(symbol: String) -> YFQuote? {
        lock.withLock {
            guard let entry = cache[symbol], !entry.isExpired else {
                cache.removeValue(forKey: symbol)
                return nil
            }
            return entry.quote
        }
    }
    
    func set(symbol: String, quote: YFQuote, ttl: TimeInterval = 60) {
        lock.withLock {
            cache[symbol] = CacheEntry(quote: quote, timestamp: Date(), ttl: ttl)
        }
    }
    
    func clear() {
        lock.withLock {
            cache.removeAll()
        }
    }
    
    func clearExpired() {
        lock.withLock {
            cache = cache.filter { !$0.value.isExpired }
        }
    }
    
    var stats: (total: Int, expired: Int) {
        lock.withLock {
            let expired = cache.values.filter { $0.isExpired }.count
            return (cache.count, expired)
        }
    }
}

// 캐시를 활용한 클라이언트 래퍼
class CachedYFClient {
    private let client = YFClient()
    private let cache = QuoteCache()
    
    func fetchQuote(ticker: YFTicker, cacheTTL: TimeInterval = 60) async throws -> YFQuote {
        // 캐시 확인
        if let cachedQuote = cache.get(symbol: ticker.symbol) {
            print("💾 캐시에서 \(ticker.symbol) 조회")
            return cachedQuote
        }
        
        // API 호출
        print("🌐 API에서 \(ticker.symbol) 조회")
        let quote = try await client.fetchQuote(ticker: ticker)
        
        // 캐시 저장
        cache.set(symbol: ticker.symbol, quote: quote, ttl: cacheTTL)
        
        return quote
    }
}
```

### 디스크 캐싱

장기 보관이 필요한 과거 데이터는 디스크에 캐싱하세요:

```swift
class HistoricalDataCache {
    private let cacheDirectory: URL
    private let fileManager = FileManager.default
    
    init() throws {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        cacheDirectory = documentsPath.appendingPathComponent("SwiftYFinanceCache")
        
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }
    
    private func cacheKey(symbol: String, period: YFPeriod, interval: YFInterval) -> String {
        return "\(symbol)_\(period.rawValue)_\(interval.rawValue)"
    }
    
    private func cacheFileURL(for key: String) -> URL {
        return cacheDirectory.appendingPathComponent("\(key).json")
    }
    
    func get(symbol: String, period: YFPeriod, interval: YFInterval) -> YFHistoricalData? {
        let key = cacheKey(symbol: symbol, period: period, interval: interval)
        let fileURL = cacheFileURL(for: key)
        
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        
        do {
            // 파일 수정 시간 확인 (1시간 TTL)
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            if let modificationDate = attributes[.modificationDate] as? Date,
               Date().timeIntervalSince(modificationDate) > 3600 {
                try fileManager.removeItem(at: fileURL)
                return nil
            }
            
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(YFHistoricalData.self, from: data)
            
        } catch {
            print("💾 캐시 읽기 실패: \(error)")
            return nil
        }
    }
    
    func set(symbol: String, period: YFPeriod, interval: YFInterval, data: YFHistoricalData) {
        let key = cacheKey(symbol: symbol, period: period, interval: interval)
        let fileURL = cacheFileURL(for: key)
        
        do {
            let jsonData = try JSONEncoder().encode(data)
            try jsonData.write(to: fileURL)
            print("💾 \(key) 캐시 저장 완료")
            
        } catch {
            print("💾 캐시 저장 실패: \(error)")
        }
    }
    
    func clearOldCache(olderThan interval: TimeInterval = 24 * 3600) throws {
        let cutoffDate = Date().addingTimeInterval(-interval)
        let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.modificationDateKey])
        
        for file in files {
            let attributes = try file.resourceValues(forKeys: [.modificationDateKey])
            if let modificationDate = attributes.modificationDate,
               modificationDate < cutoffDate {
                try fileManager.removeItem(at: file)
                print("🗑️ 오래된 캐시 삭제: \(file.lastPathComponent)")
            }
        }
    }
}
```

## Performance Optimization

### 메모리 관리

대량 데이터 처리 시 메모리 사용량을 최적화하세요:

```swift
// ✅ 좋은 예: 스트리밍 방식 처리
func processLargeSymbolList(symbols: [String]) async throws {
    // 큰 배열을 작은 청크로 나누어 처리
    for chunk in symbols.chunked(into: 50) {
        var chunkData: [YFQuote] = []
        chunkData.reserveCapacity(chunk.count)
        
        for symbol in chunk {
            do {
                let ticker = YFTicker(symbol: symbol)
                let quote = try await client.fetchQuote(ticker: ticker)
                chunkData.append(quote)
                
            } catch {
                print("❌ \(symbol): \(error)")
            }
        }
        
        // 청크 데이터 처리
        await processChunk(chunkData)
        
        // 명시적 메모리 해제
        chunkData.removeAll()
        
        // 다음 청크 전 잠깐 대기
        try await Task.sleep(nanoseconds: 500_000_000)
    }
}

// ❌ 나쁜 예: 모든 데이터를 메모리에 보관
func processLargeSymbolListBad(symbols: [String]) async throws {
    var allQuotes: [YFQuote] = []
    
    // 모든 데이터를 메모리에 축적 - 메모리 부족 위험
    for symbol in symbols {
        let ticker = YFTicker(symbol: symbol)
        let quote = try await client.fetchQuote(ticker: ticker)
        allQuotes.append(quote)
    }
    
    // 마지막에 한번에 처리
    await processAllQuotes(allQuotes)
}
```

### 동시성 제어

과도한 동시 요청을 제한하세요:

```swift
actor RequestThrottler {
    private var activeRequests = 0
    private let maxConcurrentRequests: Int
    
    init(maxConcurrentRequests: Int = 5) {
        self.maxConcurrentRequests = maxConcurrentRequests
    }
    
    func waitForSlot() async {
        while activeRequests >= maxConcurrentRequests {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초 대기
        }
        activeRequests += 1
    }
    
    func releaseSlot() {
        activeRequests = max(0, activeRequests - 1)
    }
    
    var currentLoad: Double {
        return Double(activeRequests) / Double(maxConcurrentRequests)
    }
}

func fetchQuotesConcurrently(symbols: [String]) async -> [QuoteResult] {
    let throttler = RequestThrottler(maxConcurrentRequests: 3)
    
    return await withTaskGroup(of: QuoteResult.self) { group in
        var results: [QuoteResult] = []
        
        for symbol in symbols {
            group.addTask {
                await throttler.waitForSlot()
                defer { Task { await throttler.releaseSlot() } }
                
                do {
                    let ticker = YFTicker(symbol: symbol)
                    let quote = try await client.fetchQuote(ticker: ticker)
                    return QuoteResult(symbol: symbol, quote: quote, error: nil)
                    
                } catch {
                    return QuoteResult(symbol: symbol, quote: nil, error: error)
                }
            }
        }
        
        for await result in group {
            results.append(result)
        }
        
        return results
    }
}
```

## Data Validation

### 입력 검증

사용자 입력을 철저히 검증하세요:

```swift
struct SymbolValidator {
    static func isValid(_ symbol: String) -> Bool {
        // 기본적인 심볼 형식 검증
        let trimmed = symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        // 길이 검증 (1-10자)
        guard trimmed.count >= 1 && trimmed.count <= 10 else { return false }
        
        // 문자 검증 (영문, 숫자, 일부 특수문자만)
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: ".-=^"))
        return trimmed.unicodeScalars.allSatisfy { allowedCharacters.contains($0) }
    }
    
    static func normalize(_ symbol: String) -> String {
        return symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }
    
    static func suggestCorrection(_ symbol: String) -> [String] {
        let normalized = normalize(symbol)
        var suggestions: [String] = []
        
        // 일반적인 실수들 수정
        if normalized.hasSuffix("US") {
            suggestions.append(String(normalized.dropLast(2)))
        }
        
        if !normalized.contains(".") && (normalized.count <= 4) {
            // 주요 거래소 접미사 추가
            suggestions.append(normalized + ".TO") // 토론토
            suggestions.append(normalized + ".L")  // 런던
        }
        
        return suggestions
    }
}

// 안전한 심볼 처리 함수
func safeCreateTicker(_ input: String) throws -> YFTicker {
    guard SymbolValidator.isValid(input) else {
        let suggestions = SymbolValidator.suggestCorrection(input)
        let suggestionText = suggestions.isEmpty ? "" : " 제안: \(suggestions.joined(separator: ", "))"
        throw YFError.invalidSymbol("잘못된 심볼 형식: '\(input)'\(suggestionText)")
    }
    
    let normalizedSymbol = SymbolValidator.normalize(input)
    return YFTicker(symbol: normalizedSymbol)
}
```

### 데이터 품질 검증

받은 데이터의 품질을 검증하세요:

```swift
struct DataQualityChecker {
    static func validateQuote(_ quote: YFQuote) -> [String] {
        var issues: [String] = []
        
        // 가격 데이터 검증
        if quote.regularMarketPrice <= 0 {
            issues.append("비정상적인 가격: \(quote.regularMarketPrice)")
        }
        
        if let volume = quote.regularMarketVolume, volume < 0 {
            issues.append("음수 거래량: \(volume)")
        }
        
        if let marketCap = quote.marketCap, marketCap <= 0 {
            issues.append("비정상적인 시가총액: \(marketCap)")
        }
        
        // 날짜 검증
        let now = Date()
        let marketTime = quote.regularMarketTime
        if marketTime > now {
            issues.append("미래 시점 데이터: \(marketTime)")
        }
        
        // 가격 일관성 검증
        if let open = quote.regularMarketOpen,
           let high = quote.regularMarketDayHigh,
           let low = quote.regularMarketDayLow,
           let close = quote.regularMarketPrice {
            
            if high < low {
                issues.append("고가(\(high)) < 저가(\(low))")
            }
            
            if close > high || close < low {
                issues.append("종가(\(close))가 고저가 범위를 벗어남")
            }
            
            if open > high || open < low {
                issues.append("시가(\(open))가 고저가 범위를 벗어남")
            }
        }
        
        return issues
    }
    
    static func validateHistoricalData(_ data: YFHistoricalData) -> [String] {
        var issues: [String] = []
        
        if data.prices.isEmpty {
            issues.append("가격 데이터 없음")
            return issues
        }
        
        // 날짜 순서 검증
        for i in 1..<data.prices.count {
            if data.prices[i].date <= data.prices[i-1].date {
                issues.append("날짜 순서 오류: \(data.prices[i].date)")
            }
        }
        
        // 가격 이상치 검증
        let prices = data.prices.map { $0.close }
        let median = prices.sorted()[prices.count / 2]
        
        for price in data.prices {
            if price.close > median * 10 || price.close < median * 0.1 {
                issues.append("가격 이상치: \(price.date) - $\(price.close)")
            }
        }
        
        return issues
    }
}

// 사용 예제
func fetchAndValidateQuote(symbol: String) async throws -> YFQuote {
    let ticker = try safeCreateTicker(symbol)
    let quote = try await client.fetchQuote(ticker: ticker)
    
    let issues = DataQualityChecker.validateQuote(quote)
    if !issues.isEmpty {
        print("⚠️ 데이터 품질 이슈:")
        issues.forEach { print("  - \($0)") }
    }
    
    return quote
}
```

## Logging & Monitoring

### 구조화된 로깅

체계적인 로깅을 통해 문제를 추적하세요:

```swift
import os.log

struct YFLogger {
    private static let subsystem = "com.yourapp.swiftyfinance"
    
    static let network = Logger(subsystem: subsystem, category: "network")
    static let cache = Logger(subsystem: subsystem, category: "cache")
    static let performance = Logger(subsystem: subsystem, category: "performance")
    static let business = Logger(subsystem: subsystem, category: "business")
    
    static func logAPICall(symbol: String, endpoint: String, duration: TimeInterval, success: Bool) {
        if success {
            network.info("✅ API 호출 성공: \(symbol) \(endpoint) (\(String(format: "%.3f", duration))s)")
        } else {
            network.error("❌ API 호출 실패: \(symbol) \(endpoint) (\(String(format: "%.3f", duration))s)")
        }
    }
    
    static func logCacheHit(symbol: String, hitRate: Double) {
        cache.info("💾 캐시 히트: \(symbol) (히트율: \(String(format: "%.1f", hitRate * 100))%)")
    }
    
    static func logPerformanceMetric(operation: String, duration: TimeInterval, itemCount: Int) {
        let throughput = Double(itemCount) / duration
        performance.info("📊 성능: \(operation) - \(itemCount)개 항목, \(String(format: "%.3f", duration))s (\(String(format: "%.1f", throughput))개/초)")
    }
}

// 성능 측정 래퍼
func measurePerformance<T>(
    operation: String,
    _ block: () async throws -> T
) async rethrows -> T {
    let startTime = CFAbsoluteTimeGetCurrent()
    
    defer {
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        YFLogger.performance.info("⏱️ \(operation): \(String(format: "%.3f", duration))s")
    }
    
    return try await block()
}
```

## Testing Strategies

### 테스트 설계

```swift
// 프로토콜 기반 테스트 설계
protocol YFClientProtocol {
    func fetchQuote(ticker: YFTicker) async throws -> YFQuote
    func fetchHistory(ticker: YFTicker, period: YFPeriod) async throws -> YFHistoricalData
}

extension YFClient: YFClientProtocol {}

// 테스트에서는 실제 API를 사용하거나 네트워크 레이어를 모킹
class TestableYFClient: YFClientProtocol {
    private let client = YFClient()
    
    func fetchQuote(ticker: YFTicker) async throws -> YFQuote {
        // 실제 API 호출 - 테스트는 실제 동작을 검증해야 함
        return try await client.fetchQuote(ticker: ticker)
    }
    
    func fetchHistory(ticker: YFTicker, period: YFPeriod) async throws -> YFHistoricalData {
        // 실제 API 호출 - 테스트는 실제 동작을 검증해야 함
        return try await client.fetchHistory(ticker: ticker, period: period)
    }
}
```

> **중요**: SwiftYFinance는 Mock 데이터를 사용하지 않습니다. 모든 테스트는 실제 Yahoo Finance API를 사용하여 실제 동작을 검증합니다.

## Security Considerations

### 민감한 정보 보호

```swift
// ✅ 로그에서 민감한 정보 마스킹
extension YFQuote {
    var debugDescription: String {
        return """
        YFQuote(
            symbol: \(symbol),
            price: $\(String(format: "%.2f", regularMarketPrice)),
            time: \(regularMarketTime),
            // 기타 public 정보만 표시
        )
        """
    }
}

// ❌ 전체 객체 로깅 피하기
// print("Quote: \(quote)") // 내부 구조가 모두 노출될 수 있음
```

## Next Steps

모범 사례를 익혔다면 다음을 확인해보세요:

- <doc:PerformanceOptimization> - 성능 최적화 심화
- <doc:ErrorHandling> - 고급 에러 처리 패턴
- <doc:TechnicalAnalysis> - 기술적 분석과 성능 최적화
- <doc:FAQ> - 자주 묻는 질문과 문제 해결