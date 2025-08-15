# Performance Optimization

SwiftYFinance의 성능을 최적화하는 고급 기법들

## Overview

SwiftYFinance를 사용할 때 성능을 극대화하고 리소스 사용량을 최적화하는 방법들을 다룹니다. 대량 데이터 처리, 메모리 관리, 네트워크 최적화 등의 기법을 소개합니다.

## Memory Management

### 효율적인 데이터 구조 사용

```swift
// ✅ 메모리 효율적인 배치 처리
class MemoryEfficientProcessor {
    private let batchSize: Int
    private let processingQueue = DispatchQueue(label: "data.processing", qos: .utility)
    
    init(batchSize: Int = 100) {
        self.batchSize = batchSize
    }
    
    func processSymbols(_ symbols: [String]) async throws {
        for batch in symbols.chunked(into: batchSize) {
            try await processBatch(batch)
            
            // 명시적 메모리 정리
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    // 강제 가비지 컬렉션 힌트
                    autoreleasepool { }
                }
            }
        }
    }
    
    private func processBatch(_ symbols: [String]) async throws {
        // 지역 변수로 메모리 스코프 제한
        var batchResults: [YFQuote] = []
        batchResults.reserveCapacity(symbols.count)
        
        defer {
            batchResults.removeAll()
        }
        
        for symbol in symbols {
            do {
                let ticker = try YFTicker(symbol: symbol)
                let quote = try await client.fetchQuote(ticker: ticker)
                batchResults.append(quote)
                
                // 즉시 처리하여 메모리 누적 방지
                processQuoteImmediately(quote)
                
            } catch {
                print("❌ \(symbol): \(error)")
            }
        }
    }
    
    private func processQuoteImmediately(_ quote: YFQuote) {
        // 데이터를 즉시 처리하고 필요한 것만 보관
        let essentialData = QuoteEssentials(
            symbol: quote.symbol,
            price: quote.regularMarketPrice,
            volume: quote.regularMarketVolume ?? 0,
            timestamp: quote.regularMarketTime
        )
        
        // 필수 데이터만 저장
        saveEssentialData(essentialData)
    }
}

struct QuoteEssentials {
    let symbol: String
    let price: Double
    let volume: Int64
    let timestamp: Date
}
```

### 스마트 캐싱 전략

```swift
class AdaptiveCache<Key: Hashable, Value> {
    private struct CacheEntry {
        let value: Value
        let timestamp: Date
        let accessCount: Int
        let lastAccess: Date
        
        var age: TimeInterval {
            Date().timeIntervalSince(timestamp)
        }
        
        var priority: Double {
            let recency = 1.0 / (Date().timeIntervalSince(lastAccess) + 1)
            let frequency = Double(accessCount)
            return recency * frequency
        }
    }
    
    private var cache: [Key: CacheEntry] = [:]
    private let maxSize: Int
    private let defaultTTL: TimeInterval
    private let lock = NSLock()
    
    init(maxSize: Int = 1000, defaultTTL: TimeInterval = 300) {
        self.maxSize = maxSize
        self.defaultTTL = defaultTTL
    }
    
    func get(_ key: Key) -> Value? {
        lock.withLock {
            guard var entry = cache[key] else { return nil }
            
            // TTL 확인
            if entry.age > defaultTTL {
                cache.removeValue(forKey: key)
                return nil
            }
            
            // 액세스 정보 업데이트
            entry = CacheEntry(
                value: entry.value,
                timestamp: entry.timestamp,
                accessCount: entry.accessCount + 1,
                lastAccess: Date()
            )
            cache[key] = entry
            
            return entry.value
        }
    }
    
    func set(_ key: Key, value: Value) {
        lock.withLock {
            // 캐시 크기 관리
            if cache.count >= maxSize {
                evictLeastValuable()
            }
            
            let entry = CacheEntry(
                value: value,
                timestamp: Date(),
                accessCount: 1,
                lastAccess: Date()
            )
            cache[key] = entry
        }
    }
    
    private func evictLeastValuable() {
        guard !cache.isEmpty else { return }
        
        // 우선순위가 가장 낮은 항목 제거
        let leastValuable = cache.min { $0.value.priority < $1.value.priority }
        if let keyToRemove = leastValuable?.key {
            cache.removeValue(forKey: keyToRemove)
        }
    }
    
    func clearExpired() {
        lock.withLock {
            let now = Date()
            cache = cache.filter { 
                now.timeIntervalSince($0.value.timestamp) <= defaultTTL 
            }
        }
    }
    
    var hitRate: Double {
        lock.withLock {
            let totalAccesses = cache.values.map { $0.accessCount }.reduce(0, +)
            let cacheSize = cache.count
            return cacheSize > 0 ? Double(totalAccesses) / Double(cacheSize) : 0
        }
    }
}

// 사용 예제
let smartCache = AdaptiveCache<String, YFQuote>(maxSize: 500, defaultTTL: 180)

func fetchQuoteWithSmartCache(symbol: String) async throws -> YFQuote {
    // 캐시 확인
    if let cachedQuote = smartCache.get(symbol) {
        print("💾 스마트 캐시 히트: \(symbol)")
        return cachedQuote
    }
    
    // API 호출
    let ticker = try YFTicker(symbol: symbol)
    let quote = try await client.fetchQuote(ticker: ticker)
    
    // 적응형 캐시에 저장
    smartCache.set(symbol, value: quote)
    
    return quote
}
```

