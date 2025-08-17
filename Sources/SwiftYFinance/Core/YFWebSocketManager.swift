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
public class YFWebSocketManager: @unchecked Sendable {
    
    /// WebSocket 연결 상태 (분리된 타입 별칭)
    public typealias ConnectionState = YFWebSocketConnectionState
    
    // MARK: - Private Properties
    
    /// 현재 연결 상태
    internal var _connectionState: ConnectionState = .disconnected
    
    /// 상태 전환 로그
    internal var stateTransitionLog: [YFWebSocketStateTransition] = []
    internal let maxStateTransitionEntries = 20
    
    /// 현재 연결 상태 (읽기 전용)
    internal var connectionState: ConnectionState {
        return _connectionState
    }
    
    /// 기본 Yahoo Finance WebSocket URL
    private let defaultURL = "wss://streamer.finance.yahoo.com/?version=2"
    
    /// URLSession WebSocket task
    internal var webSocketTask: URLSessionWebSocketTask?
    
    /// URLSession for WebSocket connections
    private let urlSession: URLSession
    
    /// 현재 구독 중인 심볼들
    internal var subscriptions: Set<String> = []
    
    /// 메시지 스트림 컨티뉴에이션
    internal var messageContinuation: AsyncStream<YFWebSocketMessage>.Continuation?
    
    /// 메시지 디코더
    private let messageDecoder = YFWebSocketMessageDecoder()
    
    // MARK: - Connection Monitoring Properties
    
    /// 연속 실패 횟수
    internal var consecutiveFailures: Int = 0
    
    /// 테스트용 잘못된 연결 모드
    internal var testInvalidConnectionMode: Bool = false
    
    // MARK: - Connection Quality Monitoring
    
    /// 연결 품질 메트릭
    internal var connectionQuality = YFWebSocketConnectionQuality()
    
    /// 에러 로그
    internal var errorLog: [YFWebSocketErrorLogEntry] = []
    internal let maxErrorLogEntries = 50
    
    // MARK: - Timeout Properties
    
    /// 연결 타임아웃 (초)
    internal var connectionTimeout: TimeInterval = 10.0
    
    /// 메시지 수신 타임아웃 (초)
    internal var messageTimeout: TimeInterval = 30.0
    
    // MARK: - Initialization
    
    /// YFWebSocketManager 초기화
    ///
    /// 기본 URLSession으로 WebSocket 관리자를 생성합니다.
    public init() {
        self.urlSession = URLSession(configuration: .default)
    }
    
    /// YFWebSocketManager 초기화 (커스텀 URLSession)
    ///
    /// 사용자 정의 URLSession으로 WebSocket 관리자를 생성합니다.
    ///
    /// - Parameter urlSession: 사용할 URLSession
    public init(urlSession: URLSession) {
        self.urlSession = urlSession
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
        
        try await connectToURL(url)
    }
    
    /// WebSocket 연결 해제
    ///
    /// 활성 WebSocket 연결을 정상적으로 종료합니다.
    public func disconnect() async {
        changeConnectionState(to: .disconnected, reason: "User requested disconnect")
        
        subscriptions.removeAll()
        messageContinuation?.finish()
        messageContinuation = nil
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }
    
    // MARK: - Subscription Management
    
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
        guard isUsableState else {
            throw YFError.webSocketError(.notConnected("Must be connected to WebSocket before subscribing (current state: \(connectionState))"))
        }
        
        guard !symbols.isEmpty else {
            throw YFError.webSocketError(.invalidSubscription("Cannot subscribe to empty symbol list"))
        }
        
        // 중복 제거 및 구독 목록 업데이트
        let uniqueSymbols = Set(symbols)
        subscriptions.formUnion(uniqueSymbols)
        
