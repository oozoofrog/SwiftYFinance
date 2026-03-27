# Error Handling

SwiftYFinance의 포괄적인 에러 처리 전략

## Overview

SwiftYFinance를 사용할 때 발생할 수 있는 다양한 에러 상황과 이를 효과적으로 처리하는 방법을 다룹니다. 견고한 애플리케이션을 만들기 위한 에러 처리 패턴과 복구 전략을 소개합니다.

## Error Types Overview

### SwiftYFinance 에러 타입

```swift
// YFError의 모든 케이스
enum YFError: Error, LocalizedError {
    case invalidSymbol(String)
    case networkError(Error)
    case rateLimited
    case authenticationFailed
    case dataParsingError(Error)
    case noDataAvailable
    case invalidDateRange
    case serverError(Int)
    case timeout
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidSymbol(let symbol):
            return "잘못된 종목 심볼: \(symbol)"
        case .networkError(let error):
            return "네트워크 에러: \(error.localizedDescription)"
        case .rateLimited:
            return "요청 한도 초과. 잠시 후 다시 시도해주세요."
        case .authenticationFailed:
            return "인증 실패. CSRF 토큰을 확인해주세요."
        case .dataParsingError(let error):
            return "데이터 파싱 에러: \(error.localizedDescription)"
        case .noDataAvailable:
            return "사용 가능한 데이터가 없습니다."
        case .invalidDateRange:
            return "잘못된 날짜 범위입니다."
        case .serverError(let code):
            return "서버 에러 (HTTP \(code))"
        case .timeout:
            return "요청 시간 초과"
        case .unknown:
            return "알 수 없는 에러가 발생했습니다."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidSymbol:
            return "Yahoo Finance에서 정확한 종목 심볼을 확인해주세요."
        case .networkError:
            return "인터넷 연결을 확인하고 다시 시도해주세요."
        case .rateLimited:
            return "5-10분 후에 다시 시도하거나 요청 간격을 늘려주세요."
        case .authenticationFailed:
            return "새로운 세션으로 다시 시도해주세요."
        case .dataParsingError:
            return "API 응답 형식이 변경되었을 수 있습니다. 라이브러리를 업데이트해주세요."
        case .noDataAvailable:
            return "다른 기간이나 종목으로 시도해주세요."
        case .invalidDateRange:
            return "시작일이 종료일보다 이전인지 확인해주세요."
        case .serverError:
            return "Yahoo Finance 서버에 일시적인 문제가 있을 수 있습니다."
        case .timeout:
            return "네트워크 상태를 확인하고 다시 시도해주세요."
        case .unknown:
            return "문제가 지속되면 GitHub Issues에 신고해주세요."
        }
    }
}
```

## Basic Error Handling Patterns

### 기본 에러 처리

```swift
// ✅ 기본적인 에러 처리
func fetchQuoteBasic(symbol: String) async {
    do {
        let ticker = YFTicker(symbol: symbol)
        let quote = try await client.fetchQuote(ticker: ticker)
        
        print("✅ \(symbol): $\(quote.regularMarketPrice)")
        
    } catch YFError.invalidSymbol(let symbol) {
        print("❌ 잘못된 심볼: \(symbol)")
        // 사용자에게 올바른 심볼 입력 요청
        
    } catch YFError.rateLimited {
        print("⏰ 요청 한도 초과. 잠시 후 다시 시도...")
        // UI에 대기 메시지 표시
        
    } catch YFError.networkError(let underlyingError) {
        print("🌐 네트워크 에러: \(underlyingError)")
        // 오프라인 모드로 전환 또는 캐시 데이터 사용
        
    } catch {
        print("❓ 예상치 못한 에러: \(error)")
        // 일반적인 에러 처리
    }
}
```

### 결과 타입을 활용한 에러 처리