## Network Optimization

### 연결 풀링과 재사용

```swift
class OptimizedYFClient {
    private let session: URLSession
    private let requestQueue = DispatchQueue(label: "yf.requests", qos: .userInitiated)
    private let rateLimiter = TokenBucket(capacity: 10, refillRate: 2.0)
    
    init() {
        let configuration = URLSessionConfiguration.default
        configuration.httpMaximumConnectionsPerHost = 5
        configuration.httpCookieAcceptPolicy = .always
        configuration.httpCookieStorage = HTTPCookieStorage.shared
        configuration.urlCache = URLCache(
            memoryCapacity: 50 * 1024 * 1024,  // 50MB 메모리
            diskCapacity: 200 * 1024 * 1024,   // 200MB 디스크
            diskPath: "SwiftYFinanceCache"
        )
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        
        self.session = URLSession(configuration: configuration)
    }
    
    func fetchQuoteOptimized(symbol: String) async throws -> YFQuote {
        // Rate limiting
        await rateLimiter.acquire()
        
        return try await withTaskGroup(of: YFQuote.self) { group in
            group.addTask {
                try await self.performRequest(symbol: symbol)
            }
            
            return try await group.next()!
        }
    }
    
    private func performRequest(symbol: String) async throws -> YFQuote {
        let ticker = try YFTicker(symbol: symbol)
        
        // 캐시된 응답 사용 시도
        let request = try buildOptimizedRequest(for: symbol)
        
        let (data, response) = try await session.data(for: request)
        
        // 응답 캐싱 정보 확인
        if let httpResponse = response as? HTTPURLResponse {
            let cacheStatus = httpResponse.allHeaderFields["X-Cache"] as? String ?? "MISS"
            print("📡 \(symbol): \(cacheStatus)")
        }
        
        return try parseQuoteResponse(data: data, symbol: symbol)
    }
    
    private func buildOptimizedRequest(for symbol: String) throws -> URLRequest {
        guard let url = URL(string: "https://query1.finance.yahoo.com/v8/finance/quote?symbols=\(symbol)") else {
            throw YFError.invalidSymbol(symbol)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("gzip, deflate", forHTTPHeaderField: "Accept-Encoding")
        request.setValue("keep-alive", forHTTPHeaderField: "Connection")
        request.cachePolicy = .returnCacheDataElseLoad
        request.timeoutInterval = 30
        
        return request
    }
}

// Token Bucket Rate Limiter
actor TokenBucket {
    private let capacity: Int
    private let refillRate: Double
    private var tokens: Double
    private var lastRefill: Date
    
    init(capacity: Int, refillRate: Double) {
        self.capacity = capacity
        self.refillRate = refillRate
        self.tokens = Double(capacity)
        self.lastRefill = Date()
    }
    
    func acquire() async {
        while !tryAcquire() {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초 대기
        }
    }
    
    private func tryAcquire() -> Bool {
        refillTokens()
        
        if tokens >= 1.0 {
            tokens -= 1.0
            return true
        }
        return false
    }
    
    private func refillTokens() {
        let now = Date()
        let timePassed = now.timeIntervalSince(lastRefill)
        let tokensToAdd = timePassed * refillRate
        
        tokens = min(Double(capacity), tokens + tokensToAdd)
        lastRefill = now
    }
}
```