        // JSON 구독 메시지 생성 및 전송
        let message = Self.createSubscriptionMessage(symbols: Array(subscriptions))
        try await sendMessage(message)
    }
    
    /// 심볼 구독 취소
    ///
    /// 지정된 심볼들의 실시간 데이터 구독을 취소합니다.
    ///
    /// - Parameter symbols: 구독 취소할 심볼 배열
    /// - Throws: `YFError.webSocketError` 연결 또는 구독 관련 오류
    public func unsubscribe(from symbols: [String]) async throws {
        guard isUsableState else {
            throw YFError.webSocketError(.notConnected("Must be connected to WebSocket before unsubscribing (current state: \(connectionState))"))
        }
        
        guard !symbols.isEmpty else {
            return // 빈 배열 무시
        }
        
        // 구독 목록에서 제거
        let symbolsToRemove = Set(symbols)
        subscriptions.subtract(symbolsToRemove)
        
        // JSON 구독 취소 메시지 생성 및 전송
        let message = Self.createUnsubscriptionMessage(symbols: symbols)
        try await sendMessage(message)
    }
    
    // MARK: - Message Streaming
    
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
            self.messageContinuation = continuation
            
            // Start background message listening if connected
            if isUsableState {
                Task {
                    await startMessageListening()
                }
            }
            
            continuation.onTermination = { _ in
                self.messageContinuation = nil
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// WebSocket으로 메시지 전송
    ///
    /// - Parameter message: 전송할 JSON 메시지 문자열
    /// - Throws: `YFError.webSocketError` 메시지 전송 실패 시
    internal func sendMessage(_ message: String) async throws {
        guard let webSocketTask = webSocketTask else {
            throw YFError.webSocketError(.notConnected("WebSocket task not available"))
        }
        
        do {
            let urlSessionMessage = URLSessionWebSocketTask.Message.string(message)
            try await webSocketTask.send(urlSessionMessage)
        } catch {
            throw YFError.webSocketError(.connectionFailed("Failed to send message: \(error.localizedDescription)"))
        }
    }
    
    /// 백그라운드에서 WebSocket 메시지 수신 시작
    ///
    /// 연속적으로 WebSocket 메시지를 수신하고 Protobuf 디코딩하여 AsyncStream으로 전달합니다.
    internal func startMessageListening() async {
        guard let webSocketTask = webSocketTask else { return }
        
        while isUsableState {
            do {
                let message = try await webSocketTask.receive()
                await handleWebSocketMessage(message)
            } catch {
                // WebSocket 연결 오류 처리
                if isUsableState {
                    changeConnectionState(to: .disconnected, reason: "Message listening error: \(error)")
                    messageContinuation?.finish()
                }
                break
            }
        }
    }
    
    /// WebSocket 메시지 처리
    ///
    /// 수신된 WebSocket 메시지를 파싱하고 Protobuf 디코딩하여 스트림으로 전달합니다.
    ///
    /// - Parameter message: URLSessionWebSocketTask.Message
    private func handleWebSocketMessage(_ message: URLSessionWebSocketTask.Message) async {
        switch message {
        case .string(let text):
            await handleStringMessage(text)
        case .data(let data):
            await handleDataMessage(data)
        @unknown default:
            break
        }
    }
    
    /// 문자열 WebSocket 메시지 처리
    ///
    /// Yahoo Finance WebSocket은 JSON 형태로 메시지를 전송합니다.
    /// 형식: {"message": "base64_encoded_protobuf_data"}
    ///
    /// - Parameter text: JSON 형태의 문자열 메시지
    private func handleStringMessage(_ text: String) async {
        do {
            // JSON 파싱
            guard let jsonData = text.data(using: .utf8),
                  let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                  let encodedMessage = jsonObject["message"] as? String else {
                return
            }
            
            // Protobuf 메시지 디코딩
            let webSocketMessage = try messageDecoder.decode(encodedMessage)
            
            // 메시지 수신 기록
            recordMessageReceived()
            
            // AsyncStream으로 메시지 전달
            messageContinuation?.yield(webSocketMessage)
            
        } catch {
            // 디코딩 오류는 로그로만 처리 (스트림 중단하지 않음)
            let yfError = YFError.webSocketError(.messageDecodingFailed("Failed to decode message: \(error.localizedDescription)"))
            logError(yfError, context: "Message decoding")
        }
    }
    
    /// 바이너리 WebSocket 메시지 처리
    ///
    /// 바이너리 메시지가 수신된 경우의 처리 (현재 Yahoo Finance는 문자열 전송)
    ///
    /// - Parameter data: 바이너리 데이터
    private func handleDataMessage(_ data: Data) async {
        // Yahoo Finance WebSocket은 주로 문자열 기반이므로 기본 구현만 제공
        print("Received binary message: \(data.count) bytes")
    }
    
    /// 지정된 URL로 WebSocket 연결 시도
    ///
    /// - Parameter url: 연결할 WebSocket URL
    /// - Throws: `YFError.webSocketError` WebSocket 연결 관련 오류
    internal func connectToURL(_ url: URL) async throws {
        changeConnectionState(to: .connecting, reason: "Connection attempt to \(url.host ?? "unknown")")
        
        #if DEBUG
        // 테스트용 잘못된 연결 모드
        if testInvalidConnectionMode {
            changeConnectionState(to: .failed, reason: "Test invalid connection mode enabled")
            throw YFError.webSocketError(.connectionFailed("Test invalid connection mode enabled"))
        }
        #endif
        
        do {
            // 타임아웃과 함께 연결 시도
            let timeoutTask = Task {
                try await Task.sleep(nanoseconds: UInt64(connectionTimeout * 1_000_000_000))
                throw YFError.webSocketError(.connectionTimeout("Connection timeout after \(connectionTimeout) seconds"))
            }
            
            let connectionTask = Task {
                webSocketTask = urlSession.webSocketTask(with: url)
                webSocketTask?.resume()
                
                // WebSocket 연결 확인을 위한 간단한 핑 테스트
                // URLSessionWebSocketTask의 경우 resume() 호출만으로는 실제 연결이 보장되지 않음
                if let task = webSocketTask {
                    // 연결 테스트를 위한 핑 메시지 (비어있는 문자열)
                    let testMessage = URLSessionWebSocketTask.Message.string("")
                    try await task.send(testMessage)
                }
            }
            
            // 연결과 타임아웃 중 먼저 완료되는 것을 기다림
            do {
                try await connectionTask.value
                timeoutTask.cancel()
            } catch {
                connectionTask.cancel()
                timeoutTask.cancel()
                throw error
            }
            
            changeConnectionState(to: .connected, reason: "WebSocket connection established")
            
            // 연결 성공 기록
            recordConnectionSuccess()
            
            // 메시지 스트림이 활성화되어 있다면 메시지 수신 시작
            if messageContinuation != nil {
                Task {
                    await startMessageListening()
                }
            }
        } catch let error as YFError {
            changeConnectionState(to: .disconnected, reason: "Connection failed: \(error)")
            consecutiveFailures += 1
            webSocketTask?.cancel()
            webSocketTask = nil
            
            // 에러 로깅
            logError(error, context: "WebSocket connection to \(url.absoluteString)")
            throw error
        } catch {
            changeConnectionState(to: .disconnected, reason: "Connection failed: \(error)")
            consecutiveFailures += 1
            webSocketTask?.cancel()
            webSocketTask = nil
            
            let yfError = YFError.webSocketError(.connectionFailed("Failed to connect to \(url.absoluteString): \(error.localizedDescription)"))
            // 에러 로깅
            logError(yfError, context: "WebSocket connection to \(url.absoluteString)")
            throw yfError
        }
    }
    
    // MARK: - Static Utility Methods
    
    /// 구독 JSON 메시지 생성
    ///
    /// Yahoo Finance WebSocket 프로토콜에 맞는 구독 메시지를 생성합니다.
    ///
    /// - Parameter symbols: 구독할 심볼 배열
    /// - Returns: JSON 형식의 구독 메시지 문자열
    static func createSubscriptionMessage(symbols: [String]) -> String {
        let subscriptionData: [String: [String]] = ["subscribe": symbols]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: subscriptionData, options: [])
            return String(data: jsonData, encoding: .utf8) ?? "{\"subscribe\":[]}"
        } catch {
            return "{\"subscribe\":[]}"
        }
    }
    
    /// 구독 취소 JSON 메시지 생성
    ///
    /// Yahoo Finance WebSocket 프로토콜에 맞는 구독 취소 메시지를 생성합니다.
    ///
    /// - Parameter symbols: 구독 취소할 심볼 배열
    /// - Returns: JSON 형식의 구독 취소 메시지 문자열
    static func createUnsubscriptionMessage(symbols: [String]) -> String {
        let unsubscriptionData: [String: [String]] = ["unsubscribe": symbols]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: unsubscriptionData, options: [])
            return String(data: jsonData, encoding: .utf8) ?? "{\"unsubscribe\":[]}"
        } catch {
            return "{\"unsubscribe\":[]}"
        }
    }
    
    // MARK: - Connection Management API
    
    /// 연결 시도 수
    internal var connectionAttempts: Int {
        return consecutiveFailures + 1
    }
    
    // MARK: - Error Logging API (Implemented in StateManagement extension)
    
    // 에러 로깅 및 성공 기록 메서드들은 StateManagement extension에서 구현됨
    
    // MARK: - State Management API (Implemented in StateManagement extension)
    
    /// 현재 연결 상태가 활성 상태인지 확인
    internal var isActiveState: Bool {
        return [.connecting, .connected].contains(connectionState)
    }
    
    /// 현재 연결 상태가 사용 가능한 상태인지 확인
    internal var isUsableState: Bool {
        return connectionState == .connected
    }
    
    /// 현재 연결 상태가 재시도 가능한 상태인지 확인
    internal var canRetryConnection: Bool {
        return [.disconnected, .failed].contains(connectionState)
    }
    
    // 상태 변경 및 이벤트 처리 메서드들은 StateManagement extension에서 구현됨
}