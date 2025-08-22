import Foundation

/// WebSocket 연결 상태
///
/// Yahoo Finance WebSocket 연결의 현재 상태를 나타내는 열거형입니다.
/// 연결 생명주기의 모든 단계를 추적하며, 상태 전환 유효성 검사에 사용됩니다.
public enum YFWebSocketConnectionState: Equatable, Sendable {
    /// 연결 해제됨
    ///
    /// WebSocket이 연결되지 않은 상태입니다.
    /// 초기 상태이거나 연결이 정상적으로 종료된 상태입니다.
    case disconnected
    
    /// 연결 중
    ///
    /// WebSocket 서버에 연결을 시도하고 있는 상태입니다.
    /// 연결 시도가 진행 중이며 성공 또는 실패 결과를 기다리고 있습니다.
    case connecting
    
    /// 연결됨
    ///
    /// WebSocket이 성공적으로 연결된 상태입니다.
    /// 메시지 송수신이 가능한 정상 작동 상태입니다.
    case connected
    
    
    /// 영구적 실패 (복구 불가)
    ///
    /// 연결에 영구적인 문제가 발생하여 더 이상 재시도하지 않는 상태입니다.
    /// 인증 실패나 프로토콜 오류 등 복구 불가능한 상황입니다.
    case failed
    
    /// 일시 중단됨 (사용자 요청)
    ///
    /// 사용자의 요청에 의해 연결이 일시적으로 중단된 상태입니다.
    /// 필요시 다시 연결을 시작할 수 있습니다.
    case suspended
}