### 배치 API 최적화

```swift
class BatchOptimizedClient {
    private let client = YFClient()
    private let maxBatchSize = 50
    private let optimalBatchSize = 20
    
    func fetchMultipleQuotesBatched(_ symbols: [String]) async throws -> [String: YFQuote] {
        var results: [String: YFQuote] = [:]
        let batches = createOptimalBatches(symbols)
        
        // 배치별 병렬 처리
        try await withThrowingTaskGroup(of: [String: YFQuote].self) { group in
            for (index, batch) in batches.enumerated() {
                group.addTask { [weak self] in
                    guard let self = self else { return [:] }
                    
                    // 배치 간 스케줄링
                    let delay = Double(index) * 0.5 // 500ms 간격
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    
                    return try await self.processBatch(batch)
                }
            }
            
            for try await batchResult in group {
                results.merge(batchResult) { _, new in new }
            }
        }
        
        return results
    }
    
    private func createOptimalBatches(_ symbols: [String]) -> [[String]] {
        // 심볼 우선순위 기반 배치 구성
        let prioritizedSymbols = prioritizeSymbols(symbols)
        return prioritizedSymbols.chunked(into: optimalBatchSize)
    }
    
    private func prioritizeSymbols(_ symbols: [String]) -> [String] {
        // 인기 있는 심볼을 우선 처리
        let popularSymbols = ["AAPL", "GOOGL", "MSFT", "AMZN", "TSLA"]
        let popular = symbols.filter { popularSymbols.contains($0) }
        let others = symbols.filter { !popularSymbols.contains($0) }
        
        return popular + others
    }
    
    private func processBatch(_ symbols: [String]) async throws -> [String: YFQuote] {
        var results: [String: YFQuote] = [:]
        
        for symbol in symbols {
            do {
                let ticker = try YFTicker(symbol: symbol)
                let quote = try await client.fetchQuote(ticker: ticker)
                results[symbol] = quote
                
                // 배치 내 요청 간 최소 딜레이
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1초
                
            } catch {
                print("❌ 배치 내 \(symbol) 실패: \(error)")
            }
        }
        
        return results
    }
}
```

## Concurrency Optimization

### 적응형 동시성 제어

```swift
actor AdaptiveConcurrencyManager {
    private var maxConcurrency: Int
    private var activeTasks: Int = 0
    private var completedTasks: Int = 0
    private var failedTasks: Int = 0
    private var lastAdjustment: Date = Date()
    
    init(initialConcurrency: Int = 3) {
        self.maxConcurrency = initialConcurrency
    }
    
    func acquireSlot() async {
        while activeTasks >= maxConcurrency {
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        }
        activeTasks += 1
    }
    
    func releaseSlot(success: Bool) {
        activeTasks = max(0, activeTasks - 1)
        
        if success {
            completedTasks += 1
        } else {
            failedTasks += 1
        }
        
        adjustConcurrencyIfNeeded()
    }
    
    private func adjustConcurrencyIfNeeded() {
        let now = Date()
        let timeSinceLastAdjustment = now.timeIntervalSince(lastAdjustment)
        
        // 10초마다 조정 검토
        guard timeSinceLastAdjustment > 10.0 else { return }
        
        let totalTasks = completedTasks + failedTasks
        guard totalTasks > 20 else { return } // 충분한 샘플 필요
        
        let successRate = Double(completedTasks) / Double(totalTasks)
        
        if successRate > 0.95 && maxConcurrency < 10 {
            // 성공률이 높으면 동시성 증가
            maxConcurrency += 1
            print("📈 동시성 증가: \(maxConcurrency)")
        } else if successRate < 0.80 && maxConcurrency > 1 {
            // 성공률이 낮으면 동시성 감소
            maxConcurrency -= 1
            print("📉 동시성 감소: \(maxConcurrency)")
        }
        
        // 통계 리셋
        completedTasks = 0
        failedTasks = 0
        lastAdjustment = now
    }
    
    var stats: (concurrency: Int, active: Int, successRate: Double) {
        let totalTasks = completedTasks + failedTasks
        let successRate = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0
        return (maxConcurrency, activeTasks, successRate)
    }
}

// 사용 예제
func fetchWithAdaptiveConcurrency(symbols: [String]) async -> [QuoteResult] {
    let manager = AdaptiveConcurrencyManager()
    
    return await withTaskGroup(of: QuoteResult.self) { group in
        var results: [QuoteResult] = []
        
        for symbol in symbols {
            group.addTask {
                await manager.acquireSlot()
                
                var success = false
                defer { 
                    Task { await manager.releaseSlot(success: success) }
                }
                
                do {
                    let ticker = try YFTicker(symbol: symbol)
                    let quote = try await client.fetchQuote(ticker: ticker)
                    success = true
                    return QuoteResult(symbol: symbol, quote: quote, error: nil)
                    
                } catch {
                    return QuoteResult(symbol: symbol, quote: nil, error: error)
                }
            }
        }
        
        for await result in group {
            results.append(result)
            
            // 주기적으로 통계 출력
            if results.count % 50 == 0 {
                let stats = await manager.stats
                print("📊 동시성: \(stats.concurrency), 활성: \(stats.active), 성공률: \(String(format: "%.1f", stats.successRate * 100))%")
            }
        }
        
        return results
    }
}
```

