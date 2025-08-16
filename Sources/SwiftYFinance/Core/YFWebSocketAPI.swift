import Foundation

// MARK: - WebSocket API Extension
extension YFClient {
    
    /// 실시간 스트리밍을 시작합니다
    ///
    /// Yahoo Finance WebSocket을 통해 실시간 주식 가격 데이터를 스트리밍합니다.
    /// Python yfinance의 `Ticker.live` 메서드와 유사한 기능을 제공합니다.
    ///
    /// ## 사용 예시
    /// ```swift
    /// let client = YFClient()
    /// let stream = try await client.startRealTimeStreaming(symbols: ["AAPL", "TSLA"])
    /// 
    /// for await quote in stream {
    ///     print("\(quote.symbol): $\(quote.price)")
    /// }
    /// ```
    ///
    /// - Parameter symbols: 스트리밍할 심볼 배열 (예: ["AAPL", "TSLA", "BTC-USD"])
    /// - Returns: 실시간 스트리밍 쿼트의 AsyncStream
    /// - Throws: `YFError` WebSocket 연결 또는 구독 실패 시
    public func startRealTimeStreaming(symbols: [String]) async throws -> AsyncStream<YFStreamingQuote> {
        // WebSocket 매니저 생성 (기존 세션 활용)
        let webSocketManager = YFWebSocketManager(urlSession: self.session.urlSession)
        
        // WebSocket 연결
        try await webSocketManager.connect()
        
        // 심볼 구독
        try await webSocketManager.subscribe(to: symbols)
        
        // 메시지 스트림을 YFStreamingQuote로 변환
        let messageStream = await webSocketManager.messageStream()
        
        return AsyncStream<YFStreamingQuote> { continuation in
            let streamingTask = Task {
                for await webSocketMessage in messageStream {
                    // WebSocket 메시지를 스트리밍 쿼트로 변환
                    let streamingQuote = YFStreamingQuote(
                        symbol: webSocketMessage.symbol,
                        price: webSocketMessage.price,
                        timestamp: webSocketMessage.timestamp,
                        change: nil, // WebSocket 메시지에서 계산 필요
                        changePercent: nil, // WebSocket 메시지에서 계산 필요
                        volume: nil // 추후 확장 가능
                    )
                    
                    continuation.yield(streamingQuote)
                }
            }
            
            continuation.onTermination = { _ in
                streamingTask.cancel()
                Task {
                    await webSocketManager.disconnect()
                }
            }
        }
    }
    
    /// 실시간 스트리밍을 시작합니다 (단일 심볼)
    ///
    /// 단일 심볼에 대한 실시간 스트리밍을 시작하는 편의 메서드입니다.
    ///
    /// - Parameter symbol: 스트리밍할 심볼 (예: "AAPL")
    /// - Returns: 실시간 스트리밍 쿼트의 AsyncStream
    /// - Throws: `YFError` WebSocket 연결 또는 구독 실패 시
    public func startRealTimeStreaming(symbol: String) async throws -> AsyncStream<YFStreamingQuote> {
        return try await startRealTimeStreaming(symbols: [symbol])
    }
    
    /// 실시간 스트리밍을 위한 WebSocket 매니저를 생성합니다
    ///
    /// 고급 사용자를 위한 저수준 API입니다. 직접 WebSocket 매니저를 제어하고 싶을 때 사용합니다.
    ///
    /// ## 사용 예시
    /// ```swift
    /// let client = YFClient()
    /// let manager = client.createWebSocketManager()
    /// 
    /// try await manager.connect()
    /// try await manager.subscribe(to: ["AAPL"])
    /// 
    /// let stream = await manager.messageStream()
    /// for await message in stream {
    ///     print("Raw message: \(message)")
    /// }
    /// ```
    ///
    /// - Returns: 구성된 YFWebSocketManager 인스턴스
    public func createWebSocketManager() -> YFWebSocketManager {
        return YFWebSocketManager(urlSession: self.session.urlSession)
    }
    
