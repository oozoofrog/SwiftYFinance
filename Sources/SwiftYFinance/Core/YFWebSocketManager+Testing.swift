import Foundation

#if DEBUG
/// YFWebSocketManager의 테스트 지원 기능 확장
///
/// 이 확장은 DEBUG 빌드에서만 사용할 수 있는 테스트 메서드들을 제공합니다.
/// 단위 테스트와 통합 테스트에서 WebSocket 매니저의 내부 상태와 동작을 검증할 수 있습니다.
extension YFWebSocketManager {
    
    // MARK: - Connection State Testing
    
    /// 현재 연결 상태 조회 (테스트용)
    ///
    /// DEBUG 빌드에서만 사용할 수 있는 연결 상태 조회 메서드입니다.
    ///
    /// - Returns: 현재 WebSocket 연결 상태
    public func testGetConnectionState() -> ConnectionState {
        return connectionState
    }
    
    /// 커스텀 URL로 WebSocket 연결 (테스트용)
    ///
    /// DEBUG 빌드에서만 사용할 수 있는 커스텀 URL 연결 메서드입니다.
    /// 테스트 목적으로만 사용하세요.
    ///
    /// - Parameter urlString: 연결할 WebSocket URL 문자열
    /// - Throws: `YFError.webSocketError` WebSocket 연결 관련 오류
    public func testConnectWithCustomURL(_ urlString: String) async throws {
        guard let url = URL(string: urlString) else {
            throw YFError.webSocketError(.invalidURL("Invalid custom WebSocket URL: \(urlString)"))
        }
        
        // Validate WebSocket scheme
        guard url.scheme == "ws" || url.scheme == "wss" else {
            throw YFError.webSocketError(.invalidURL("WebSocket URL must use ws:// or wss:// scheme: \(urlString)"))
        }
        
        try await connectToURL(url)
    }
    
    /// 현재 구독 목록 조회 (테스트용)
    ///
    /// DEBUG 빌드에서만 사용할 수 있는 구독 목록 조회 메서드입니다.
    ///
    /// - Returns: 현재 구독 중인 심볼들의 Set
    public func testGetSubscriptions() -> Set<String> {
        return subscriptions
    }
    
    // MARK: - Connection Loss Testing
    
    /// 연결 손실 시뮬레이션 (테스트용)
    ///
    /// DEBUG 빌드에서만 사용할 수 있는 연결 손실 시뮬레이션 메서드입니다.
    public func testSimulateConnectionLoss() async {
        if isUsableState {
            webSocketTask?.cancel()
            changeConnectionState(to: .disconnected, reason: "Test: Simulated connection loss")
        }
    }
    
    // MARK: - Configuration Testing
    
    /// 잘못된 연결 모드 설정 (테스트용)
    ///
    /// DEBUG 빌드에서만 사용할 수 있는 잘못된 연결 모드 설정 메서드입니다.
    ///
    /// - Parameter enabled: 잘못된 연결 모드 활성화 여부
    public func testSetInvalidConnectionMode(_ enabled: Bool) {
        testInvalidConnectionMode = enabled
    }
    
    /// 타임아웃 설정 (테스트용)
    ///
    /// DEBUG 빌드에서만 사용할 수 있는 타임아웃 설정 메서드입니다.
    ///
    /// - Parameters:
    ///   - connectionTimeout: 연결 타임아웃 (초)
    ///   - messageTimeout: 메시지 수신 타임아웃 (초)
    public func testSetTimeouts(connectionTimeout: TimeInterval, messageTimeout: TimeInterval) {
        self.connectionTimeout = connectionTimeout
        self.messageTimeout = messageTimeout
    }
    
    // MARK: - Failure Statistics Testing
    
    /// 연속 실패 횟수 조회 (테스트용)
    ///
    /// DEBUG 빌드에서만 사용할 수 있는 연속 실패 횟수 조회 메서드입니다.
    ///
    /// - Returns: 현재 연속 실패 횟수
    public func testGetConsecutiveFailures() -> Int {
        return consecutiveFailures
    }
    
    /// 연결 시도 횟수 조회 (테스트용)
    ///
    /// DEBUG 빌드에서만 사용할 수 있는 연결 시도 횟수 조회 메서드입니다.
    ///
    /// - Returns: 현재까지의 총 연결 시도 횟수
    public func testGetConnectionAttempts() -> Int {
        return connectionAttempts
    }
    
