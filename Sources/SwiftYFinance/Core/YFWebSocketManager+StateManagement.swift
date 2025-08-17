import Foundation

/// YFWebSocketManager의 상태 관리 기능 확장
///
/// 이 확장은 WebSocket 연결 상태 관리, 에러 로깅, 연결 품질 모니터링 기능을 제공합니다.
/// 모든 상태 변경은 중앙화되어 관리되며, 유효성 검사와 로깅이 자동으로 처리됩니다.
extension YFWebSocketManager {
    
    // MARK: - State Management Implementation
    
    /// 연결 상태 변경 (중앙화된 상태 관리)
    ///
    /// 모든 상태 변경은 이 메서드를 통해 수행되며, 
    /// 상태 전환 로그와 유효성 검사가 자동으로 처리됩니다.
    ///
    /// - Parameters:
    ///   - newState: 변경할 새로운 상태
    ///   - reason: 상태 변경 이유
    internal func changeConnectionState(to newState: ConnectionState, reason: String) {
        let oldState = _connectionState
        
        // 상태 전환 유효성 검사
        guard isValidStateTransition(from: oldState, to: newState) else {
            print("⚠️ Invalid state transition: \(oldState) -> \(newState)")
            return
        }
        
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
        
        // 상태 변경 이벤트 처리
        handleStateChangeEffects(from: oldState, to: newState)
        
        print("🔄 State changed: \(oldState) -> \(newState) (\(reason))")
    }
    
    /// 상태 전환 유효성 검사
    ///
    /// 특정 상태 전환이 유효한지 확인합니다.
    ///
    /// - Parameters:
    ///   - fromState: 현재 상태
    ///   - toState: 전환할 상태
    /// - Returns: 유효한 전환인지 여부
    internal func isValidStateTransition(from fromState: ConnectionState, to toState: ConnectionState) -> Bool {
        // 동일한 상태로의 전환은 허용 (로그 목적)
        if fromState == toState {
            return true
        }
        
        switch fromState {
        case .disconnected:
            return [.connecting, .suspended].contains(toState)
            
        case .connecting:
            return [.connected, .disconnected, .failed].contains(toState)
            
        case .connected:
            return [.disconnected, .suspended].contains(toState)
            
        case .failed:
            return [.disconnected, .connecting].contains(toState)
            
        case .suspended:
            return [.disconnected, .connecting].contains(toState)
        }
    }
    
    /// 상태 변경 부수 효과 처리
    ///
    /// 상태가 변경될 때 필요한 부가 작업을 수행합니다.
    ///
    /// - Parameters:
    ///   - fromState: 이전 상태
    ///   - toState: 새로운 상태
    internal func handleStateChangeEffects(from fromState: ConnectionState, to toState: ConnectionState) {
        switch toState {
        case .disconnected:
            // 연결 해제 시 정리 작업
            if fromState != .disconnected {
                messageContinuation?.finish()
            }
            
        case .connecting:
            // 연결 시도 시작
            break
            
        case .connected:
            // 연결 성공 시 카운터 초기화
            if fromState != .connected {
                consecutiveFailures = 0
                connectionQuality.recordSuccess()
            }
            
        case .failed:
            // 영구적 실패 시 정리
            messageContinuation?.finish()
            connectionQuality.recordError()
            
        case .suspended:
            // 일시 중단 시 정리
            webSocketTask?.cancel(with: .goingAway, reason: nil)
        }
    }
    
    // MARK: - Error Logging and Diagnostics Implementation
    
    /// 에러 로그 추가
    ///
    /// 진단을 위해 에러 정보를 기록합니다.
    ///
    /// - Parameters:
    ///   - error: 발생한 에러
    ///   - context: 에러 발생 컨텍스트
    internal func logError(_ error: Error, context: String) {
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
        
        print("📝 Error logged: \(error) in \(context)")
    }
    
    /// 연결 성공 기록
    ///
    /// 연결 품질 메트릭을 업데이트합니다.
    internal func recordConnectionSuccess() {
        connectionQuality.recordSuccess()
        print("✅ Connection success recorded")
    }
    
    /// 메시지 수신 기록
    ///
    /// 연결 품질 메트릭을 업데이트합니다.
    internal func recordMessageReceived() {
        connectionQuality.recordMessageReceived()
    }
    
    // MARK: - Connection Quality Management
    
