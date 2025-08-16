import Foundation

/// 상태 전환 로그 엔트리
///
/// WebSocket 연결 상태 전환을 추적하고 기록하는 구조체입니다.
/// 디버깅과 모니터링을 위해 상태 변화의 이력을 관리합니다.
internal struct YFWebSocketStateTransition {
    /// 이전 연결 상태
    let fromState: YFWebSocketConnectionState
    
    /// 새로운 연결 상태
    let toState: YFWebSocketConnectionState
    
    /// 상태 전환 시간
    let timestamp: Date
    
    /// 상태 전환 이유
    let reason: String
    
    /// 로그 문자열 표현
    ///
    /// 상태 전환 정보를 사람이 읽기 쉬운 형태로 포매팅합니다.
    ///
    /// - Returns: 포매팅된 상태 전환 로그 문자열
    var description: String {
        return "\(timestamp): \(fromState) -> \(toState) (\(reason))"
    }
}