    // MARK: - Quality and Diagnostics Testing
    
    /// 연결 품질 메트릭 조회 (테스트용)
    ///
    /// DEBUG 빌드에서만 사용할 수 있는 연결 품질 정보 조회 메서드입니다.
    ///
    /// - Returns: 연결 품질 정보 딕셔너리
    public func testGetConnectionQuality() -> [String: Any] {
        return [
            "totalConnections": connectionQuality.totalConnections,
            "successfulConnections": connectionQuality.successfulConnections,
            "totalErrors": connectionQuality.totalErrors,
            "messagesReceived": connectionQuality.messagesReceived,
            "successRate": connectionQuality.successRate,
            "errorRate": connectionQuality.errorRate,
            "lastSuccessTime": connectionQuality.lastSuccessTime?.timeIntervalSince1970 ?? 0,
            "lastErrorTime": connectionQuality.lastErrorTime?.timeIntervalSince1970 ?? 0
        ]
    }
    
    /// 에러 로그 조회 (테스트용)
    ///
    /// DEBUG 빌드에서만 사용할 수 있는 에러 로그 조회 메서드입니다.
    ///
    /// - Returns: 에러 로그 문자열 배열
    public func testGetErrorLog() -> [String] {
        return errorLog.map { $0.description }
    }
    
    /// 진단 정보 조회 (테스트용)
    ///
    /// DEBUG 빌드에서만 사용할 수 있는 종합 진단 정보 조회 메서드입니다.
    ///
    /// - Returns: 진단 정보 딕셔너리
    public func testGetDiagnostics() -> [String: Any] {
        var diagnostics: [String: Any] = [:]
        
        // 기본 상태 정보
        diagnostics["connectionState"] = "\(connectionState)"
        diagnostics["subscriptions"] = Array(subscriptions)
        diagnostics["consecutiveFailures"] = consecutiveFailures
        
        // 연결 품질 정보
        diagnostics["connectionQuality"] = testGetConnectionQuality()
        
        // 최근 에러 로그 (최대 5개)
        let recentErrors = Array(errorLog.suffix(5)).map { $0.description }
        diagnostics["recentErrors"] = recentErrors
        
        return diagnostics
    }
    
    /// 상태 전환 로그 조회 (테스트용)
    ///
    /// DEBUG 빌드에서만 사용할 수 있는 상태 전환 로그 조회 메서드입니다.
    ///
    /// - Returns: 상태 전환 로그 문자열 배열
    public func testGetStateTransitionLog() -> [String] {
        return stateTransitionLog.map { $0.description }
    }
    
    /// 현재 상태의 활성/사용가능 여부 조회 (테스트용)
    ///
    /// DEBUG 빌드에서만 사용할 수 있는 상태 정보 조회 메서드입니다.
    ///
    /// - Returns: 상태 정보 딕셔너리
    public func testGetStateInfo() -> [String: Any] {
        return [
            "connectionState": "\(connectionState)",
            "isActiveState": isActiveState,
            "isUsableState": isUsableState,
            "canRetryConnection": canRetryConnection
        ]
    }
    
    /// 상태 전환 강제 실행 (테스트용)
    ///
    /// DEBUG 빌드에서만 사용할 수 있는 상태 전환 테스트 메서드입니다.
    /// 주의: 이 메서드는 테스트 목적으로만 사용하세요.
    ///
    /// - Parameters:
    ///   - newState: 전환할 상태
    ///   - reason: 전환 이유
    /// - Returns: 전환 성공 여부
    public func testForceStateTransition(to newState: ConnectionState, reason: String) -> Bool {
        let oldState = _connectionState
        if isValidStateTransition(from: oldState, to: newState) {
            changeConnectionState(to: newState, reason: "Test: \(reason)")
            return true
        } else {
            return false
        }
    }
    
    // MARK: - Message Testing
    
    /// 테스트 메시지 전송 (테스트용)
    ///
    /// DEBUG 빌드에서만 사용할 수 있는 테스트 메시지 전송 메서드입니다.
    ///
    /// - Parameter message: 전송할 테스트 메시지
    /// - Throws: `YFError.webSocketError` 메시지 전송 실패 시
    public func testSendMessage(_ message: String) async throws {
        try await sendMessage(message)
    }
    
