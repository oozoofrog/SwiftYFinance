import Foundation

/// Yahoo Finance WebSocket 연결 관리자
///
/// Yahoo Finance WebSocket 서버와의 실시간 연결을 관리하고
/// 스트리밍 데이터를 처리하는 핵심 클래스입니다.
///
/// ## 기본 사용법
/// ```swift
/// let manager = YFWebSocketManager()
/// try await manager.connect()
/// await manager.disconnect()
/// ```
///
/// ## 테스트 지원
/// DEBUG 빌드에서는 테스트를 위한 추가 API를 제공합니다:
/// ```swift
/// #if DEBUG
/// let state = manager.testGetConnectionState()
/// try await manager.testConnectWithCustomURL("wss://test.example.com")
/// #endif
/// ```
///
/// - SeeAlso: `YFWebSocketMessage` WebSocket 메시지 데이터
/// - SeeAlso: `YFStreamingQuote` 실시간 스트리밍 쿼트
public actor YFWebSocketManager {
    
    /// WebSocket 연결 상태 (분리된 타입 별칭)
    public typealias ConnectionState = YFWebSocketConnectionState
    
    // MARK: - Private Properties
    
    /// 내부 상태 관리 Actor
    internal let internalState = YFWebSocketInternalState()
    
    /// 기본 Yahoo Finance WebSocket URL
    private let defaultURL = "wss://streamer.finance.yahoo.com/?version=2"
    
    /// 메시지 디코더
    internal let messageDecoder = YFWebSocketMessageDecoder()
    
    // MARK: - Composition Components
    
    /// WebSocket 연결 관리자
    internal let connection: YFWebSocketConnection
    
    /// 메시지 처리기
    internal let messageProcessor: YFMessageProcessor
    
    /// 구독 관리자
    internal let subscriptionRegistry: YFSubscriptionRegistry
    
    /// 스트림 제공자
    internal let streamProvider: YFStreamProvider
    
    // MARK: - Initialization
    
    /// YFWebSocketManager 초기화
    ///
    /// 기본 URLSession으로 WebSocket 관리자를 생성합니다.
    public init() {
        let urlSession = URLSession(configuration: .default)
        self.connection = YFWebSocketConnection(urlSession: urlSession, stateManager: internalState)
        self.messageProcessor = YFMessageProcessor(messageDecoder: messageDecoder, stateManager: internalState)
        self.subscriptionRegistry = YFSubscriptionRegistry(stateManager: internalState)
        self.streamProvider = YFStreamProvider(messageProcessor: messageProcessor, stateManager: internalState)
    }
    
    /// YFWebSocketManager 초기화 (커스텀 URLSession)
    ///
    /// 사용자 정의 URLSession으로 WebSocket 관리자를 생성합니다.
    ///
    /// - Parameter urlSession: 사용할 URLSession
    public init(urlSession: URLSession) {
        self.connection = YFWebSocketConnection(urlSession: urlSession, stateManager: internalState)
        self.messageProcessor = YFMessageProcessor(messageDecoder: messageDecoder, stateManager: internalState)
        self.subscriptionRegistry = YFSubscriptionRegistry(stateManager: internalState)
        self.streamProvider = YFStreamProvider(messageProcessor: messageProcessor, stateManager: internalState)
    }
    
    // MARK: - Public API
    
    /// Yahoo Finance WebSocket 서버에 연결
    ///
    /// 기본 Yahoo Finance WebSocket URL로 연결을 시도합니다.
    ///
    /// - Throws: `YFError.webSocketError` WebSocket 연결 관련 오류
    public func connect() async throws {
        guard let url = URL(string: defaultURL) else {
            throw YFError.webSocketError(.invalidURL("Invalid default WebSocket URL: \(defaultURL)"))
        }
        
        try await connection.connectToURL(url)
    }
    
    /// WebSocket 연결 해제
    ///
    /// 활성 WebSocket 연결을 정상적으로 종료합니다.
    public func disconnect() async {
        await connection.disconnect()
        
        await subscriptionRegistry.clearSubscriptions()
        await streamProvider.forceCleanupMessageContinuation()
    }
    
    // MARK: - Connection Management
    
    /// 지정된 URL로 WebSocket 연결 시도
    ///
    /// - Parameter url: 연결할 WebSocket URL
    /// - Throws: `YFError.webSocketError` WebSocket 연결 관련 오류
    internal func connectToURL(_ url: URL) async throws {
        // connection 객체에 위임
        try await connection.connectToURL(url)
        
        // 메시지 스트림이 활성화되어 있다면 메시지 수신 시작
        let hasMessageContinuation = await streamProvider.hasMessageContinuation()
        if hasMessageContinuation {
            Task {
                await startMessageListening()
            }
        }
    }
    
    /// WebSocket task 접근을 위한 내부 헬퍼
    ///
    /// - Returns: 현재 WebSocket task
    internal var webSocketTask: URLSessionWebSocketTask? {
        get async {
            return await connection.webSocketTask
        }
    }
    
    // MARK: - Message Handling
    
    /// WebSocket으로 메시지 전송
    ///
    /// - Parameter message: 전송할 JSON 메시지 문자열
    /// - Throws: `YFError.webSocketError` 메시지 전송 실패 시
    internal func sendMessage(_ message: String) async throws {
        let webSocketTask = await webSocketTask
        try await messageProcessor.sendMessage(message, using: webSocketTask)
    }
    
    /// WebSocket 메시지 처리
    ///
    /// 수신된 WebSocket 메시지를 파싱하고 Protobuf 디코딩하여 스트림으로 전달합니다.
    ///
    /// - Parameter message: URLSessionWebSocketTask.Message
    internal func handleWebSocketMessage(_ message: URLSessionWebSocketTask.Message) async {
        await messageProcessor.handleWebSocketMessage(message)
    }
    
    // MARK: - Internal State Access Properties
    
    /// 현재 연결 상태 조회
    internal var connectionState: ConnectionState {
        get async {
            return await internalState.getConnectionState()
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
    
    // MARK: - Message Streaming Support
    
    /// 백그라운드에서 WebSocket 메시지 수신 시작
    ///
    /// 연속적으로 WebSocket 메시지를 수신하고 Protobuf 디코딩하여 AsyncStream으로 전달합니다.
    internal func startMessageListening() async {
        let webSocketTask = await webSocketTask
        await streamProvider.startMessageListening(
            webSocketTask: webSocketTask,
            isUsableState: { await self.isUsableState },
            handleMessage: { message in await self.handleWebSocketMessage(message) },
            onError: { error in 
                await self.changeConnectionState(to: .disconnected, reason: "Message listening error: \(error)")
            }
        )
    }
    
}