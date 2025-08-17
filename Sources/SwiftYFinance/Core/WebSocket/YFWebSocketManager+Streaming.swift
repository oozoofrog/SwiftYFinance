import Foundation

// MARK: - Message Streaming

extension YFWebSocketManager {
    
    /// 실시간 메시지 스트림 제공
    ///
    /// AsyncStream을 통해 WebSocket으로부터 수신되는 실시간 메시지를 스트리밍합니다.
    /// 백그라운드에서 지속적으로 메시지를 수신하고 Protobuf 디코딩을 수행합니다.
    ///
    /// - Returns: YFWebSocketMessage의 AsyncStream
    ///
    /// ## 사용 예시
    /// ```swift
    /// let manager = YFWebSocketManager()
    /// try await manager.connect()
    /// try await manager.subscribe(to: ["AAPL", "TSLA"])
    /// 
    /// let messageStream = await manager.messageStream()
    /// for await message in messageStream {
    ///     print("Received: \(message.symbol) - \(message.price)")
    /// }
    /// ```
    public func messageStream() async -> AsyncStream<YFWebSocketMessage> {
        return AsyncStream { continuation in
            Task {
                await self.setupMessageStream(with: continuation)
            }
            
            continuation.onTermination = { _ in
                Task {
                    await self.clearMessageContinuation()
                }
            }
        }
    }
    
    /// 메시지 스트림 설정 (Actor-safe)
    ///
    /// - Parameter continuation: AsyncStream의 continuation
    private func setupMessageStream(with continuation: AsyncStream<YFWebSocketMessage>.Continuation) async {
        messageContinuation = continuation
        
        // Start background message listening if connected
        if await isUsableState {
            await startMessageListening()
        }
    }
    
    /// 메시지 continuation 정리 (Actor-safe)
    private func clearMessageContinuation() async {
        messageContinuation = nil
    }
    
    /// 백그라운드에서 WebSocket 메시지 수신 시작
    ///
    /// 연속적으로 WebSocket 메시지를 수신하고 Protobuf 디코딩하여 AsyncStream으로 전달합니다.
    internal func startMessageListening() async {
        guard let webSocketTask = webSocketTask else { return }
        
        while await isUsableState {
            do {
                let message = try await webSocketTask.receive()
                await handleWebSocketMessage(message)
            } catch {
                // WebSocket 연결 오류 처리
                if await isUsableState {
                    await changeConnectionState(to: .disconnected, reason: "Message listening error: \(error)")
                    messageContinuation?.finish()
                }
                break
            }
        }
    }
}