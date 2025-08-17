import Foundation

/// WebSocket 메시지 스트리밍 전용 Actor
///
/// AsyncStream 제공과 백그라운드 메시지 수신을 담당합니다.
/// Single Responsibility Principle에 따라 스트리밍 관련 기능만 제공합니다.
internal actor YFStreamProvider {
    
    // MARK: - Properties
    
    /// 메시지 처리기 (외부 주입)
    private let messageProcessor: YFMessageProcessor
    
    /// 상태 관리 Actor (외부 주입)
    private let stateManager: YFWebSocketInternalState
    
    // MARK: - Initialization
    
    /// 스트림 제공자 초기화
    ///
    /// - Parameters:
    ///   - messageProcessor: 메시지 처리를 담당하는 Actor
    ///   - stateManager: 상태 관리를 담당하는 Actor
    internal init(messageProcessor: YFMessageProcessor, stateManager: YFWebSocketInternalState) {
        self.messageProcessor = messageProcessor
        self.stateManager = stateManager
    }
    
    // MARK: - Stream Management
    
    /// 실시간 메시지 스트림 제공
    ///
    /// AsyncStream을 통해 WebSocket으로부터 수신되는 실시간 메시지를 스트리밍합니다.
    /// 백그라운드에서 지속적으로 메시지를 수신하고 Protobuf 디코딩을 수행합니다.
    ///
    /// - Parameters:
    ///   - isUsableState: 현재 연결 상태가 사용 가능한지 확인하는 클로저
    ///   - startListening: 메시지 수신을 시작하는 클로저
    /// - Returns: YFWebSocketMessage의 AsyncStream
    internal func createMessageStream(
        isUsableState: @escaping @Sendable () async -> Bool,
        startListening: @escaping @Sendable () async -> Void
    ) async -> AsyncStream<YFWebSocketMessage> {
        return AsyncStream { continuation in
            Task {
                await self.setupMessageStream(
                    with: continuation,
                    isUsableState: isUsableState,
                    startListening: startListening
                )
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
    /// - Parameters:
    ///   - continuation: AsyncStream의 continuation
    ///   - isUsableState: 현재 연결 상태가 사용 가능한지 확인하는 클로저
    ///   - startListening: 메시지 수신을 시작하는 클로저
    private func setupMessageStream(
        with continuation: AsyncStream<YFWebSocketMessage>.Continuation,
        isUsableState: @escaping @Sendable () async -> Bool,
        startListening: @escaping @Sendable () async -> Void
    ) async {
        await messageProcessor.setMessageContinuation(continuation)
        
        // Start background message listening if connected
        if await isUsableState() {
            await startListening()
        }
    }
    
    /// 메시지 continuation 정리 (Actor-safe)
    private func clearMessageContinuation() async {
        await messageProcessor.clearMessageContinuation()
    }
    
    // MARK: - Message Listening Management
    
    /// 백그라운드에서 WebSocket 메시지 수신 시작
    ///
    /// 연속적으로 WebSocket 메시지를 수신하고 Protobuf 디코딩하여 AsyncStream으로 전달합니다.
    ///
    /// - Parameters:
    ///   - webSocketTask: 메시지를 수신할 WebSocket task
    ///   - isUsableState: 현재 연결 상태가 사용 가능한지 확인하는 클로저
    ///   - handleMessage: 수신된 메시지를 처리하는 클로저
    ///   - onError: 오류 발생 시 호출되는 클로저
    internal func startMessageListening(
        webSocketTask: URLSessionWebSocketTask?,
        isUsableState: @escaping @Sendable () async -> Bool,
        handleMessage: @escaping @Sendable (URLSessionWebSocketTask.Message) async -> Void,
        onError: @escaping @Sendable (Error) async -> Void
    ) async {
        guard let webSocketTask = webSocketTask else { return }
        
        while await isUsableState() {
            do {
                let message = try await webSocketTask.receive()
                await handleMessage(message)
            } catch {
                // WebSocket 연결 오류 처리
                if await isUsableState() {
                    await onError(error)
                    await messageProcessor.clearMessageContinuation()
                }
                break
            }
        }
    }
    
    // MARK: - State Access
    
    /// 메시지 continuation 존재 여부 확인
    ///
    /// - Returns: continuation이 설정되어 있는지 여부
    internal func hasMessageContinuation() async -> Bool {
        return await messageProcessor.hasMessageContinuation()
    }
    
    /// 메시지 continuation 강제 정리
    ///
    /// 연결 해제 시나 오류 상황에서 사용됩니다.
    internal func forceCleanupMessageContinuation() async {
        await messageProcessor.clearMessageContinuation()
    }
}