```swift
// Result 타입을 활용한 안전한 에러 처리
func fetchQuoteSafe(symbol: String) async -> Result<YFQuote, YFError> {
    do {
        let ticker = YFTicker(symbol: symbol)
        let quote = try await client.fetchQuote(ticker: ticker)
        return .success(quote)
        
    } catch let error as YFError {
        return .failure(error)
        
    } catch {
        return .failure(.unknown)
    }
}

// 사용 예제
let result = await fetchQuoteSafe(symbol: "AAPL")

switch result {
case .success(let quote):
    print("성공: \(quote.symbol) - $\(quote.regularMarketPrice)")
    
case .failure(let error):
    handleError(error)
}

func handleError(_ error: YFError) {
    switch error {
    case .invalidSymbol(let symbol):
        showSymbolValidationError(symbol)
    case .rateLimited:
        showRateLimitWarning()
    case .networkError:
        enableOfflineMode()
    default:
        showGenericError(error)
    }
}
```

## Advanced Error Handling

### 재시도 로직이 있는 에러 처리

```swift
class RobustYFClient {
    private let client = YFClient()
    private let maxRetries: Int
    private let baseDelay: TimeInterval
    
    init(maxRetries: Int = 3, baseDelay: TimeInterval = 1.0) {
        self.maxRetries = maxRetries
        self.baseDelay = baseDelay
    }
    
    func fetchQuoteWithRetry(symbol: String) async throws -> YFQuote {
        return try await withRetry(operation: "fetchQuote(\(symbol))") {
            let ticker = YFTicker(symbol: symbol)
            return try await self.client.fetchQuote(ticker: ticker)
        }
    }
    
    private func withRetry<T>(
        operation: String,
        _ block: () async throws -> T
    ) async throws -> T {
        
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                let result = try await block()
                
                if attempt > 1 {
                    print("✅ \(operation) 성공 (시도 \(attempt)/\(maxRetries))")
                }
                
                return result
                
            } catch let error as YFError {
                lastError = error
                
                let shouldRetry = shouldRetryForError(error, attempt: attempt)
                
                if shouldRetry && attempt < maxRetries {
                    let delay = calculateDelay(for: error, attempt: attempt)
                    print("🔄 \(operation) 재시도 \(attempt + 1)/\(maxRetries) (\(delay)초 후)")
                    
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                } else {
                    throw error
                }
                
            } catch {
                lastError = error
                
                if attempt == maxRetries {
                    throw error
                } else {
                    let delay = baseDelay * Double(attempt)
                    print("🔄 \(operation) 알 수 없는 에러 재시도 (\(delay)초 후)")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? YFError.unknown
    }
    
    private func shouldRetryForError(_ error: YFError, attempt: Int) -> Bool {
        switch error {
        case .networkError:
            return true // 네트워크 에러는 항상 재시도
        case .timeout:
            return true // 타임아웃도 재시도
        case .serverError(let code):
            return code >= 500 // 5xx 서버 에러만 재시도
        case .rateLimited:
            return attempt <= 2 // Rate limit은 최대 2번만 재시도
        case .authenticationFailed:
            return attempt == 1 // 인증 실패는 1번만 재시도
        case .invalidSymbol, .noDataAvailable, .invalidDateRange:
            return false // 이런 에러들은 재시도 불필요
        default:
            return false
        }
    }
    
    private func calculateDelay(for error: YFError, attempt: Int) -> TimeInterval {
        switch error {
        case .rateLimited:
            // Rate limit은 지수적으로 증가하는 대기 시간
            return baseDelay * pow(3.0, Double(attempt))
        case .networkError, .timeout:
            // 네트워크 에러는 지수 백오프
            return baseDelay * pow(2.0, Double(attempt - 1))
        case .serverError:
            // 서버 에러는 선형 증가
            return baseDelay * Double(attempt)
        case .authenticationFailed:
            // 인증 실패는 긴 대기
            return baseDelay * 5.0
        default:
            return baseDelay
        }
    }
}
```

### 회로 차단기 패턴 (Circuit Breaker)

