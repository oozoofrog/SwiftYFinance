import Foundation
import os

/// 네트워크 요청/응답 로깅 시스템
/// 
/// Yahoo Finance API 통신의 디버깅 및 모니터링을 위한 로깅 시스템입니다.
/// Phase 4.5.3 네트워크 계층 최적화의 일환으로 구현되었습니다.
///
/// ## 기능
/// - **요청/응답 로깅**: 모든 HTTP 통신 기록
/// - **에러 분류**: 네트워크 에러 타입별 분류 및 통계
/// - **성능 측정**: 응답 시간 및 처리량 모니터링
/// - **디버깅 지원**: 상세 로그 및 트러블슈팅 정보
///
/// ## 사용 예시
/// ```swift
/// let logger = YFNetworkLogger.shared
/// logger.logRequest(request, for: "quoteSummary")
/// logger.logResponse(response, data: data, duration: 1.2)
/// ```
public final class YFNetworkLogger: @unchecked Sendable {
    
    // MARK: - Singleton
    public static let shared = YFNetworkLogger()
    
    // MARK: - Properties
    private let logger: Logger
    private var requestStats: [String: RequestStats] = [:]
    private let statsLock = NSLock()
    
    // MARK: - Types
    
    /// 요청 통계 정보
    public struct RequestStats {
        var totalRequests: Int = 0
        var successRequests: Int = 0
        var errorRequests: Int = 0
        var totalDuration: TimeInterval = 0
        var errorTypes: [String: Int] = [:]
        
        var successRate: Double {
            guard totalRequests > 0 else { return 0.0 }
            return Double(successRequests) / Double(totalRequests)
        }
        
        var averageDuration: TimeInterval {
            guard totalRequests > 0 else { return 0.0 }
            return totalDuration / Double(totalRequests)
        }
    }
    
    /// 로그 레벨
    public enum LogLevel {
        case debug    // 상세 디버깅 정보
        case info     // 일반 정보
        case warning  // 경고
        case error    // 에러
    }
    
    // MARK: - Initialization
    
    private init() {
        self.logger = Logger(subsystem: "com.swiftyfinance", category: "NetworkLogger")
    }
    
    // MARK: - Public Methods
    
    /// HTTP 요청 로깅
    /// - Parameters:
    ///   - request: URLRequest 객체
    ///   - endpoint: API 엔드포인트 식별자
    public func logRequest(_ request: URLRequest, for endpoint: String) {
        let method = request.httpMethod ?? "GET"
        let url = request.url?.absoluteString ?? "unknown"
        
        logger.info("🌐 [REQUEST] \(endpoint) \(method) \(url)")
        
        // 헤더 로깅 (디버그 모드)
        #if DEBUG
        if let headers = request.allHTTPHeaderFields {
            for (key, value) in headers {
                // 민감한 정보 마스킹
                let maskedValue = maskSensitiveValue(key: key, value: value)
                logger.debug("  📋 \(key): \(maskedValue)")
            }
        }
        #endif
        
        // 통계 업데이트
        updateRequestStats(for: endpoint, increment: \.totalRequests)
    }
    
    /// HTTP 응답 로깅
    /// - Parameters:
    ///   - response: HTTPURLResponse 객체
    ///   - data: 응답 데이터
    ///   - duration: 요청 처리 시간
    ///   - endpoint: API 엔드포인트 식별자
    public func logResponse(_ response: HTTPURLResponse?, data: Data?, duration: TimeInterval, for endpoint: String) {
        let statusCode = response?.statusCode ?? 0
        let dataSize = data?.count ?? 0
        let statusIcon = getStatusIcon(for: statusCode)
        
        logger.info("\(statusIcon) [RESPONSE] \(endpoint) \(statusCode) (\(dataSize) bytes) in \(String(format: "%.3f", duration))s")
        
        // 응답 헤더 로깅 (디버그 모드)
        #if DEBUG
        if let headers = response?.allHeaderFields {
            for (key, value) in headers {
                logger.debug("  📋 \(String(describing: key)): \(String(describing: value))")
            }
        }
        #endif
        
        // 통계 업데이트
        updateRequestStats(for: endpoint, duration: duration)
        
        if statusCode >= 200 && statusCode < 300 {
            updateRequestStats(for: endpoint, increment: \.successRequests)
        } else {
            updateRequestStats(for: endpoint, increment: \.errorRequests)
            logError(statusCode: statusCode, for: endpoint)
        }
    }
    
