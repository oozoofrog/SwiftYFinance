import Foundation

/// 연결 품질 메트릭
///
/// WebSocket 연결의 품질을 추적하고 측정하는 메트릭 구조체입니다.
/// 연결 성공률, 에러율, 메시지 수신 통계 등을 관리합니다.
internal struct YFWebSocketConnectionQuality {
    private(set) var totalConnections: Int = 0
    private(set) var successfulConnections: Int = 0
    private(set) var totalErrors: Int = 0
    private(set) var messagesReceived: Int = 0
    private(set) var lastSuccessTime: Date?
    private(set) var lastErrorTime: Date?
    
    /// 연결 성공률
    ///
    /// 전체 연결 시도 대비 성공한 연결의 비율을 반환합니다.
    ///
    /// - Returns: 0.0 ~ 1.0 사이의 성공률
    var successRate: Double {
        guard totalConnections > 0 else { return 0.0 }
        return Double(successfulConnections) / Double(totalConnections)
    }
    
    /// 에러율
    ///
    /// 전체 시도 (연결 + 에러) 대비 에러 발생 비율을 반환합니다.
    ///
    /// - Returns: 0.0 ~ 1.0 사이의 에러율
    var errorRate: Double {
        let totalAttempts = totalConnections + totalErrors
        guard totalAttempts > 0 else { return 0.0 }
        return Double(totalErrors) / Double(totalAttempts)
    }
    
    /// 연결 성공 기록
    ///
    /// 성공한 연결을 메트릭에 기록합니다.
    mutating func recordSuccess() {
        totalConnections += 1
        successfulConnections += 1
        lastSuccessTime = Date()
    }
    
    /// 에러 발생 기록
    ///
    /// 발생한 에러를 메트릭에 기록합니다.
    mutating func recordError() {
        totalErrors += 1
        lastErrorTime = Date()
    }
    
    /// 메시지 수신 기록
    ///
    /// 수신한 메시지를 메트릭에 기록합니다.
    mutating func recordMessageReceived() {
        messagesReceived += 1
    }
}