```swift
actor CircuitBreaker {
    enum State {
        case closed    // 정상 동작
        case open      // 에러가 많아서 차단됨
        case halfOpen  // 복구 시도 중
    }
    
    private var state: State = .closed
    private var failureCount: Int = 0
    private var lastFailureTime: Date?
    private var successCount: Int = 0
    
    private let maxFailures: Int
    private let timeout: TimeInterval
    private let maxSuccessInHalfOpen: Int
    
    init(maxFailures: Int = 5, timeout: TimeInterval = 60, maxSuccessInHalfOpen: Int = 3) {
        self.maxFailures = maxFailures
        self.timeout = timeout
        self.maxSuccessInHalfOpen = maxSuccessInHalfOpen
    }
    
    func execute<T>(_ operation: () async throws -> T) async throws -> T {
        switch state {
        case .closed:
            return try await executeInClosedState(operation)
        case .open:
            try await checkIfCanTransitionToHalfOpen()
            throw YFError.rateLimited // 여전히 차단 상태면 에러
        case .halfOpen:
            return try await executeInHalfOpenState(operation)
        }
    }
    
    private func executeInClosedState<T>(_ operation: () async throws -> T) async throws -> T {
        do {
            let result = try await operation()
            reset() // 성공 시 리셋
            return result
        } catch {
            recordFailure()
            if failureCount >= maxFailures {
                transitionToOpen()
            }
            throw error
        }
    }
    
    private func executeInHalfOpenState<T>(_ operation: () async throws -> T) async throws -> T {
        do {
            let result = try await operation()
            recordSuccess()
            if successCount >= maxSuccessInHalfOpen {
                transitionToClosed()
            }
            return result
        } catch {
            transitionToOpen()
            throw error
        }
    }
    
    private func checkIfCanTransitionToHalfOpen() async throws {
        guard let lastFailureTime = lastFailureTime else { return }
        
        if Date().timeIntervalSince(lastFailureTime) >= timeout {
            transitionToHalfOpen()
        }
    }
    
    private func recordFailure() {
        failureCount += 1
        lastFailureTime = Date()
        successCount = 0
    }
    
    private func recordSuccess() {
        successCount += 1
        failureCount = 0
    }
    
    private func reset() {
        failureCount = 0
        successCount = 0
        lastFailureTime = nil
    }
    
    private func transitionToOpen() {
        state = .open
        print("🔴 Circuit Breaker OPEN - API 호출 차단")
    }
    
    private func transitionToHalfOpen() {
        state = .halfOpen
        successCount = 0
        print("🟡 Circuit Breaker HALF-OPEN - 복구 시도")
    }
    
    private func transitionToClosed() {
        state = .closed
        reset()
        print("🟢 Circuit Breaker CLOSED - 정상 복구")
    }
    
    var currentState: State {
        state
    }
    
    var stats: (state: State, failures: Int, successes: Int) {
        (state, failureCount, successCount)
    }
}

// Circuit Breaker를 사용하는 클라이언트
class ReliableYFClient {
    private let client = YFClient()
    private let circuitBreaker = CircuitBreaker()
    
    func fetchQuote(symbol: String) async throws -> YFQuote {
        return try await circuitBreaker.execute {
            let ticker = YFTicker(symbol: symbol)
            return try await self.client.fetchQuote(ticker: ticker)
        }
    }
    
    func getCircuitBreakerStatus() async -> (state: CircuitBreaker.State, failures: Int, successes: Int) {
        return await circuitBreaker.stats
    }
}
```

## Error Recovery Strategies

### 폴백 데이터 전략

