import Foundation

// MARK: - Internal State Access Properties

extension YFWebSocketManager {
    
    /// 현재 연결 상태 조회
    internal var connectionState: ConnectionState {
        get async {
            return await internalState.getConnectionState()
        }
    }
    
    /// 현재 구독 목록 조회
    internal var subscriptions: Set<String> {
        get async {
            return await internalState.getSubscriptions()
        }
    }
    
    /// 연속 실패 횟수 조회
    internal var consecutiveFailures: Int {
        get async {
            return await internalState.getConsecutiveFailures()
        }
    }
    
    /// 테스트용 잘못된 연결 모드 조회
    internal var testInvalidConnectionMode: Bool {
        get async {
            return await internalState.getTestInvalidConnectionMode()
        }
    }
    
    /// 연결 타임아웃 조회
    internal var connectionTimeout: TimeInterval {
        get async {
            return await internalState.getConnectionTimeout()
        }
    }
    
    /// 연결 시도 수
    internal var connectionAttempts: Int {
        get async {
            return await internalState.getConnectionAttempts()
        }
    }
    
    /// 현재 연결 상태가 활성 상태인지 확인
    internal var isActiveState: Bool {
        get async {
            return await internalState.isActiveState()
        }
    }
    
    /// 현재 연결 상태가 사용 가능한 상태인지 확인
    internal var isUsableState: Bool {
        get async {
            return await internalState.isUsableState()
        }
    }
    
    /// 현재 연결 상태가 재시도 가능한 상태인지 확인
    internal var canRetryConnection: Bool {
        get async {
            return await internalState.canRetryConnection()
        }
    }
}