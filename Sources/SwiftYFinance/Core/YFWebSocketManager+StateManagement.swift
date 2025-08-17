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
    internal func changeConnectionState(to newState: ConnectionState, reason: String) async {
        let oldState = await connectionState
        
        // 상태 전환 유효성 검사
        guard isValidStateTransition(from: oldState, to: newState) else {
            print("⚠️ Invalid state transition: \(oldState) -> \(newState)")
            return
        }
        
        // Actor를 통한 상태 변경
        await internalState.updateConnectionState(to: newState, reason: reason)
        
        // 상태 변경 이벤트 처리
        await handleStateChangeEffects(from: oldState, to: newState)
        
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
    internal func handleStateChangeEffects(from fromState: ConnectionState, to toState: ConnectionState) async {
        switch toState {
        case .disconnected:
            // 연결 해제 시 정리 작업
            if fromState != .disconnected {
                Task {
                    await messageProcessor.clearMessageContinuation()
                }
            }
            
        case .connecting:
            // 연결 시도 시작
            break
            
        case .connected:
            // 연결 성공 시 카운터 초기화
            if fromState != .connected {
                await internalState.resetConsecutiveFailures()
                await internalState.recordConnectionSuccess()
            }
            
        case .failed:
            // 영구적 실패 시 정리
            Task {
                await messageProcessor.clearMessageContinuation()
            }
            await internalState.recordError()
            
        case .suspended:
            // 일시 중단 시 정리
            let task = await webSocketTask
            task?.cancel(with: .goingAway, reason: nil)
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
    internal func logError(_ error: Error, context: String) async {
        let currentState = await connectionState
        let failures = await consecutiveFailures
        
        await internalState.addErrorLog(error, context: context, connectionState: currentState, consecutiveFailures: failures)
        
        print("📝 Error logged: \(error) in \(context)")
    }
    
    /// 연결 성공 기록
    ///
    /// 연결 품질 메트릭을 업데이트합니다.
    internal func recordConnectionSuccess() async {
        await internalState.recordConnectionSuccess()
        print("✅ Connection success recorded")
    }
    
    /// 메시지 수신 기록
    ///
    /// 연결 품질 메트릭을 업데이트합니다.
    internal func recordMessageReceived() async {
        await internalState.recordMessageReceived()
    }
    
    // MARK: - Connection Quality Management
    
    /// 연결 품질 통계 조회
    ///
    /// 현재 연결 품질과 성능 메트릭을 반환합니다.
    ///
    /// - Returns: 연결 품질 통계 딕셔너리
    internal func getConnectionQualityStats() async -> [String: Any] {
        let quality = await internalState.getConnectionQuality()
        return [
            "totalConnections": quality.totalConnections,
            "successfulConnections": quality.successfulConnections,
            "totalErrors": quality.totalErrors,
            "messagesReceived": quality.messagesReceived,
            "successRate": quality.successRate,
            "errorRate": quality.errorRate,
            "lastSuccessTime": quality.lastSuccessTime?.timeIntervalSince1970 ?? 0,
            "lastErrorTime": quality.lastErrorTime?.timeIntervalSince1970 ?? 0
        ]
    }
    
    /// 연결 품질 메트릭 초기화
    ///
    /// 모든 연결 품질 메트릭을 초기 상태로 재설정합니다.
    internal func resetConnectionQuality() async {
        await internalState.resetAllStateData()
        print("🔄 Connection quality metrics reset")
    }
    
    // MARK: - State Monitoring
    
    /// 상태 전환 통계 조회
    ///
    /// 상태 전환 패턴과 빈도를 분석할 수 있는 통계를 반환합니다.
    ///
    /// - Returns: 상태 전환 통계 딕셔너리
    internal func getStateTransitionStats() async -> [String: Any] {
        let transitions = await internalState.getStateTransitionLog()
        
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
            "currentState": "\(await connectionState)"
        ]
    }
    
    /// 종합 진단 정보 조회
    ///
    /// 전체 시스템 상태와 성능 메트릭을 포함한 종합 진단 정보를 반환합니다.
    ///
    /// - Returns: 종합 진단 정보 딕셔너리
    internal func getComprehensiveDiagnostics() async -> [String: Any] {
        var diagnostics: [String: Any] = [:]
        
        // 기본 상태 정보
        diagnostics["connectionState"] = "\(await connectionState)"
        diagnostics["subscriptions"] = Array(await subscriptions)
        diagnostics["isUsableState"] = await isUsableState
        diagnostics["isActiveState"] = await isActiveState
        diagnostics["canRetryConnection"] = await canRetryConnection
        
        // 연결 정보
        diagnostics["consecutiveFailures"] = await consecutiveFailures
        
        // 연결 품질 정보
        diagnostics["connectionQuality"] = await getConnectionQualityStats()
        
        // 상태 전환 정보
        diagnostics["stateTransitions"] = await getStateTransitionStats()
        
        // 최근 에러 로그 (최대 10개)
        let errorLog = await internalState.getErrorLog()
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
            "connectionTimeout": await connectionTimeout,
            "messageTimeout": await internalState.getMessageTimeout()
        ]
        
        return diagnostics
    }
    
    // MARK: - Health Monitoring
    
    /// 연결 상태 건강도 평가
    ///
    /// 현재 연결 상태와 품질 메트릭을 기반으로 전체적인 건강도를 평가합니다.
    ///
    /// - Returns: 건강도 점수 (0.0 ~ 1.0)
    internal func evaluateConnectionHealth() async -> Double {
        var score: Double = 0.0
        
        // 현재 연결 상태 점수 (40%)
        let currentState = await connectionState
        switch currentState {
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
        let quality = await internalState.getConnectionQuality()
        let successRate = quality.successRate
        score += successRate * 0.3
        
        // 연속 실패 점수 (20%)
        let failures = await consecutiveFailures
        let failureScore = failures == 0 ? 1.0 : max(0.0, 1.0 - Double(failures) / 10.0)
        score += failureScore * 0.2
        
        // 에러율 점수 (10%)
        let errorRate = quality.errorRate
        let errorScore = max(0.0, 1.0 - errorRate)
        score += errorScore * 0.1
        
        return min(1.0, max(0.0, score))
    }
    
    /// 연결 상태 권장 사항 생성
    ///
    /// 현재 상태와 메트릭을 기반으로 개선 권장 사항을 생성합니다.
    ///
    /// - Returns: 권장 사항 문자열 배열
    internal func generateConnectionRecommendations() async -> [String] {
        var recommendations: [String] = []
        
        let health = await evaluateConnectionHealth()
        let quality = await internalState.getConnectionQuality()
        let failures = await consecutiveFailures
        
        if health < 0.3 {
            recommendations.append("Connection health is critical. Consider restarting the connection.")
        } else if health < 0.6 {
            recommendations.append("Connection health is poor. Monitor for frequent disconnections.")
        }
        
        if failures >= 3 {
            recommendations.append("Multiple consecutive failures detected. Check network connectivity.")
        }
        
        if quality.errorRate > 0.5 {
            recommendations.append("High error rate detected. Review error logs for patterns.")
        }
        
        if quality.successRate < 0.7 {
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
    internal func resetAllStateData() async {
        await internalState.resetAllStateData()
        
        print("🔄 All state management data reset")
    }
    
    /// 이전 세션 데이터 정리
    ///
    /// 새로운 연결 세션을 시작하기 전에 이전 세션의 임시 데이터를 정리합니다.
    internal func cleanupPreviousSession() async {
        await internalState.cleanupPreviousSession()
        
        print("🧹 Previous session data cleaned up")
    }
}