```swift
class FallbackDataManager {
    private let primaryClient = YFClient()
    private let cache = QuoteCache()
    private let localStorage = LocalStorage()
    
    func fetchQuoteWithFallback(symbol: String) async -> YFQuote? {
        // 1단계: 메인 API 시도
        do {
            let ticker = YFTicker(symbol: symbol)
            let quote = try await primaryClient.fetchQuote(ticker: ticker)
            
            // 성공시 캐시에 저장
            cache.set(symbol: symbol, quote: quote)
            await localStorage.saveQuote(quote)
            
            return quote
            
        } catch let error as YFError {
            print("⚠️ Primary API 실패: \(error.localizedDescription)")
            
            // 2단계: 캐시에서 시도
            if let cachedQuote = cache.get(symbol: symbol) {
                print("💾 캐시에서 데이터 반환: \(symbol)")
                return cachedQuote
            }
            
            // 3단계: 로컬 스토리지에서 시도
            if let storedQuote = await localStorage.loadQuote(symbol: symbol) {
                print("💽 로컬 저장소에서 데이터 반환: \(symbol)")
                return storedQuote
            }
            
            // 4단계: 기본값 또는 추정값 반환
            return await generateEstimatedQuote(symbol: symbol)
        }
    }
    
    private func generateEstimatedQuote(symbol: String) async -> YFQuote? {
        // 과거 데이터를 기반으로 추정값 생성
        guard let historicalData = await localStorage.loadHistoricalData(symbol: symbol),
              let lastPrice = historicalData.prices.last else {
            print("❌ 폴백 데이터 없음: \(symbol)")
            return nil
        }
        
        print("📊 추정 데이터 생성: \(symbol)")
        
        return YFQuote(
            symbol: symbol,
            regularMarketPrice: lastPrice.close,
            regularMarketTime: Date(),
            // 기타 필드들을 과거 데이터나 기본값으로 설정
            marketCap: nil,
            regularMarketVolume: nil
        )
    }
}

// 로컬 스토리지 구현
actor LocalStorage {
    private let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    
    func saveQuote(_ quote: YFQuote) async {
        do {
            let fileURL = documentsPath.appendingPathComponent("\(quote.symbol)_quote.json")
            let data = try JSONEncoder().encode(quote)
            try data.write(to: fileURL)
        } catch {
            print("💽 저장 실패: \(error)")
        }
    }
    
    func loadQuote(symbol: String) async -> YFQuote? {
        do {
            let fileURL = documentsPath.appendingPathComponent("\(symbol)_quote.json")
            let data = try Data(contentsOf: fileURL)
            let quote = try JSONDecoder().decode(YFQuote.self, from: data)
            
            // 데이터가 너무 오래되었는지 확인
            let dataAge = Date().timeIntervalSince(quote.regularMarketTime)
            if dataAge > 24 * 3600 { // 24시간 이상 오래됨
                return nil
            }
            
            return quote
        } catch {
            return nil
        }
    }
    
    func loadHistoricalData(symbol: String) async -> YFHistoricalData? {
        do {
            let fileURL = documentsPath.appendingPathComponent("\(symbol)_history.json")
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(YFHistoricalData.self, from: data)
        } catch {
            return nil
        }
    }
}
```

### 부분 실패 처리