## Data Processing Optimization

### 스트리밍 데이터 처리

```swift
class StreamingDataProcessor {
    private let processingBuffer = StreamingBuffer<YFQuote>(size: 1000)
    
    func processLargeDataset(symbols: [String]) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            // Producer: 데이터 가져오기
            group.addTask {
                try await self.produceData(symbols: symbols)
            }
            
            // Consumer: 데이터 처리
            group.addTask {
                await self.consumeData()
            }
            
            // Monitor: 진행상황 모니터링
            group.addTask {
                await self.monitorProgress()
            }
        }
    }
    
    private func produceData(symbols: [String]) async throws {
        for symbol in symbols {
            do {
                let ticker = try YFTicker(symbol: symbol)
                let quote = try await client.fetchQuote(ticker: ticker)
                
                await processingBuffer.add(quote)
                
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1초
                
            } catch {
                print("❌ Producer error for \(symbol): \(error)")
            }
        }
        
        await processingBuffer.complete()
    }
    
    private func consumeData() async {
        while await !processingBuffer.isCompleted || !processingBuffer.isEmpty {
            if let quote = await processingBuffer.next() {
                await processQuote(quote)
            } else {
                try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            }
        }
    }
    
    private func processQuote(_ quote: YFQuote) async {
        // 실제 데이터 처리 로직
        // 예: 데이터베이스 저장, 계산, 알림 등
        print("📈 처리 완료: \(quote.symbol) - $\(quote.regularMarketPrice)")
    }
    
    private func monitorProgress() async {
        while await !processingBuffer.isCompleted {
            let stats = await processingBuffer.stats
            print("📊 버퍼: \(stats.current)/\(stats.capacity), 총 처리: \(stats.processed)")
            
            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5초
        }
    }
}

actor StreamingBuffer<T> {
    private var buffer: [T] = []
    private let capacity: Int
    private var completed = false
    private var totalProcessed = 0
    
    init(size: Int) {
        self.capacity = size
    }
    
    func add(_ item: T) async {
        while buffer.count >= capacity && !completed {
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
        
        if !completed {
            buffer.append(item)
        }
    }
    
    func next() -> T? {
        guard !buffer.isEmpty else { return nil }
        
        let item = buffer.removeFirst()
        totalProcessed += 1
        return item
    }
    
    func complete() {
        completed = true
    }
    
    var isEmpty: Bool {
        buffer.isEmpty
    }
    
    var isCompleted: Bool {
        completed
    }
    
    var stats: (current: Int, capacity: Int, processed: Int) {
        (buffer.count, capacity, totalProcessed)
    }
}
```

## Algorithmic Optimization

### 효율적인 기술적 지표 계산

