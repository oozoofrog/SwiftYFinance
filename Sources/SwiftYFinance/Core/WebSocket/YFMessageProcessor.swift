import Foundation

/// WebSocket 메시지 처리 전용 Actor
///
/// WebSocket으로부터 수신된 메시지의 파싱, 디코딩, 전송을 담당합니다.
/// Single Responsibility Principle에 따라 메시지 처리 관련 기능만 제공합니다.
internal actor YFMessageProcessor {
    
    // MARK: - Properties
    
    /// 메시지 디코더
    private let messageDecoder: YFWebSocketMessageDecoder
    
    /// 상태 관리 Actor (외부 주입)
    private let stateManager: YFWebSocketInternalState
    
    /// 메시지 스트림 컨티뉴에이션
    internal var messageContinuation: AsyncStream<YFWebSocketMessage>.Continuation?
    
    // MARK: - Initialization
    
    /// 메시지 처리기 초기화
    ///
    /// - Parameters:
    ///   - messageDecoder: Protobuf 메시지 디코더
    ///   - stateManager: 상태 관리를 담당하는 Actor
    internal init(messageDecoder: YFWebSocketMessageDecoder, stateManager: YFWebSocketInternalState) {
        self.messageDecoder = messageDecoder
        self.stateManager = stateManager
    }
    
    // MARK: - Message Sending
    
    /// WebSocket으로 메시지 전송
    ///
    /// - Parameters:
    ///   - message: 전송할 JSON 메시지 문자열
    ///   - webSocketTask: 메시지를 전송할 WebSocket task
    /// - Throws: `YFError.webSocketError` 메시지 전송 실패 시
    internal func sendMessage(_ message: String, using webSocketTask: URLSessionWebSocketTask?) async throws {
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
    
    // MARK: - Message Reception
    
    /// WebSocket 메시지 처리
    ///
    /// 수신된 WebSocket 메시지를 파싱하고 Protobuf 디코딩하여 스트림으로 전달합니다.
    ///
    /// - Parameter message: URLSessionWebSocketTask.Message
    internal func handleWebSocketMessage(_ message: URLSessionWebSocketTask.Message) async {
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
            await recordMessageReceived()
            
            // AsyncStream으로 메시지 전달
            messageContinuation?.yield(webSocketMessage)
            
        } catch {
            // 디코딩 오류는 로그로만 처리 (스트림 중단하지 않음)
            let yfError = YFError.webSocketError(.messageDecodingFailed("Failed to decode message: \(error.localizedDescription)"))
            await logError(yfError, context: "Message decoding")
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
    
    // MARK: - Stream Management
    
    /// 메시지 continuation 설정
    ///
    /// - Parameter continuation: AsyncStream의 continuation
    internal func setMessageContinuation(_ continuation: AsyncStream<YFWebSocketMessage>.Continuation?) {
        messageContinuation = continuation
    }
    
    /// 메시지 continuation 정리
    internal func clearMessageContinuation() {
        messageContinuation?.finish()
        messageContinuation = nil
    }
    
    /// 메시지 continuation 존재 확인 (테스트용)
    ///
    /// - Returns: 메시지 continuation이 존재하는지 여부
    internal func hasMessageContinuation() -> Bool {
        return messageContinuation != nil
    }
    
    // MARK: - Private Helpers
    
    /// 메시지 수신 기록
    private func recordMessageReceived() async {
        await stateManager.recordMessageReceived()
    }
    
    /// 에러 로깅
    ///
    /// - Parameters:
    ///   - error: 로깅할 에러
    ///   - context: 에러 발생 컨텍스트
    private func logError(_ error: Error, context: String) async {
        let currentState = await stateManager.getConnectionState()
        let failures = await stateManager.getConsecutiveFailures()
        await stateManager.addErrorLog(error, context: context, connectionState: currentState, consecutiveFailures: failures)
    }
}