```swift
struct BulkFetchResult {
    let successful: [String: YFQuote]
    let failed: [String: Error]
    let partial: [String: YFQuote] // 부분적으로 성공한 데이터
    
    var totalRequested: Int {
        successful.count + failed.count + partial.count
    }
    
    var successRate: Double {
        let successCount = successful.count + partial.count
        return Double(successCount) / Double(totalRequested)
    }
}

class BulkQuoteFetcher {
    private let client = YFClient()
    private let fallbackManager = FallbackDataManager()
    
    func fetchQuotes(symbols: [String], toleratePartialFailure: Bool = true) async -> BulkFetchResult {
        var successful: [String: YFQuote] = [:]
        var failed: [String: Error] = [:]
        var partial: [String: YFQuote] = [:]
        
        for symbol in symbols {
            do {
                let ticker = YFTicker(symbol: symbol)
                let quote = try await client.fetchQuote(ticker: ticker)
                
                // 데이터 품질 검증
                let qualityIssues = validateQuoteQuality(quote)
                
                if qualityIssues.isEmpty {
                    successful[symbol] = quote
                } else if toleratePartialFailure {
                    print("⚠️ \(symbol) 품질 이슈: \(qualityIssues.joined(separator: ", "))")
                    partial[symbol] = quote
                } else {
                    failed[symbol] = YFError.dataParsingError(NSError(domain: "DataQuality", code: 1, userInfo: [NSLocalizedDescriptionKey: qualityIssues.joined(separator: ", ")]))
                }
                
            } catch {
                // 폴백 시도
                if toleratePartialFailure,
                   let fallbackQuote = await fallbackManager.fetchQuoteWithFallback(symbol: symbol) {
                    partial[symbol] = fallbackQuote
                } else {
                    failed[symbol] = error
                }
            }
            
            // Rate limiting
            try? await Task.sleep(nanoseconds: 200_000_000)
        }
        
        let result = BulkFetchResult(successful: successful, failed: failed, partial: partial)
        logBulkFetchResult(result)
        
        return result
    }
    
    private func validateQuoteQuality(_ quote: YFQuote) -> [String] {
        var issues: [String] = []
        
        if quote.regularMarketPrice <= 0 {
            issues.append("invalid price")
        }
        
        if let volume = quote.regularMarketVolume, volume < 0 {
            issues.append("negative volume")
        }
        
        let dataAge = Date().timeIntervalSince(quote.regularMarketTime)
        if dataAge > 24 * 3600 {
            issues.append("stale data")
        }
        
        return issues
    }
    
    private func logBulkFetchResult(_ result: BulkFetchResult) {
        print("\n📊 대량 조회 결과:")
        print("  총 요청: \(result.totalRequested)개")
        print("  성공: \(result.successful.count)개")
        print("  부분 성공: \(result.partial.count)개")
        print("  실패: \(result.failed.count)개")
        print("  성공률: \(String(format: "%.1f", result.successRate * 100))%")
        
        if !result.failed.isEmpty {
            print("\n❌ 실패한 종목들:")
            for (symbol, error) in result.failed {
                print("  \(symbol): \(error.localizedDescription)")
            }
        }
    }
}
```

## Error Monitoring and Logging

### 구조화된 에러 로깅

```swift
import os.log

struct ErrorLogger {
    private static let subsystem = "com.yourapp.swift-yf-tools"
    private static let errorLogger = Logger(subsystem: subsystem, category: "errors")
    private static let metricsLogger = Logger(subsystem: subsystem, category: "metrics")
    
    static func logError(
        _ error: Error,
        context: String,
        metadata: [String: Any] = [:]
    ) {
        let errorInfo = ErrorInfo(
            error: error,
            context: context,
            metadata: metadata,
            timestamp: Date(),
            threadInfo: Thread.current.description
        )
        
        if let yfError = error as? YFError {
            logYFError(yfError, info: errorInfo)
        } else {
            logGenericError(error, info: errorInfo)
        }
        
        // 에러 메트릭 업데이트
        updateErrorMetrics(error: error, context: context)
    }
    
    private static func logYFError(_ error: YFError, info: ErrorInfo) {
        switch error {
        case .invalidSymbol(let symbol):
            errorLogger.error("Invalid symbol: \(symbol) | Context: \(info.context)")
            
        case .rateLimited:
            errorLogger.warning("Rate limited | Context: \(info.context)")
            
        case .networkError(let underlyingError):
            errorLogger.error("Network error: \(underlyingError) | Context: \(info.context)")
            
        case .authenticationFailed:
            errorLogger.error("Authentication failed | Context: \(info.context)")
            
        case .serverError(let code):
            errorLogger.error("Server error HTTP \(code) | Context: \(info.context)")
            
        default:
            errorLogger.error("YF Error: \(error.localizedDescription) | Context: \(info.context)")
        }
    }
    
    private static func logGenericError(_ error: Error, info: ErrorInfo) {
        errorLogger.error("Generic error: \(error.localizedDescription) | Context: \(info.context) | Type: \(type(of: error))")
    }
    
    private static func updateErrorMetrics(error: Error, context: String) {
        Task {
            await ErrorMetrics.shared.recordError(type: String(describing: type(of: error)), context: context)
        }
    }
}

struct ErrorInfo {
    let error: Error
    let context: String
    let metadata: [String: Any]
    let timestamp: Date
    let threadInfo: String
}

// 에러 메트릭 수집
actor ErrorMetrics {
    static let shared = ErrorMetrics()
    
    private var errorCounts: [String: Int] = [:]
    private var contextCounts: [String: Int] = [:]
    private var lastResetTime = Date()
    
    func recordError(type: String, context: String) {
        errorCounts[type, default: 0] += 1
        contextCounts[context, default: 0] += 1
    }
    
    func getMetrics() -> (errors: [String: Int], contexts: [String: Int], period: TimeInterval) {
        let period = Date().timeIntervalSince(lastResetTime)
        return (errorCounts, contextCounts, period)
    }
    
    func resetMetrics() {
        errorCounts.removeAll()
        contextCounts.removeAll()
        lastResetTime = Date()
    }
    
    func getTopErrors(limit: Int = 5) -> [(type: String, count: Int)] {
        return errorCounts.sorted { $0.value > $1.value }
                         .prefix(limit)
                         .map { (type: $0.key, count: $0.value) }
    }
}
```