```swift
class OptimizedIndicators {
    // 메모이제이션을 활용한 이동평균
    private var smaCache: [String: [Double]] = [:]
    
    func optimizedSMA(prices: [Double], period: Int) -> [Double] {
        let cacheKey = "\(prices.count)_\(period)"
        
        if let cached = smaCache[cacheKey] {
            return cached
        }
        
        guard prices.count >= period else { return [] }
        
        var sma: [Double] = []
        sma.reserveCapacity(prices.count - period + 1)
        
        // 첫 번째 SMA는 일반적인 방법으로 계산
        var sum = prices[0..<period].reduce(0, +)
        sma.append(sum / Double(period))
        
        // 이후는 롤링 계산으로 최적화
        for i in period..<prices.count {
            sum = sum - prices[i - period] + prices[i]
            sma.append(sum / Double(period))
        }
        
        smaCache[cacheKey] = sma
        return sma
    }
    
    // 증분 업데이트가 가능한 RSI
    class IncrementalRSI {
        private let period: Int
        private var gains: [Double] = []
        private var losses: [Double] = []
        private var avgGain: Double = 0
        private var avgLoss: Double = 0
        private var isInitialized = false
        
        init(period: Int = 14) {
            self.period = period
        }
        
        func update(newPrice: Double, previousPrice: Double) -> Double? {
            let change = newPrice - previousPrice
            let gain = max(change, 0)
            let loss = max(-change, 0)
            
            if !isInitialized {
                gains.append(gain)
                losses.append(loss)
                
                if gains.count >= period {
                    avgGain = gains.reduce(0, +) / Double(period)
                    avgLoss = losses.reduce(0, +) / Double(period)
                    isInitialized = true
                    
                    // 첫 번째 RSI 계산
                    return calculateRSI()
                }
                return nil
            } else {
                // 지수 이동평균으로 업데이트
                let alpha = 1.0 / Double(period)
                avgGain = (1 - alpha) * avgGain + alpha * gain
                avgLoss = (1 - alpha) * avgLoss + alpha * loss
                
                return calculateRSI()
            }
        }
        
        private func calculateRSI() -> Double {
            guard avgLoss != 0 else { return 100 }
            
            let rs = avgGain / avgLoss
            return 100 - (100 / (1 + rs))
        }
    }
    
    // 벡터화된 MACD 계산
    func vectorizedMACD(prices: [Double], fastPeriod: Int = 12, slowPeriod: Int = 26, signalPeriod: Int = 9) -> (macd: [Double], signal: [Double], histogram: [Double]) {
        
        let fastEMA = exponentialMovingAverage(prices: prices, period: fastPeriod)
        let slowEMA = exponentialMovingAverage(prices: prices, period: slowPeriod)
        
        // MACD 라인 계산 (벡터화)
        let startIndex = slowPeriod - 1
        let macd = zip(fastEMA.dropFirst(startIndex), slowEMA).map { $0 - $1 }
        
        // 시그널 라인 계산
        let signal = exponentialMovingAverage(prices: macd, period: signalPeriod)
        
        // 히스토그램 계산
        let signalStartIndex = signalPeriod - 1
        let histogram = zip(macd.dropFirst(signalStartIndex), signal).map { $0 - $1 }
        
        return (macd, signal, histogram)
    }
    
    private func exponentialMovingAverage(prices: [Double], period: Int) -> [Double] {
        guard prices.count >= period else { return [] }
        
        var ema: [Double] = []
        let multiplier = 2.0 / Double(period + 1)
        
        // 첫 번째 EMA는 SMA로 시작
        let firstSMA = prices[0..<period].reduce(0, +) / Double(period)
        ema.append(firstSMA)
        
        // 이후는 지수 이동평균 공식 사용
        for i in period..<prices.count {
            let newEMA = (prices[i] - ema.last!) * multiplier + ema.last!
            ema.append(newEMA)
        }
        
        return ema
    }
}
```

## Performance Monitoring

### 자동 성능 측정