    /// 연결 품질 통계 조회
    ///
    /// 현재 연결 품질과 성능 메트릭을 반환합니다.
    ///
    /// - Returns: 연결 품질 통계 딕셔너리
    internal func getConnectionQualityStats() -> [String: Any] {
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
    
    /// 연결 품질 메트릭 초기화
    ///
    /// 모든 연결 품질 메트릭을 초기 상태로 재설정합니다.
    internal func resetConnectionQuality() {
        connectionQuality = YFWebSocketConnectionQuality()
        errorLog.removeAll()
        print("🔄 Connection quality metrics reset")
    }
    
    // MARK: - State Monitoring
    
    /// 상태 전환 통계 조회
    ///
    /// 상태 전환 패턴과 빈도를 분석할 수 있는 통계를 반환합니다.
    ///
    /// - Returns: 상태 전환 통계 딕셔너리
    internal func getStateTransitionStats() -> [String: Any] {
        let transitions = stateTransitionLog
        
        // 상태별 전환 횟수 계산
        var transitionCounts: [String: Int] = [:]
        for transition in transitions {
            let key = "\(transition.fromState) -> \(transition.toState)"
            transitionCounts[key] = (transitionCounts[key] ?? 0) + 1
        }
        
        // 최근 전환들
        let recentTransitions = Array(transitions.suffix(5)).map { transition in
            [
                "from": "\(transition.fromState)",
                "to": "\(transition.toState)",
                "timestamp": transition.timestamp.timeIntervalSince1970,
                "reason": transition.reason
            ]
        }
        
        return [
            "totalTransitions": transitions.count,
            "transitionCounts": transitionCounts,
            "recentTransitions": recentTransitions,
            "currentState": "\(connectionState)"
        ]
    }
    
    /// 종합 진단 정보 조회
    ///
    /// 전체 시스템 상태와 성능 메트릭을 포함한 종합 진단 정보를 반환합니다.
    ///
    /// - Returns: 종합 진단 정보 딕셔너리
    internal func getComprehensiveDiagnostics() -> [String: Any] {
        var diagnostics: [String: Any] = [:]
        
        // 기본 상태 정보
        diagnostics["connectionState"] = "\(connectionState)"
        diagnostics["subscriptions"] = Array(subscriptions)
        diagnostics["isUsableState"] = isUsableState
        diagnostics["isActiveState"] = isActiveState
        diagnostics["canRetryConnection"] = canRetryConnection
        
        // 연결 정보
        diagnostics["consecutiveFailures"] = consecutiveFailures
        
        // 연결 품질 정보
        diagnostics["connectionQuality"] = getConnectionQualityStats()
        
        // 상태 전환 정보
        diagnostics["stateTransitions"] = getStateTransitionStats()
        
        // 최근 에러 로그 (최대 10개)
        let recentErrors = Array(errorLog.suffix(10)).map { entry in
            [
                "timestamp": entry.timestamp.timeIntervalSince1970,
                "error": entry.description,
                "context": entry.context,
                "connectionState": "\(entry.connectionState)"
            ]
        }
        diagnostics["recentErrors"] = recentErrors
        
        // 구성 정보
        diagnostics["configuration"] = [
            "connectionTimeout": connectionTimeout,
            "messageTimeout": messageTimeout
        ]
        
        return diagnostics
    }
    
    // MARK: - Health Monitoring
    
    /// 연결 상태 건강도 평가
    ///
    /// 현재 연결 상태와 품질 메트릭을 기반으로 전체적인 건강도를 평가합니다.
    ///
    /// - Returns: 건강도 점수 (0.0 ~ 1.0)
    internal func evaluateConnectionHealth() -> Double {
        var score: Double = 0.0
        
        // 현재 연결 상태 점수 (40%)
        switch connectionState {
        case .connected:
            score += 0.4
        case .connecting:
            score += 0.2
        case .disconnected:
            score += 0.1
        case .failed, .suspended:
            score += 0.0
        }
        
        // 성공률 점수 (30%)
        let successRate = connectionQuality.successRate
        score += successRate * 0.3
        
        // 연속 실패 점수 (20%)
        let failureScore = consecutiveFailures == 0 ? 1.0 : max(0.0, 1.0 - Double(consecutiveFailures) / 10.0)
        score += failureScore * 0.2
        
        // 에러율 점수 (10%)
        let errorRate = connectionQuality.errorRate
        let errorScore = max(0.0, 1.0 - errorRate)
        score += errorScore * 0.1
        
        return min(1.0, max(0.0, score))
    }
    
    /// 연결 상태 권장 사항 생성
    ///
    /// 현재 상태와 메트릭을 기반으로 개선 권장 사항을 생성합니다.
    ///
    /// - Returns: 권장 사항 문자열 배열
    internal func generateConnectionRecommendations() -> [String] {
        var recommendations: [String] = []
        
        let health = evaluateConnectionHealth()
        
        if health < 0.3 {
            recommendations.append("Connection health is critical. Consider restarting the connection.")
        } else if health < 0.6 {
            recommendations.append("Connection health is poor. Monitor for frequent disconnections.")
        }
        
        if consecutiveFailures >= 3 {
            recommendations.append("Multiple consecutive failures detected. Check network connectivity.")
        }
        
        if connectionQuality.errorRate > 0.5 {
            recommendations.append("High error rate detected. Review error logs for patterns.")
        }
        
        if connectionQuality.successRate < 0.7 {
            recommendations.append("Low connection success rate. Consider adjusting timeout settings.")
        }
        
        if recommendations.isEmpty {
            recommendations.append("Connection is healthy and performing well.")
        }
        
        return recommendations
    }
    
    // MARK: - Cleanup and Reset
    
    /// 모든 상태 관리 데이터 초기화
    ///
    /// 상태 전환 로그, 에러 로그, 연결 품질 메트릭을 모두 초기화합니다.
    internal func resetAllStateData() {
        stateTransitionLog.removeAll()
        errorLog.removeAll()
        connectionQuality = YFWebSocketConnectionQuality()
        consecutiveFailures = 0
        
        print("🔄 All state management data reset")
    }
    
    /// 이전 세션 데이터 정리
    ///
    /// 새로운 연결 세션을 시작하기 전에 이전 세션의 임시 데이터를 정리합니다.
    internal func cleanupPreviousSession() {
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
        
        print("🧹 Previous session data cleaned up")
    }
}