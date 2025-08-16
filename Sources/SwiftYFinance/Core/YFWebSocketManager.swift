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
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }
    
    // MARK: - Private Methods
    
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
        
        try await connectToURL(url)
    }
    #endif
}