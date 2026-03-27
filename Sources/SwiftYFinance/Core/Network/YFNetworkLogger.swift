import Foundation
import os

/// 네트워크 요청/응답 로깅 시스템
///
/// Yahoo Finance API 통신의 디버깅 및 모니터링을 위한 로깅 시스템입니다.
/// actor 기반으로 Swift 6.1 strict concurrency를 완전 지원합니다.
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
/// await logger.logRequest(request, for: "quoteSummary")
/// await logger.logResponse(response, data: data, duration: 1.2, for: "quoteSummary")
/// ```
public actor YFNetworkLogger {

    // MARK: - Singleton
    public static let shared = YFNetworkLogger()

    // MARK: - Properties
    private let logger: Logger
    // actor isolation이 requestStats의 동시 접근을 자동으로 보호합니다.
    private var requestStats: [String: RequestStats] = [:]

    // MARK: - Types

    /// 요청 통계 정보
    public struct RequestStats: Sendable {
        public var totalRequests: Int = 0
        public var successRequests: Int = 0
        public var errorRequests: Int = 0
        public var totalDuration: TimeInterval = 0
        public var errorTypes: [String: Int] = [:]

        public var successRate: Double {
            guard totalRequests > 0 else { return 0.0 }
            return Double(successRequests) / Double(totalRequests)
        }

        public var averageDuration: TimeInterval {
            guard totalRequests > 0 else { return 0.0 }
            return totalDuration / Double(totalRequests)
        }
    }

    /// 로그 레벨
    public enum LogLevel: Sendable {
        case debug    // 상세 디버깅 정보
        case info     // 일반 정보
        case warning  // 경고
        case error    // 에러
    }

    // MARK: - Initialization

    private init() {
        self.logger = Logger(subsystem: "com.swiftyftools", category: "NetworkLogger")
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
        incrementStat(for: endpoint, keyPath: \.totalRequests)
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
        addDuration(duration, for: endpoint)

        if statusCode >= 200 && statusCode < 300 {
            incrementStat(for: endpoint, keyPath: \.successRequests)
        } else {
            incrementStat(for: endpoint, keyPath: \.errorRequests)
            logHTTPError(statusCode: statusCode, for: endpoint)
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
        addErrorType(errorType, for: endpoint)
        incrementStat(for: endpoint, keyPath: \.errorRequests)
    }

    /// 특정 엔드포인트의 통계 반환
    /// - Parameter endpoint: API 엔드포인트 식별자
    /// - Returns: 요청 통계 정보
    public func getStats(for endpoint: String) -> RequestStats? {
        return requestStats[endpoint]
    }

    /// 모든 엔드포인트 통계 반환
    /// - Returns: 전체 요청 통계 정보
    public func getAllStats() -> [String: RequestStats] {
        return requestStats
    }

    /// 통계 초기화
    public func resetStats() {
        requestStats.removeAll()
        logger.info("📊 [STATS] Statistics reset")
    }

    /// 통계 요약 출력
    public func printStatsSummary() {
        let stats = requestStats

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

    /// 카운터 증가 (actor 내부에서 호출)
    private func incrementStat(for endpoint: String, keyPath: WritableKeyPath<RequestStats, Int>) {
        if requestStats[endpoint] == nil {
            requestStats[endpoint] = RequestStats()
        }
        requestStats[endpoint]![keyPath: keyPath] += 1
    }

    /// duration 합산 (actor 내부에서 호출)
    private func addDuration(_ duration: TimeInterval, for endpoint: String) {
        if requestStats[endpoint] == nil {
            requestStats[endpoint] = RequestStats()
        }
        requestStats[endpoint]!.totalDuration += duration
        requestStats[endpoint]!.totalRequests += 1
    }

    /// 에러 타입 추가 (actor 내부에서 호출)
    private func addErrorType(_ errorType: String, for endpoint: String) {
        if requestStats[endpoint] == nil {
            requestStats[endpoint] = RequestStats()
        }
        requestStats[endpoint]!.errorTypes[errorType, default: 0] += 1
    }

    /// HTTP 상태 코드 에러 로깅
    private func logHTTPError(statusCode: Int, for endpoint: String) {
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
        addErrorType("HTTP_\(statusCode)", for: endpoint)
    }
}