```swift
class PerformanceMonitor {
    private var metrics: [String: PerformanceMetric] = [:]
    private let queue = DispatchQueue(label: "performance.monitor")
    
    func measure<T>(operation: String, _ block: () async throws -> T) async rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let startMemory = getCurrentMemoryUsage()
        
        defer {
            let endTime = CFAbsoluteTimeGetCurrent()
            let endMemory = getCurrentMemoryUsage()
            let duration = endTime - startTime
            let memoryDelta = endMemory - startMemory
            
            recordMetric(
                operation: operation,
                duration: duration,
                memoryDelta: memoryDelta
            )
        }
        
        return try await block()
    }
    
    private func recordMetric(operation: String, duration: TimeInterval, memoryDelta: Int64) {
        queue.async {
            var metric = self.metrics[operation] ?? PerformanceMetric(operation: operation)
            metric.recordExecution(duration: duration, memoryDelta: memoryDelta)
            self.metrics[operation] = metric
        }
    }
    
    private func getCurrentMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let status = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return status == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }
    
    func getReport() -> PerformanceReport {
        return queue.sync {
            PerformanceReport(metrics: Array(metrics.values))
        }
    }
}

struct PerformanceMetric {
    let operation: String
    private(set) var executionCount: Int = 0
    private(set) var totalDuration: TimeInterval = 0
    private(set) var minDuration: TimeInterval = Double.infinity
    private(set) var maxDuration: TimeInterval = 0
    private(set) var totalMemoryDelta: Int64 = 0
    
    var averageDuration: TimeInterval {
        executionCount > 0 ? totalDuration / Double(executionCount) : 0
    }
    
    var averageMemoryDelta: Double {
        executionCount > 0 ? Double(totalMemoryDelta) / Double(executionCount) : 0
    }
    
    mutating func recordExecution(duration: TimeInterval, memoryDelta: Int64) {
        executionCount += 1
        totalDuration += duration
        minDuration = min(minDuration, duration)
        maxDuration = max(maxDuration, duration)
        totalMemoryDelta += memoryDelta
    }
}

struct PerformanceReport {
    let metrics: [PerformanceMetric]
    let timestamp: Date = Date()
    
    func printReport() {
        print("\n=== 성능 리포트 (\(timestamp)) ===")
        
        for metric in metrics.sorted(by: { $0.totalDuration > $1.totalDuration }) {
            print("\n📊 \(metric.operation):")
            print("  실행 횟수: \(metric.executionCount)")
            print("  평균 시간: \(String(format: "%.3f", metric.averageDuration))초")
            print("  최소/최대: \(String(format: "%.3f", metric.minDuration))초 / \(String(format: "%.3f", metric.maxDuration))초")
            print("  총 시간: \(String(format: "%.3f", metric.totalDuration))초")
            print("  평균 메모리: \(formatBytes(Int64(metric.averageMemoryDelta)))")
        }
        
        let totalExecutions = metrics.map { $0.executionCount }.reduce(0, +)
        let totalTime = metrics.map { $0.totalDuration }.reduce(0, +)
        
        print("\n📈 전체 통계:")
        print("  총 실행: \(totalExecutions)회")
        print("  총 시간: \(String(format: "%.3f", totalTime))초")
        print("  평균 처리율: \(String(format: "%.1f", Double(totalExecutions) / totalTime))회/초")
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: bytes)
    }
}

// 글로벌 성능 모니터
let performanceMonitor = PerformanceMonitor()

// 사용 예제
func optimizedDataFetch(symbols: [String]) async throws -> [YFQuote] {
    return try await performanceMonitor.measure(operation: "bulk_quote_fetch") {
        var quotes: [YFQuote] = []
        
        for symbol in symbols {
            let quote = try await performanceMonitor.measure(operation: "single_quote_fetch") {
                let ticker = try YFTicker(symbol: symbol)
                return try await client.fetchQuote(ticker: ticker)
            }
            quotes.append(quote)
        }
        
        return quotes
    }
}

// 주기적 성능 리포트
Task {
    while true {
        try await Task.sleep(nanoseconds: 60_000_000_000) // 1분마다
        performanceMonitor.getReport().printReport()
    }
}
```

## 비용 및 리소스 관리

### 1. 네트워크 비용 최적화

SwiftYFinance는 무료 API를 사용하지만, 네트워크 데이터 사용량을 고려해야 합니다:

```swift
class NetworkCostManager {
    private var dailyRequestCount = 0
    private var dailyDataTransfer: Int64 = 0
    private let maxDailyRequests = 1000
    private let maxDailyDataMB = 100
    
    func trackRequest(responseSize: Int64) {
        dailyRequestCount += 1
        dailyDataTransfer += responseSize
        
        if dailyRequestCount > maxDailyRequests {
            print("⚠️ 일일 요청 한도 (\(maxDailyRequests)) 초과")
        }
        
        let dailyDataMB = dailyDataTransfer / (1024 * 1024)
        if dailyDataMB > maxDailyDataMB {
            print("⚠️ 일일 데이터 사용량 (\(maxDailyDataMB)MB) 초과")
        }
    }
    
    func getDailyUsage() -> (requests: Int, dataMB: Int64) {
        return (dailyRequestCount, dailyDataTransfer / (1024 * 1024))
    }
}

let costManager = NetworkCostManager()

// API 호출 시 비용 추적
let response = try await client.fetchQuote(ticker: ticker)
let responseSize = MemoryLayout.size(ofValue: response) // 추정치
costManager.trackRequest(responseSize: Int64(responseSize))
```

