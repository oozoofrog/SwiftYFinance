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
    
    /// WebSocket 연결 상태
    public enum ConnectionState: Equatable, Sendable {
        /// 연결 해제됨
        case disconnected
        /// 연결 중
        case connecting
        /// 연결됨
        case connected
    }
    
    // MARK: - Private Properties
    
    /// 현재 연결 상태
    private var connectionState: ConnectionState = .disconnected
    
    /// 기본 Yahoo Finance WebSocket URL
    private let defaultURL = "wss://streamer.finance.yahoo.com/?version=2"
    
    /// URLSession WebSocket task
    private var webSocketTask: URLSessionWebSocketTask?
    
    /// URLSession for WebSocket connections
    private let urlSession: URLSession
    
    /// 현재 구독 중인 심볼들
    private var subscriptions: Set<String> = []
    
    /// 메시지 스트림 컨티뉴에이션
    private var messageContinuation: AsyncStream<YFWebSocketMessage>.Continuation?
    
    /// 메시지 디코더
    private let messageDecoder = YFWebSocketMessageDecoder()
    
    // MARK: - Auto-Reconnection Properties
    
    /// 자동 재연결 활성화 여부
    private var autoReconnectionEnabled: Bool = false
    
    /// 재연결 시도 횟수
    private var reconnectionAttempts: Int = 0
    
    /// 총 재연결 시도 횟수 (성공 후에도 유지)
    private var totalReconnectionAttempts: Int = 0
    
    /// 최대 재연결 시도 횟수
    private var maxReconnectionAttempts: Int = 5
    
    /// 초기 재연결 지연 시간 (초)
    private var initialReconnectionDelay: TimeInterval = 0.5 // 첫 번째 재시도는 더 빠르게
    
    /// 최대 재연결 지연 시간 (초)
    private var maxReconnectionDelay: TimeInterval = 30.0
    
    /// 재연결 지연 배수
    private var reconnectionDelayMultiplier: Double = 2.0
    
    /// 재연결 지터 최대값 (초) - 동시 재연결 방지
    private var reconnectionJitterMax: TimeInterval = 1.0
    
    /// 재연결 타스크
    private var reconnectionTask: Task<Void, Never>?
    
    /// 마지막 연결 실패 시간
    private var lastConnectionFailureTime: Date?
    
    /// 연속 실패 횟수 (빠른 실패 감지용)
    private var consecutiveFailures: Int = 0
    
    /// 테스트용 잘못된 연결 모드
    private var testInvalidConnectionMode: Bool = false
    
    // MARK: - Timeout Properties
    
    /// 연결 타임아웃 (초)
    private var connectionTimeout: TimeInterval = 10.0
    
    /// 메시지 수신 타임아웃 (초)
    private var messageTimeout: TimeInterval = 30.0
    
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
        connectionState = .disconnected
        autoReconnectionEnabled = false
        reconnectionAttempts = 0
        totalReconnectionAttempts = 0
        consecutiveFailures = 0
        lastConnectionFailureTime = nil
        
        // 재연결 태스크 취소
        reconnectionTask?.cancel()
        reconnectionTask = nil
        
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
        guard connectionState == .connected else {
            throw YFError.webSocketError(.notConnected("Must be connected to WebSocket before subscribing"))
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
        guard connectionState == .connected else {
            throw YFError.webSocketError(.notConnected("Must be connected to WebSocket before unsubscribing"))
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
            if connectionState == .connected {
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
    private func sendMessage(_ message: String) async throws {
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
    private func startMessageListening() async {
        guard let webSocketTask = webSocketTask else { return }
        
        while connectionState == .connected {
            do {
                let message = try await webSocketTask.receive()
                await handleWebSocketMessage(message)
            } catch {
                // WebSocket 연결 오류 처리
                if connectionState == .connected {
                    connectionState = .disconnected
                    
                    // 자동 재연결이 활성화된 경우 재연결 시도
                    if autoReconnectionEnabled {
                        await attemptReconnection()
                    } else {
                        messageContinuation?.finish()
                    }
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
            
            // AsyncStream으로 메시지 전달
            messageContinuation?.yield(webSocketMessage)
            
        } catch {
            // 디코딩 오류는 로그로만 처리 (스트림 중단하지 않음)
            print("Message decoding error: \(error)")
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
    private func connectToURL(_ url: URL) async throws {
        connectionState = .connecting
        
        #if DEBUG
        // 테스트용 잘못된 연결 모드
        if testInvalidConnectionMode {
            connectionState = .disconnected
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
            
            connectionState = .connected
            
            // 연결 성공 시 실패 카운터 초기화
            consecutiveFailures = 0
            lastConnectionFailureTime = nil
            
            // 메시지 스트림이 활성화되어 있다면 메시지 수신 시작
            if messageContinuation != nil {
                Task {
                    await startMessageListening()
                }
            }
        } catch let error as YFError {
            connectionState = .disconnected
            consecutiveFailures += 1
            lastConnectionFailureTime = Date()
            webSocketTask?.cancel()
            webSocketTask = nil
            throw error
        } catch {
            connectionState = .disconnected
            consecutiveFailures += 1
            lastConnectionFailureTime = Date()
            webSocketTask?.cancel()
            webSocketTask = nil
            throw YFError.webSocketError(.connectionFailed("Failed to connect to \(url.absoluteString): \(error.localizedDescription)"))
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
    
    // MARK: - Testing Support (DEBUG only)
    
    #if DEBUG
    /// 현재 연결 상태 조회 (테스트용)
    ///
    /// DEBUG 빌드에서만 사용할 수 있는 연결 상태 조회 메서드입니다.
    ///
    /// - Returns: 현재 WebSocket 연결 상태
    public func testGetConnectionState() -> ConnectionState {
        return connectionState
    }
    
    /// 커스텀 URL로 WebSocket 연결 (테스트용)
    ///
    /// DEBUG 빌드에서만 사용할 수 있는 커스텀 URL 연결 메서드입니다.
    /// 테스트 목적으로만 사용하세요.
    ///
    /// - Parameter urlString: 연결할 WebSocket URL 문자열
    /// - Throws: `YFError.webSocketError` WebSocket 연결 관련 오류
    public func testConnectWithCustomURL(_ urlString: String) async throws {
        guard let url = URL(string: urlString) else {
            throw YFError.webSocketError(.invalidURL("Invalid custom WebSocket URL: \(urlString)"))
        }
        
        // Validate WebSocket scheme
        guard url.scheme == "ws" || url.scheme == "wss" else {
            throw YFError.webSocketError(.invalidURL("WebSocket URL must use ws:// or wss:// scheme: \(urlString)"))
        }
        
        try await connectToURL(url)
    }
    
    /// 현재 구독 목록 조회 (테스트용)
    ///
    /// DEBUG 빌드에서만 사용할 수 있는 구독 목록 조회 메서드입니다.
    ///
    /// - Returns: 현재 구독 중인 심볼들의 Set
    public func testGetSubscriptions() -> Set<String> {
        return subscriptions
    }
    
    /// 자동 재연결 활성화 (테스트용)
    ///
    /// DEBUG 빌드에서만 사용할 수 있는 자동 재연결 설정 메서드입니다.
    ///
    /// - Parameters:
    ///   - maxAttempts: 최대 재연결 시도 횟수
    ///   - initialDelay: 초기 재연결 지연 시간 (초)
    public func testEnableAutoReconnection(maxAttempts: Int, initialDelay: TimeInterval) {
        autoReconnectionEnabled = true
        maxReconnectionAttempts = maxAttempts
        initialReconnectionDelay = initialDelay
        reconnectionAttempts = 0
        totalReconnectionAttempts = 0
        consecutiveFailures = 0
        lastConnectionFailureTime = nil
    }
    
    /// 연결 손실 시뮬레이션 (테스트용)
    ///
    /// DEBUG 빌드에서만 사용할 수 있는 연결 손실 시뮬레이션 메서드입니다.
    public func testSimulateConnectionLoss() async {
        if connectionState == .connected {
            webSocketTask?.cancel()
            connectionState = .disconnected
            
            if autoReconnectionEnabled {
                await attemptReconnection()
            }
        }
    }
    
    /// 재연결 시도 횟수 조회 (테스트용)
    ///
    /// DEBUG 빌드에서만 사용할 수 있는 재연결 시도 횟수 조회 메서드입니다.
    ///
    /// - Returns: 현재까지의 총 재연결 시도 횟수
    public func testGetReconnectionAttempts() -> Int {
        return totalReconnectionAttempts
    }
    
    /// 재연결 파라미터 설정 (테스트용)
    ///
    /// DEBUG 빌드에서만 사용할 수 있는 재연결 파라미터 설정 메서드입니다.
    ///
    /// - Parameters:
    ///   - initialDelay: 초기 지연 시간 (초)
    ///   - maxDelay: 최대 지연 시간 (초)
    ///   - multiplier: 지연 시간 배수
    public func testSetReconnectionParams(
        initialDelay: TimeInterval,
        maxDelay: TimeInterval,
        multiplier: Double
    ) {
        initialReconnectionDelay = initialDelay
        maxReconnectionDelay = maxDelay
        reconnectionDelayMultiplier = multiplier
    }
    
    /// 재연결 지연 시간 계산 (테스트용)
    ///
    /// DEBUG 빌드에서만 사용할 수 있는 지연 시간 계산 메서드입니다.
    ///
    /// - Parameter attempt: 재연결 시도 횟수
    /// - Returns: 계산된 지연 시간 (초)
    public func testCalculateReconnectionDelay(attempt: Int) -> TimeInterval {
        return calculateReconnectionDelay(attempt: attempt)
    }
    
    /// 잘못된 연결 모드 설정 (테스트용)
    ///
    /// DEBUG 빌드에서만 사용할 수 있는 잘못된 연결 모드 설정 메서드입니다.
    ///
    /// - Parameter enabled: 잘못된 연결 모드 활성화 여부
    public func testSetInvalidConnectionMode(_ enabled: Bool) {
        testInvalidConnectionMode = enabled
    }
    
    /// 타임아웃 설정 (테스트용)
    ///
    /// DEBUG 빌드에서만 사용할 수 있는 타임아웃 설정 메서드입니다.
    ///
    /// - Parameters:
    ///   - connectionTimeout: 연결 타임아웃 (초)
    ///   - messageTimeout: 메시지 수신 타임아웃 (초)
    public func testSetTimeouts(connectionTimeout: TimeInterval, messageTimeout: TimeInterval) {
        self.connectionTimeout = connectionTimeout
        self.messageTimeout = messageTimeout
    }
    
    /// 연속 실패 횟수 조회 (테스트용)
    ///
    /// DEBUG 빌드에서만 사용할 수 있는 연속 실패 횟수 조회 메서드입니다.
    ///
    /// - Returns: 현재 연속 실패 횟수
    public func testGetConsecutiveFailures() -> Int {
        return consecutiveFailures
    }
    
    /// 마지막 연결 실패 시간 조회 (테스트용)
    ///
    /// DEBUG 빌드에서만 사용할 수 있는 마지막 실패 시간 조회 메서드입니다.
    ///
    /// - Returns: 마지막 연결 실패 시간
    public func testGetLastConnectionFailureTime() -> Date? {
        return lastConnectionFailureTime
    }
    
    /// 최적화된 재연결 지연 시간 계산 (테스트용)
    ///
    /// DEBUG 빌드에서만 사용할 수 있는 최적화된 지연 시간 계산 메서드입니다.
    ///
    /// - Parameter attempt: 재연결 시도 횟수
    /// - Returns: 계산된 지연 시간 (초)
    public func testCalculateOptimizedReconnectionDelay(attempt: Int) -> TimeInterval {
        return calculateOptimizedReconnectionDelay(attempt: attempt)
    }
    #endif
    
    // MARK: - Auto-Reconnection Implementation
    
    /// 자동 재연결 시도
    ///
    /// 최적화된 exponential backoff + jitter 알고리즘을 사용하여 재연결을 시도합니다.
    private func attemptReconnection() async {
        guard autoReconnectionEnabled else { return }
        guard reconnectionAttempts < maxReconnectionAttempts else {
            print("⚠️ Max reconnection attempts (\(maxReconnectionAttempts)) reached")
            messageContinuation?.finish()
            return
        }
        
        // 빠른 실패 감지: 연속 실패가 많으면 재연결 간격 늘리기
        if shouldSkipReconnectionAttempt() {
            print("⏭️ Skipping reconnection attempt due to recent failures")
            await scheduleDelayedReconnection()
            return
        }
        
        reconnectionAttempts += 1
        totalReconnectionAttempts += 1
        consecutiveFailures += 1
        lastConnectionFailureTime = Date()
        
        // 최적화된 지연 시간 계산 (exponential backoff + jitter)
        let delay = calculateOptimizedReconnectionDelay(attempt: reconnectionAttempts)
        
        print("🔄 Reconnection attempt \(reconnectionAttempts)/\(maxReconnectionAttempts) in \(String(format: "%.1f", delay))s")
        
        reconnectionTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            
            // 취소되지 않았고 여전히 재연결이 필요한 경우
            if !Task.isCancelled && connectionState == .disconnected && autoReconnectionEnabled {
                do {
                    try await connect()
                    
                    // 연결 성공 시 상태 초기화
                    reconnectionAttempts = 0
                    consecutiveFailures = 0
                    lastConnectionFailureTime = nil
                    print("✅ Reconnection successful after \(totalReconnectionAttempts) total attempts")
                    
                    // 재구독 (기존 구독 유지)
                    if !subscriptions.isEmpty {
                        try await subscribe(to: Array(subscriptions))
                    }
                    
                    // 메시지 리스닝 재시작
                    Task {
                        await startMessageListening()
                    }
                    
                } catch {
                    print("❌ Reconnection attempt \(reconnectionAttempts) failed: \(error)")
                    
                    // 에러 타입에 따른 재시도 결정
                    if shouldRetryAfterError(error) && reconnectionAttempts < maxReconnectionAttempts {
                        await attemptReconnection()
                    } else {
                        print("⚠️ All reconnection attempts failed or permanent error detected")
                        messageContinuation?.finish()
                    }
                }
            }
        }
    }
    
    /// 최적화된 재연결 지연 시간 계산 (exponential backoff + jitter)
    ///
    /// - Parameter attempt: 재연결 시도 횟수 (1부터 시작)
    /// - Returns: 계산된 지연 시간 (초)
    private func calculateOptimizedReconnectionDelay(attempt: Int) -> TimeInterval {
        // 기본 exponential backoff
        let baseDelay = initialReconnectionDelay * pow(reconnectionDelayMultiplier, Double(attempt - 1))
        let cappedDelay = min(baseDelay, maxReconnectionDelay)
        
        // 지터 추가 (동시 재연결 방지)
        let jitter = Double.random(in: 0...reconnectionJitterMax)
        
        return cappedDelay + jitter
    }
    
    /// 재연결 시도를 건너뛸지 결정
    ///
    /// 연속 실패가 많거나 최근에 실패한 경우 재연결을 건너뜁니다.
    ///
    /// - Returns: 재연결을 건너뛸지 여부
    private func shouldSkipReconnectionAttempt() -> Bool {
        // 연속 실패가 많은 경우
        if consecutiveFailures >= 3 {
            // 마지막 실패 후 충분한 시간이 지나지 않았다면 건너뛰기
            if let lastFailure = lastConnectionFailureTime,
               Date().timeIntervalSince(lastFailure) < 5.0 {
                return true
            }
        }
        
        return false
    }
    
    /// 지연된 재연결 스케줄링
    ///
    /// 빈번한 실패 시 더 긴 간격으로 재연결을 시도합니다.
    private func scheduleDelayedReconnection() async {
        let extendedDelay = min(30.0, Double(consecutiveFailures) * 5.0) // 5초씩 늘려서 최대 30초
        
        reconnectionTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(extendedDelay * 1_000_000_000))
            
            if !Task.isCancelled && connectionState == .disconnected && autoReconnectionEnabled {
                await attemptReconnection()
            }
        }
    }
    
    /// 에러 타입에 따른 재시도 결정
    ///
    /// 특정 에러 타입에 대해서는 재시도를 하지 않습니다.
    ///
    /// - Parameter error: 발생한 에러
    /// - Returns: 재시도 여부
    private func shouldRetryAfterError(_ error: Error) -> Bool {
        if let yfError = error as? YFError {
            switch yfError {
            case .webSocketError(.invalidURL):
                // 잘못된 URL은 재시도해도 의미없음
                return false
            case .webSocketError(.connectionTimeout):
                // 타임아웃은 재시도 가능
                return true
            case .webSocketError(.connectionFailed):
                // 연결 실패는 재시도 가능
                return true
            default:
                return true
            }
        }
        
        // 알 수 없는 에러는 재시도
        return true
    }
    
    /// Exponential backoff 지연 시간 계산 (기존 호환성)
    ///
    /// - Parameter attempt: 재연결 시도 횟수 (1부터 시작)
    /// - Returns: 계산된 지연 시간 (초)
    private func calculateReconnectionDelay(attempt: Int) -> TimeInterval {
        return calculateOptimizedReconnectionDelay(attempt: attempt)
    }
}