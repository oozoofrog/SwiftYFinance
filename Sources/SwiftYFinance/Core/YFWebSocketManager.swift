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
public class YFWebSocketManager {
    
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
        subscriptions.removeAll()
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
    
    /// 지정된 URL로 WebSocket 연결 시도
    ///
    /// - Parameter url: 연결할 WebSocket URL
    /// - Throws: `YFError.webSocketError` WebSocket 연결 관련 오류
    private func connectToURL(_ url: URL) async throws {
        connectionState = .connecting
        
        do {
            webSocketTask = urlSession.webSocketTask(with: url)
            webSocketTask?.resume()
            connectionState = .connected
        } catch {
            connectionState = .disconnected
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
    #endif
}