### 에러 알림 시스템

```swift
protocol ErrorNotificationDelegate: AnyObject {
    func shouldNotifyUser(for error: YFError) -> Bool
    func notifyUser(error: YFError, suggestion: String?)
    func logCriticalError(error: Error, context: String)
}

class ErrorNotificationManager {
    weak var delegate: ErrorNotificationDelegate?
    private let criticalErrorThreshold = 5
    private var recentErrors: [Date] = []
    private let errorWindow: TimeInterval = 300 // 5분
    
    func handleError(_ error: Error, context: String) {
        ErrorLogger.logError(error, context: context)
        
        // 임계 에러 빈도 체크
        cleanupOldErrors()
        recentErrors.append(Date())
        
        if recentErrors.count >= criticalErrorThreshold {
            delegate?.logCriticalError(error: error, context: "High error frequency: \(recentErrors.count) errors in \(errorWindow/60) minutes")
        }
        
        // YFError 처리
        if let yfError = error as? YFError {
            handleYFError(yfError, context: context)
        }
    }
    
    private func handleYFError(_ error: YFError, context: String) {
        guard let delegate = delegate else { return }
        
        if delegate.shouldNotifyUser(for: error) {
            let suggestion = error.recoverySuggestion
            delegate.notifyUser(error: error, suggestion: suggestion)
        }
        
        // 자동 복구 시도
        Task {
            await attemptAutoRecovery(for: error, context: context)
        }
    }
    
    private func attemptAutoRecovery(for error: YFError, context: String) async {
        switch error {
        case .authenticationFailed:
            print("🔄 CSRF 재인증 시도...")
            do {
                let session = YFSession()
                try await session.authenticateCSRF()
                print("✅ 자동 재인증 성공")
            } catch {
                print("❌ 자동 재인증 실패: \(error)")
            }
            
        case .rateLimited:
            print("⏰ Rate limit 자동 대기...")
            try? await Task.sleep(nanoseconds: 10_000_000_000) // 10초
            print("✅ Rate limit 대기 완료")
            
        default:
            break
        }
    }
    
    private func cleanupOldErrors() {
        let cutoffTime = Date().addingTimeInterval(-errorWindow)
        recentErrors = recentErrors.filter { $0 > cutoffTime }
    }
}

// 사용 예제
class MyApp: ErrorNotificationDelegate {
    private let errorManager = ErrorNotificationManager()
    
    init() {
        errorManager.delegate = self
    }
    
    func shouldNotifyUser(for error: YFError) -> Bool {
        switch error {
        case .invalidSymbol, .noDataAvailable:
            return true // 사용자가 알아야 할 에러
        case .networkError, .timeout:
            return true // 네트워크 관련 에러도 알림
        case .rateLimited:
            return false // Rate limit은 자동 처리
        default:
            return false
        }
    }
    
    func notifyUser(error: YFError, suggestion: String?) {
        DispatchQueue.main.async {
            // UI 에러 알림 표시
            self.showErrorAlert(
                title: "오류 발생",
                message: error.localizedDescription,
                suggestion: suggestion
            )
        }
    }
    
    func logCriticalError(error: Error, context: String) {
        // 크리티컬 에러는 외부 로깅 서비스로 전송
        print("🚨 CRITICAL ERROR: \(error) | Context: \(context)")
        // sendToExternalLoggingService(error, context)
    }
    
    private func showErrorAlert(title: String, message: String, suggestion: String?) {
        // UI 알림 구현
        print("🔔 사용자 알림: \(title) - \(message)")
        if let suggestion = suggestion {
            print("💡 제안: \(suggestion)")
        }
    }
}
```