    /// 구독 메시지 생성 테스트 (테스트용)
    ///
    /// DEBUG 빌드에서만 사용할 수 있는 구독 메시지 생성 테스트 메서드입니다.
    ///
    /// - Parameter symbols: 구독할 심볼 배열
    /// - Returns: 생성된 JSON 메시지
    public func testCreateSubscriptionMessage(symbols: [String]) -> String {
        return Self.createSubscriptionMessage(symbols: symbols)
    }
    
    /// 구독 취소 메시지 생성 테스트 (테스트용)
    ///
    /// DEBUG 빌드에서만 사용할 수 있는 구독 취소 메시지 생성 테스트 메서드입니다.
    ///
    /// - Parameter symbols: 구독 취소할 심볼 배열
    /// - Returns: 생성된 JSON 메시지
    public func testCreateUnsubscriptionMessage(symbols: [String]) -> String {
        return Self.createUnsubscriptionMessage(symbols: symbols)
    }
    
    // MARK: - Internal State Manipulation
    
    /// 연결 품질 메트릭 강제 업데이트 (테스트용)
    ///
    /// DEBUG 빌드에서만 사용할 수 있는 연결 품질 업데이트 메서드입니다.
    ///
    /// - Parameters:
    ///   - success: 성공 여부
    ///   - error: 에러 여부
    ///   - message: 메시지 수신 여부
    public func testUpdateConnectionQuality(success: Bool = false, error: Bool = false, message: Bool = false) {
        if success {
            connectionQuality.recordSuccess()
        }
        if error {
            connectionQuality.recordError()
        }
        if message {
            connectionQuality.recordMessageReceived()
        }
    }
    
    /// 테스트용 에러 로그 추가 (테스트용)
    ///
    /// DEBUG 빌드에서만 사용할 수 있는 에러 로그 추가 메서드입니다.
    ///
    /// - Parameters:
    ///   - error: 추가할 에러
    ///   - context: 에러 컨텍스트
    public func testAddErrorLog(_ error: Error, context: String) {
        logError(error, context: context)
    }
    
    // MARK: - Validation Testing
    
    /// 상태 전환 유효성 검사 (테스트용)
    ///
    /// DEBUG 빌드에서만 사용할 수 있는 상태 전환 유효성 검사 메서드입니다.
    ///
    /// - Parameters:
    ///   - fromState: 현재 상태
    ///   - toState: 전환할 상태
    /// - Returns: 유효한 전환인지 여부
    public func testIsValidStateTransition(from fromState: ConnectionState, to toState: ConnectionState) -> Bool {
        return isValidStateTransition(from: fromState, to: toState)
    }
    
    /// WebSocket task 존재 확인 (테스트용)
    ///
    /// DEBUG 빌드에서만 사용할 수 있는 WebSocket task 확인 메서드입니다.
    ///
    /// - Returns: WebSocket task가 존재하는지 여부
    public func testHasWebSocketTask() -> Bool {
        return webSocketTask != nil
    }
    
    /// 메시지 컨티뉴에이션 존재 확인 (테스트용)
    ///
    /// DEBUG 빌드에서만 사용할 수 있는 메시지 컨티뉴에이션 확인 메서드입니다.
    ///
    /// - Returns: 메시지 컨티뉴에이션이 존재하는지 여부
    public func testHasMessageContinuation() -> Bool {
        return messageContinuation != nil
    }
    
    /// 연결 실패 시뮬레이션 (테스트용)
    ///
    /// DEBUG 빌드에서만 사용할 수 있는 연결 실패 시뮬레이션 메서드입니다.
    public func testSimulateConnectionFailure() {
        consecutiveFailures += 1
        changeConnectionState(to: .failed, reason: "Test: Simulated connection failure")
    }
    
    /// 연결 상태 초기화 (테스트용)
    ///
    /// DEBUG 빌드에서만 사용할 수 있는 상태 초기화 메서드입니다.
    public func testResetConnectionState() {
        consecutiveFailures = 0
        _connectionState = .disconnected
        subscriptions.removeAll()
        messageContinuation?.finish()
        messageContinuation = nil
        webSocketTask?.cancel()
        webSocketTask = nil
    }
}
#endif