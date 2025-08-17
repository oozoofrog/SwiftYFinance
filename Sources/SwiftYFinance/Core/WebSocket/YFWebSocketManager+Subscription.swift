import Foundation

// MARK: - Subscription Management

extension YFWebSocketManager {
    
    /// 심볼 구독
    ///
    /// 지정된 심볼들의 실시간 데이터를 구독합니다.
    /// Yahoo Finance WebSocket 프로토콜에 따라 JSON 형식으로 구독 메시지를 전송합니다.
    ///
    /// - Parameter symbols: 구독할 심볼 배열 (예: ["AAPL", "TSLA"])
    /// - Throws: `YFError.webSocketError` 연결 또는 구독 관련 오류
    ///
    /// ## 사용 예시
    /// ```swift
    /// let manager = YFWebSocketManager()
    /// try await manager.connect()
    /// try await manager.subscribe(to: ["AAPL", "TSLA"])
    /// ```
    public func subscribe(to symbols: [String]) async throws {
        try await subscriptionRegistry.subscribe(
            to: symbols,
            isUsableState: { await self.isUsableState },
            sendMessage: { message in try await self.sendMessage(message) }
        )
    }
    
    /// 심볼 구독 취소
    ///
    /// 지정된 심볼들의 실시간 데이터 구독을 취소합니다.
    ///
    /// - Parameter symbols: 구독 취소할 심볼 배열
    /// - Throws: `YFError.webSocketError` 연결 또는 구독 관련 오류
    public func unsubscribe(from symbols: [String]) async throws {
        try await subscriptionRegistry.unsubscribe(
            from: symbols,
            isUsableState: { await self.isUsableState },
            sendMessage: { message in try await self.sendMessage(message) }
        )
    }
    
    // MARK: - State Access
    
    /// 현재 구독 목록 조회
    ///
    /// - Returns: 현재 구독 중인 심볼들의 Set
    public var subscriptions: Set<String> {
        get async {
            return await subscriptionRegistry.getSubscriptions()
        }
    }
    
    /// 구독 목록 초기화
    public func clearSubscriptions() async {
        await subscriptionRegistry.clearSubscriptions()
    }
}