    /// 실시간 스트리밍 상태를 확인합니다
    ///
    /// 현재 활성화된 WebSocket 연결이 있는지 확인하는 유틸리티 메서드입니다.
    ///
    /// - Returns: WebSocket 기능 사용 가능 여부
    public func isRealTimeStreamingAvailable() -> Bool {
        // 세션이 유효하고 WebSocket 매니저를 생성할 수 있는지 확인
        return session.urlSession.configuration.httpCookieStorage != nil
    }
}

// MARK: - WebSocket Convenience Methods
extension YFClient {
    
    /// 암호화폐 실시간 스트리밍을 시작합니다
    ///
    /// 주요 암호화폐들의 실시간 가격을 스트리밍하는 편의 메서드입니다.
    ///
    /// - Parameter cryptoSymbols: 암호화폐 심볼 배열 (기본값: 주요 암호화폐)
    /// - Returns: 실시간 스트리밍 쿼트의 AsyncStream
    /// - Throws: `YFError` WebSocket 연결 또는 구독 실패 시
    public func startCryptoStreaming(
        cryptoSymbols: [String] = ["BTC-USD", "ETH-USD", "ADA-USD", "XRP-USD"]
    ) async throws -> AsyncStream<YFStreamingQuote> {
        return try await startRealTimeStreaming(symbols: cryptoSymbols)
    }
    
    /// 주요 주식 실시간 스트리밍을 시작합니다
    ///
    /// 인기 있는 주식들의 실시간 가격을 스트리밍하는 편의 메서드입니다.
    ///
    /// - Parameter stockSymbols: 주식 심볼 배열 (기본값: FAANG + Tesla)
    /// - Returns: 실시간 스트리밍 쿼트의 AsyncStream
    /// - Throws: `YFError` WebSocket 연결 또는 구독 실패 시
    public func startPopularStocksStreaming(
        stockSymbols: [String] = ["AAPL", "GOOGL", "AMZN", "NFLX", "META", "TSLA"]
    ) async throws -> AsyncStream<YFStreamingQuote> {
        return try await startRealTimeStreaming(symbols: stockSymbols)
    }
}

// MARK: - Internal WebSocket Management
extension YFClient {
    
    /// WebSocket 매니저 인스턴스 저장소 (내부 사용)
    nonisolated(unsafe) private static var webSocketManagerStore: [ObjectIdentifier: YFWebSocketManager] = [:]
    private static let managerStoreLock = NSLock()
    
    /// 클라이언트별 WebSocket 매니저를 가져오거나 생성합니다
    ///
    /// 동일한 클라이언트 인스턴스에 대해 재사용 가능한 WebSocket 매니저를 제공합니다.
    ///
    /// - Returns: 클라이언트에 연결된 WebSocket 매니저
    internal func getOrCreateWebSocketManager() -> YFWebSocketManager {
        let clientID = ObjectIdentifier(self)
        
        return Self.managerStoreLock.withLock {
            if let existingManager = Self.webSocketManagerStore[clientID] {
                return existingManager
            } else {
                let newManager = YFWebSocketManager(urlSession: self.session.urlSession)
                Self.webSocketManagerStore[clientID] = newManager
                return newManager
            }
        }
    }
    
    /// 클라이언트의 WebSocket 매니저를 정리합니다
    ///
    /// 클라이언트가 해제될 때 관련된 WebSocket 매니저도 정리합니다.
    internal func cleanupWebSocketManager() {
        let clientID = ObjectIdentifier(self)
        
        Self.managerStoreLock.withLock {
            if let manager = Self.webSocketManagerStore.removeValue(forKey: clientID) {
                Task {
                    await manager.disconnect()
                }
            }
        }
    }
}

// MARK: - NSLock Extension
extension NSLock {
    
    /// 락을 사용해서 클로저를 실행하는 편의 메서드
    fileprivate func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try body()
    }
}