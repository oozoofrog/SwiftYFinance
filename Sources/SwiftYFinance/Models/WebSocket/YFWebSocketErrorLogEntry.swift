import Foundation

/// 에러 로그 엔트리
///
/// WebSocket 연결 중 발생한 에러 정보를 기록하는 구조체입니다.
/// 디버깅과 진단을 위해 에러 컨텍스트와 시점의 상태 정보를 함께 저장합니다.
internal struct YFWebSocketErrorLogEntry {
    /// 에러 발생 시간
    let timestamp: Date
    
    /// 발생한 에러
    let error: Error
    
    /// 에러 발생 컨텍스트 (어떤 작업 중 발생했는지)
    let context: String
    
    /// 에러 발생 시점의 연결 상태
    let connectionState: YFWebSocketConnectionState
    
    
    /// 에러 발생 시점의 연속 실패 횟수
    let consecutiveFailures: Int
    
    /// 로그 문자열 표현
    ///
    /// 에러 정보를 사람이 읽기 쉬운 형태로 포매팅합니다.
    ///
    /// - Returns: 포매팅된 에러 로그 문자열
    var description: String {
        return "\(timestamp): [\(context)] \(error) (state: \(connectionState), failures: \(consecutiveFailures))"
    }
}