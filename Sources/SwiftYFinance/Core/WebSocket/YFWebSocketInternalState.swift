import Foundation

/// WebSocket 내부 상태를 관리하는 Actor
///
/// YFWebSocketManager의 mutable 상태들을 동시성 안전하게 관리합니다.
/// 모든 상태 변경은 이 actor를 통해 원자적으로 수행됩니다.
internal actor YFWebSocketInternalState {
    
    // MARK: - Connection State Properties
    
    /// 현재 연결 상태
    private var _connectionState: YFWebSocketConnectionState = .disconnected
    
    /// 상태 전환 로그
    private var stateTransitionLog: [YFWebSocketStateTransition] = []
    private let maxStateTransitionEntries = 20
    
    /// 연속 실패 횟수
    private var consecutiveFailures: Int = 0
    
    // MARK: - Subscription Properties
    
    /// 현재 구독 중인 심볼들
    private var subscriptions: Set<String> = []
    
    // MARK: - Quality Monitoring Properties
    
    /// 연결 품질 메트릭
    private var connectionQuality = YFWebSocketConnectionQuality()
    
    /// 에러 로그
    private var errorLog: [YFWebSocketErrorLogEntry] = []
    private let maxErrorLogEntries = 50
    
    // MARK: - Configuration Properties
    
    /// 테스트용 잘못된 연결 모드
    private var testInvalidConnectionMode: Bool = false
    
    /// 연결 타임아웃 (초)
    private var connectionTimeout: TimeInterval = 10.0
    
    /// 메시지 수신 타임아웃 (초)
    private var messageTimeout: TimeInterval = 30.0
    
    // MARK: - Initialization
    
    /// WebSocket 내부 상태 초기화
    init() {
        // 기본 초기화
    }
    
    // MARK: - Connection State Management
    
    /// 현재 연결 상태 조회
    func getConnectionState() -> YFWebSocketConnectionState {
        return _connectionState
    }
    
    /// 연결 상태 변경
    func updateConnectionState(to newState: YFWebSocketConnectionState, reason: String) {
        let oldState = _connectionState
        
        // 상태 변경
        _connectionState = newState
        
        // 상태 전환 로그 기록
        let transition = YFWebSocketStateTransition(
            fromState: oldState,
            toState: newState,
            timestamp: Date(),
            reason: reason
        )
        
        stateTransitionLog.append(transition)
        
        // 로그 크기 제한
        if stateTransitionLog.count > maxStateTransitionEntries {
            stateTransitionLog.removeFirst()
        }
        
        // 상태 변경 부수 효과 처리
        handleStateChangeEffects(from: oldState, to: newState)
    }
    
    /// 상태 변경 부수 효과 처리
    private func handleStateChangeEffects(from fromState: YFWebSocketConnectionState, to toState: YFWebSocketConnectionState) {
        switch toState {
        case .connected:
            // 연결 성공 시 카운터 초기화
            if fromState != .connected {
                consecutiveFailures = 0
                connectionQuality.recordSuccess()
            }
            
        case .failed:
            // 영구적 실패 시 품질 기록
            connectionQuality.recordError()
            
        default:
            break
        }
    }
    
    // MARK: - Subscription Management
    
    /// 현재 구독 목록 조회
    func getSubscriptions() -> Set<String> {
        return subscriptions
    }
    
    /// 심볼 구독 추가
    func addSubscriptions(_ symbols: Set<String>) {
        subscriptions.formUnion(symbols)
    }
    
    /// 심볼 구독 제거
    func removeSubscriptions(_ symbols: Set<String>) {
        subscriptions.subtract(symbols)
    }
    
    /// 모든 구독 제거
    func clearSubscriptions() {
        subscriptions.removeAll()
    }
    
    // MARK: - Quality Monitoring
    
    /// 연결 품질 메트릭 조회
    func getConnectionQuality() -> YFWebSocketConnectionQuality {
        return connectionQuality
    }
    
    /// 연결 성공 기록
    func recordConnectionSuccess() {
        connectionQuality.recordSuccess()
    }
    
    /// 에러 발생 기록
    func recordError() {
        connectionQuality.recordError()
    }
    
    /// 메시지 수신 기록
    func recordMessageReceived() {
        connectionQuality.recordMessageReceived()
    }
    
    // MARK: - Error Logging
    
    /// 에러 로그 추가
    func addErrorLog(_ error: Error, context: String, connectionState: YFWebSocketConnectionState, consecutiveFailures: Int) {
        let entry = YFWebSocketErrorLogEntry(
            timestamp: Date(),
            error: error,
            context: context,
            connectionState: connectionState,
            consecutiveFailures: consecutiveFailures
        )
        
        errorLog.append(entry)
        
        // 로그 크기 제한
        if errorLog.count > maxErrorLogEntries {
            errorLog.removeFirst()
        }
        
        // 연결 품질 업데이트
        connectionQuality.recordError()
    }
    
    /// 에러 로그 조회
    func getErrorLog() -> [YFWebSocketErrorLogEntry] {
        return errorLog
    }
    
    // MARK: - State Transition Logging
    
    /// 상태 전환 로그 조회
    func getStateTransitionLog() -> [YFWebSocketStateTransition] {
        return stateTransitionLog
    }
    
    // MARK: - Failure Tracking
    
    /// 연속 실패 횟수 조회
    func getConsecutiveFailures() -> Int {
        return consecutiveFailures
    }
    
    /// 연속 실패 횟수 증가
    func incrementConsecutiveFailures() {
        consecutiveFailures += 1
    }
    
    /// 연속 실패 횟수 초기화
    func resetConsecutiveFailures() {
        consecutiveFailures = 0
    }
    
    // MARK: - Configuration
    
    /// 테스트용 잘못된 연결 모드 설정
    func setTestInvalidConnectionMode(_ enabled: Bool) {
        testInvalidConnectionMode = enabled
    }
    
    /// 테스트용 잘못된 연결 모드 조회
    func getTestInvalidConnectionMode() -> Bool {
        return testInvalidConnectionMode
    }
    
    /// 타임아웃 설정
    func setTimeouts(connectionTimeout: TimeInterval, messageTimeout: TimeInterval) {
        self.connectionTimeout = connectionTimeout
        self.messageTimeout = messageTimeout
    }
    
    /// 연결 타임아웃 조회
    func getConnectionTimeout() -> TimeInterval {
        return connectionTimeout
    }
    
    /// 메시지 타임아웃 조회
    func getMessageTimeout() -> TimeInterval {
        return messageTimeout
    }
    
    // MARK: - State Validation
    
    /// 현재 연결 상태가 활성 상태인지 확인
    func isActiveState() -> Bool {
        return [.connecting, .connected].contains(_connectionState)
    }
    
    /// 현재 연결 상태가 사용 가능한 상태인지 확인
    func isUsableState() -> Bool {
        return _connectionState == .connected
    }
    
    /// 현재 연결 상태가 재시도 가능한 상태인지 확인
    func canRetryConnection() -> Bool {
        return [.disconnected, .failed].contains(_connectionState)
    }
    
    /// 연결 시도 수 계산
    func getConnectionAttempts() -> Int {
        return consecutiveFailures + 1
    }
    
    // MARK: - Reset Operations
    
    /// 모든 상태 데이터 초기화
    func resetAllStateData() {
        stateTransitionLog.removeAll()
        errorLog.removeAll()
        connectionQuality = YFWebSocketConnectionQuality()
        consecutiveFailures = 0
    }
    
    /// 이전 세션 데이터 정리
    func cleanupPreviousSession() {
        // 연결 관련 임시 상태만 정리 (품질 메트릭은 유지)
        consecutiveFailures = 0
        
        // 오래된 상태 전환 로그 정리 (최근 10개만 유지)
        if stateTransitionLog.count > 10 {
            stateTransitionLog = Array(stateTransitionLog.suffix(10))
        }
        
        // 오래된 에러 로그 정리 (최근 20개만 유지)
        if errorLog.count > 20 {
            errorLog = Array(errorLog.suffix(20))
        }
    }
}