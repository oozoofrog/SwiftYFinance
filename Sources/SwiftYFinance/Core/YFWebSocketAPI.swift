import Foundation

// MARK: - WebSocket API Extension
extension YFClient {
    
    /// 실시간 스트리밍을 시작합니다
    ///
    /// Yahoo Finance WebSocket을 통해 실시간 주식 가격 데이터를 스트리밍합니다.
    /// 각 호출마다 새로운 WebSocket 연결을 생성하며, 단일 연결로 여러 심볼을 구독할 수 있습니다.
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
    /// - Returns: 실시간 스트리밍 쿼트의 AsyncStream (단일 연결)
    /// - Throws: `YFError` WebSocket 연결 또는 구독 실패 시
    public func startRealTimeStreaming(symbols: [String]) async throws -> AsyncStream<YFStreamingQuote> {
        // 단일 WebSocket 매니저 생성
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
    
    /// 새로운 WebSocket 매니저를 생성합니다
    ///
    /// 단일 WebSocket 연결을 직접 제어하고 싶을 때 사용하는 저수준 API입니다.
    /// 각 호출마다 새로운 매니저 인스턴스를 생성합니다.
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
    /// - Returns: 새로운 YFWebSocketManager 인스턴스
    public func createWebSocketManager() -> YFWebSocketManager {
        return YFWebSocketManager(urlSession: self.session.urlSession)
    }
    
    /// 실시간 스트리밍 사용 가능 여부를 확인합니다
    ///
    /// 클라이언트 세션이 WebSocket 연결을 생성할 수 있는 상태인지 확인하는 유틸리티 메서드입니다.
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
    /// 주요 암호화폐들의 실시간 가격을 단일 WebSocket 연결로 스트리밍하는 편의 메서드입니다.
    ///
    /// - Parameter cryptoSymbols: 암호화폐 심볼 배열 (기본값: 주요 암호화폐)
    /// - Returns: 실시간 스트리밍 쿼트의 AsyncStream (단일 연결)
    /// - Throws: `YFError` WebSocket 연결 또는 구독 실패 시
    public func startCryptoStreaming(
        cryptoSymbols: [String] = ["BTC-USD", "ETH-USD", "ADA-USD", "XRP-USD"]
    ) async throws -> AsyncStream<YFStreamingQuote> {
        return try await startRealTimeStreaming(symbols: cryptoSymbols)
    }
    
    /// 주요 주식 실시간 스트리밍을 시작합니다
    ///
    /// 인기 있는 주식들의 실시간 가격을 단일 WebSocket 연결로 스트리밍하는 편의 메서드입니다.
    ///
    /// - Parameter stockSymbols: 주식 심볼 배열 (기본값: FAANG + Tesla)
    /// - Returns: 실시간 스트리밍 쿼트의 AsyncStream (단일 연결)
    /// - Throws: `YFError` WebSocket 연결 또는 구독 실패 시
    public func startPopularStocksStreaming(
        stockSymbols: [String] = ["AAPL", "GOOGL", "AMZN", "NFLX", "META", "TSLA"]
    ) async throws -> AsyncStream<YFStreamingQuote> {
        return try await startRealTimeStreaming(symbols: stockSymbols)
    }
}