## Testing Error Scenarios

### 에러 시나리오 테스트

```swift
class ErrorTestHelper {
    static func simulateNetworkError() throws -> Never {
        throw YFError.networkError(URLError(.notConnectedToInternet))
    }
    
    static func simulateRateLimit() throws -> Never {
        throw YFError.rateLimited
    }
    
    static func simulateInvalidSymbol(_ symbol: String) throws -> Never {
        throw YFError.invalidSymbol(symbol)
    }
    
    static func simulateRandomError() throws -> Never {
        let errors: [YFError] = [
            .networkError(URLError(.timedOut)),
            .rateLimited,
            .authenticationFailed,
            .serverError(500),
            .noDataAvailable
        ]
        
        throw errors.randomElement()!
    }
}

// 에러 처리 테스트
class ErrorHandlingTests {
    func testRetryLogic() async {
        let robustClient = RobustYFClient(maxRetries: 3, baseDelay: 0.1)
        
        do {
            // 실제로는 실패할 가능성이 높은 요청
            let quote = try await robustClient.fetchQuoteWithRetry(symbol: "INVALID_SYMBOL")
            print("예상치 못한 성공: \(quote)")
        } catch {
            print("예상된 최종 실패: \(error)")
        }
    }
    
    func testCircuitBreaker() async {
        let reliableClient = ReliableYFClient()
        
        // 연속 실패를 시뮬레이션하여 Circuit Breaker 동작 확인
        for i in 1...10 {
            do {
                let quote = try await reliableClient.fetchQuote(symbol: "FAIL_SYMBOL")
                print("\(i): 성공 - \(quote)")
            } catch {
                print("\(i): 실패 - \(error)")
                
                let status = await reliableClient.getCircuitBreakerStatus()
                print("   Circuit Breaker 상태: \(status.state)")
            }
        }
    }
    
    func testBulkFetchResilience() async {
        let fetcher = BulkQuoteFetcher()
        let symbols = ["AAPL", "INVALID1", "GOOGL", "INVALID2", "MSFT"]
        
        let result = await fetcher.fetchQuotes(symbols: symbols, toleratePartialFailure: true)
        
        print("성공률: \(result.successRate)")
        print("성공: \(result.successful.keys.sorted())")
        print("실패: \(result.failed.keys.sorted())")
        print("부분: \(result.partial.keys.sorted())")
    }
}
```

## Next Steps

에러 처리를 마스터했다면:

- <doc:BestPractices> - 전반적인 모범 사례
- <doc:PerformanceOptimization> - 성능과 안정성 최적화
- <doc:TechnicalAnalysis> - 견고한 기술적 분석 구현
- <doc:FAQ> - 에러 관련 FAQ