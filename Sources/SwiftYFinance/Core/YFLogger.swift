import Foundation
import OSLog

/// SwiftYFinance 구조화된 로깅 시스템
///
/// OSLog(os.Logger)를 기반으로 카테고리별 로깅을 제공합니다.
/// Instruments 등 Apple 도구에서 로그를 확인할 수 있습니다.
///
/// ## 사용 예시
/// ```swift
/// YFLogger.service.info("서비스 시작")
/// YFLogger.network.error("네트워크 오류: \(error.localizedDescription)")
/// ```
///
/// ## 설계 원칙
/// - 함수 진입/종료 로그 제거 → 의미 있는 이벤트만 로깅
/// - OSLog를 사용하여 Instruments에서 추적 가능
/// - 카테고리로 로그 분류 (서비스, 네트워크, WebSocket, 인증)
struct YFLogger: Sendable {

    // MARK: - 공유 로거 인스턴스 (카테고리별)

    /// 서비스 레이어 로거 (YFService, YFServiceCore)
    static let service = YFLogger(category: "Service")

    /// 네트워크 레이어 로거 (HTTP 요청/응답)
    static let network = YFLogger(category: "Network")

    /// WebSocket 로거 (YFWebSocketClient)
    static let webSocket = YFLogger(category: "WebSocket")

    /// 인증 로거 (CSRF, 쿠키)
    static let auth = YFLogger(category: "Auth")

    /// 파싱 로거 (JSON, Protobuf)
    static let parser = YFLogger(category: "Parser")

    // MARK: - 내부 상태

    private let logger: Logger

    // MARK: - 초기화

    /// YFLogger 초기화
    /// - Parameter category: 로그 카테고리 식별자
    init(category: String) {
        self.logger = Logger(subsystem: "com.swiftyftools", category: category)
    }

    // MARK: - 로깅 메서드

    /// 디버그 수준 로그 (개발 중에만 표시)
    /// - Parameter message: 로그 메시지
    func debug(_ message: String) {
        logger.debug("\(message, privacy: .public)")
    }

    /// 정보 수준 로그 (일반적인 이벤트)
    /// - Parameter message: 로그 메시지
    func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
    }

    /// 경고 수준 로그 (주의가 필요한 상황)
    /// - Parameter message: 로그 메시지
    func warning(_ message: String) {
        logger.warning("\(message, privacy: .public)")
    }

    /// 오류 수준 로그 (에러 발생)
    /// - Parameter message: 로그 메시지
    func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
    }
}