### 2. 배터리 사용량 최적화

모바일 디바이스에서의 배터리 효율성:

```swift
class BatteryEfficientClient {
    private let client = YFClient()
    private var isLowPowerModeEnabled: Bool {
        ProcessInfo.processInfo.isLowPowerModeEnabled
    }
    
    func adaptiveDataFetch(symbols: [String]) async throws -> [YFQuote] {
        let batchSize = isLowPowerModeEnabled ? 3 : 10
        let requestInterval = isLowPowerModeEnabled ? 1.0 : 0.3
        
        var results: [YFQuote] = []
        
        for batch in symbols.chunked(into: batchSize) {
            for symbol in batch {
                let ticker = try YFTicker(symbol: symbol)
                let quote = try await client.fetchQuote(ticker: ticker)
                results.append(quote)
                
                // 저전력 모드에서는 더 긴 간격
                try await Task.sleep(nanoseconds: UInt64(requestInterval * 1_000_000_000))
            }
        }
        
        return results
    }
}
```

### 3. 저장소 비용 관리

```swift
class StorageCostOptimizer {
    private let maxCacheSize: Int64 = 50 * 1024 * 1024 // 50MB
    private var currentCacheSize: Int64 = 0
    
    func addToCache<T: Codable>(_ object: T, key: String) throws {
        let data = try JSONEncoder().encode(object)
        
        if currentCacheSize + Int64(data.count) > maxCacheSize {
            clearOldestCacheEntries()
        }
        
        // 캐시에 저장
        UserDefaults.standard.set(data, forKey: key)
        currentCacheSize += Int64(data.count)
    }
    
    private func clearOldestCacheEntries() {
        // 오래된 캐시 항목 제거
        // 실제 구현에서는 LRU 알고리즘 사용
        currentCacheSize = 0
        print("💾 캐시 정리 완료 - 저장 공간 확보")
    }
}
```

### 4. 비용 모니터링 대시보드

```swift
struct CostReport {
    let networkRequests: Int
    let dataUsageMB: Double
    let cacheHitRate: Double
    let averageResponseTime: TimeInterval
    let batteryImpactScore: Double // 0-100
    
    func printCostSummary() {
        print("💰 일일 비용 리포트")
        print("├─ 네트워크 요청: \(networkRequests)회")
        print("├─ 데이터 사용량: \(String(format: "%.1f", dataUsageMB))MB")
        print("├─ 캐시 적중률: \(String(format: "%.1f", cacheHitRate * 100))%")
        print("├─ 평균 응답시간: \(String(format: "%.2f", averageResponseTime))초")
        print("└─ 배터리 영향도: \(String(format: "%.0f", batteryImpactScore))/100")
        
        // 개선 제안
        if cacheHitRate < 0.7 {
            print("📈 제안: 캐시 적중률 개선 필요")
        }
        if averageResponseTime > 2.0 {
            print("⚡ 제안: 응답 속도 최적화 필요")
        }
        if batteryImpactScore > 70 {
            print("🔋 제안: 배터리 사용량 최적화 필요")
        }
    }
}
```

### 5. 스마트 백그라운드 작업

```swift
import BackgroundTasks

class SmartBackgroundUpdater {
    private let identifier = "com.yourapp.dataupdate"
    
    func scheduleIntelligentUpdate() {
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        
        // 사용자 활동 패턴 기반 스케줄링
        let userActiveHours = getUserActiveHours()
        request.earliestBeginDate = Calendar.current.date(
            byAdding: .hour, 
            value: userActiveHours.contains(Date().hour) ? 1 : 6,
            to: Date()
        )
        
        try? BGTaskScheduler.shared.submit(request)
    }
    
    private func getUserActiveHours() -> Set<Int> {
        // 사용자 활동 패턴 분석 (예: 9시~18시)
        return Set(9...18)
    }
}
```

## Next Steps

성능 최적화를 마스터했다면:

- <doc:ImportantNotices> - 비용 및 제약사항 상세 정보
- <doc:BestPractices> - 전반적인 모범 사례
- <doc:TechnicalAnalysis> - 최적화된 기술적 분석
- <doc:AdvancedFeatures> - 고급 기능과 성능
- <doc:FAQ> - 성능 관련 FAQ