    /// 네트워크 에러 로깅
    /// - Parameters:
    ///   - error: 에러 객체
    ///   - endpoint: API 엔드포인트 식별자
    public func logError(_ error: Error, for endpoint: String) {
        let errorDescription = error.localizedDescription
        let errorType = String(describing: type(of: error))
        
        logger.error("❌ [ERROR] \(endpoint) \(errorType): \(errorDescription)")
        
        // 에러 타입별 통계 업데이트
        updateErrorStats(for: endpoint, errorType: errorType)
        updateRequestStats(for: endpoint, increment: \.errorRequests)
    }
    
    /// 특정 엔드포인트의 통계 반환
    /// - Parameter endpoint: API 엔드포인트 식별자
    /// - Returns: 요청 통계 정보
    public func getStats(for endpoint: String) -> RequestStats? {
        statsLock.lock()
        defer { statsLock.unlock() }
        return requestStats[endpoint]
    }
    
    /// 모든 엔드포인트 통계 반환
    /// - Returns: 전체 요청 통계 정보
    public func getAllStats() -> [String: RequestStats] {
        statsLock.lock()
        defer { statsLock.unlock() }
        return requestStats
    }
    
    /// 통계 초기화
    public func resetStats() {
        statsLock.lock()
        defer { statsLock.unlock() }
        requestStats.removeAll()
        logger.info("📊 [STATS] Statistics reset")
    }
    
    /// 통계 요약 출력
    public func printStatsSummary() {
        statsLock.lock()
        let stats = requestStats
        statsLock.unlock()
        
        logger.info("📊 === Network Statistics Summary ===")
        
        for (endpoint, stat) in stats {
            logger.info("🎯 \(endpoint):")
            logger.info("   Total: \(stat.totalRequests), Success: \(stat.successRequests), Error: \(stat.errorRequests)")
            logger.info("   Success Rate: \(String(format: "%.1f", stat.successRate * 100))%")
            logger.info("   Avg Duration: \(String(format: "%.3f", stat.averageDuration))s")
            
            if !stat.errorTypes.isEmpty {
                logger.info("   Error Types: \(stat.errorTypes)")
            }
        }
        
        logger.info("📊 ===================================")
    }
    
    // MARK: - Private Methods
    
    /// 상태 코드에 따른 아이콘 반환
    private func getStatusIcon(for statusCode: Int) -> String {
        switch statusCode {
        case 200..<300: return "✅"
        case 300..<400: return "🔄"
        case 400..<500: return "⚠️"
        case 500..<600: return "❌"
        default: return "❓"
        }
    }
    
    /// 민감한 정보 마스킹
    private func maskSensitiveValue(key: String, value: String) -> String {
        let sensitiveKeys = ["Authorization", "Cookie", "crumb", "csrf"]
        
        if sensitiveKeys.contains(where: { key.localizedCaseInsensitiveContains($0) }) {
            return "***MASKED***"
        }
        
        return value
    }
    
    /// 요청 통계 업데이트
    private func updateRequestStats(for endpoint: String, increment keyPath: WritableKeyPath<RequestStats, Int>) {
        statsLock.lock()
        defer { statsLock.unlock() }
        
        if requestStats[endpoint] == nil {
            requestStats[endpoint] = RequestStats()
        }
        
        requestStats[endpoint]![keyPath: keyPath] += 1
    }
    
    /// 요청 통계 업데이트 (duration)
    private func updateRequestStats(for endpoint: String, duration: TimeInterval) {
        statsLock.lock()
        defer { statsLock.unlock() }
        
        if requestStats[endpoint] == nil {
            requestStats[endpoint] = RequestStats()
        }
        
        requestStats[endpoint]!.totalDuration += duration
    }
    
    /// 에러 통계 업데이트
    private func updateErrorStats(for endpoint: String, errorType: String) {
        statsLock.lock()
        defer { statsLock.unlock() }
        
        if requestStats[endpoint] == nil {
            requestStats[endpoint] = RequestStats()
        }
        
        requestStats[endpoint]!.errorTypes[errorType, default: 0] += 1
    }
    
    /// HTTP 상태 코드 에러 로깅
    private func logError(statusCode: Int, for endpoint: String) {
        let errorMessage: String
        
        switch statusCode {
        case 401:
            errorMessage = "Unauthorized - Authentication failed"
        case 403:
            errorMessage = "Forbidden - Access denied"
        case 404:
            errorMessage = "Not Found - Endpoint not available"
        case 429:
            errorMessage = "Too Many Requests - Rate limited"
        case 500..<600:
            errorMessage = "Server Error - Yahoo Finance server issue"
        default:
            errorMessage = "HTTP Error \(statusCode)"
        }
        
        logger.error("⚠️ [HTTP_ERROR] \(endpoint) \(statusCode): \(errorMessage)")
        updateErrorStats(for: endpoint, errorType: "HTTP_\(statusCode)")
    }
}
