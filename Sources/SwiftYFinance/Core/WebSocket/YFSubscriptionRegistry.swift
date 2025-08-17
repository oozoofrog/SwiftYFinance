import Foundation

/// WebSocket 구독 관리 전용 Actor
///
/// WebSocket 구독/구독취소 및 구독 상태 관리를 담당합니다.
/// Single Responsibility Principle에 따라 구독 관련 기능만 제공합니다.
internal actor YFSubscriptionRegistry {
    
    // MARK: - Properties
    
    /// 상태 관리 Actor (외부 주입)
    private let stateManager: YFWebSocketInternalState
    
    // MARK: - Initialization
    
    /// 구독 관리자 초기화
    ///
    /// - Parameter stateManager: 상태 관리를 담당하는 Actor
    internal init(stateManager: YFWebSocketInternalState) {
        self.stateManager = stateManager
    }
    
    // MARK: - Subscription Management
    
    /// 심볼 구독
    ///
    /// 지정된 심볼들의 실시간 데이터를 구독합니다.
    /// Yahoo Finance WebSocket 프로토콜에 따라 JSON 형식으로 구독 메시지를 전송합니다.
    ///
    /// - Parameters:
    ///   - symbols: 구독할 심볼 배열 (예: ["AAPL", "TSLA"])
    ///   - isUsableState: 현재 연결 상태가 사용 가능한지 확인하는 클로저
    ///   - sendMessage: 메시지 전송을 담당하는 클로저
    /// - Throws: `YFError.webSocketError` 연결 또는 구독 관련 오류
    internal func subscribe(to symbols: [String], 
                          isUsableState: @Sendable () async -> Bool,
                          sendMessage: @Sendable (String) async throws -> Void) async throws {
        guard await isUsableState() else {
            let currentState = await stateManager.getConnectionState()
            throw YFError.webSocketError(.notConnected("Must be connected to WebSocket before subscribing (current state: \(currentState))"))
        }
        
        guard !symbols.isEmpty else {
            throw YFError.webSocketError(.invalidSubscription("Cannot subscribe to empty symbol list"))
        }
        
        // 중복 제거 및 구독 목록 업데이트
        let uniqueSymbols = Set(symbols)
        await stateManager.addSubscriptions(uniqueSymbols)
        
        // JSON 구독 메시지 생성 및 전송
        let currentSubscriptions = await stateManager.getSubscriptions()
        let message = Self.createSubscriptionMessage(symbols: Array(currentSubscriptions))
        try await sendMessage(message)
    }
    
    /// 심볼 구독 취소
    ///
    /// 지정된 심볼들의 실시간 데이터 구독을 취소합니다.
    ///
    /// - Parameters:
    ///   - symbols: 구독 취소할 심볼 배열
    ///   - isUsableState: 현재 연결 상태가 사용 가능한지 확인하는 클로저
    ///   - sendMessage: 메시지 전송을 담당하는 클로저
    /// - Throws: `YFError.webSocketError` 연결 또는 구독 관련 오류
    internal func unsubscribe(from symbols: [String],
                             isUsableState: @Sendable () async -> Bool,
                             sendMessage: @Sendable (String) async throws -> Void) async throws {
        guard await isUsableState() else {
            let currentState = await stateManager.getConnectionState()
            throw YFError.webSocketError(.notConnected("Must be connected to WebSocket before unsubscribing (current state: \(currentState))"))
        }
        
        guard !symbols.isEmpty else {
            return // 빈 배열 무시
        }
        
        // 구독 목록에서 제거
        let symbolsToRemove = Set(symbols)
        await stateManager.removeSubscriptions(symbolsToRemove)
        
        // JSON 구독 취소 메시지 생성 및 전송
        let message = Self.createUnsubscriptionMessage(symbols: symbols)
        try await sendMessage(message)
    }
    
    // MARK: - Message Creation
    
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
    
    // MARK: - State Access
    
    /// 현재 구독 목록 조회
    ///
    /// - Returns: 현재 구독 중인 심볼들의 Set
    internal func getSubscriptions() async -> Set<String> {
        return await stateManager.getSubscriptions()
    }
    
    /// 구독 목록 초기화
    internal func clearSubscriptions() async {
        await stateManager.clearSubscriptions()
    }
}