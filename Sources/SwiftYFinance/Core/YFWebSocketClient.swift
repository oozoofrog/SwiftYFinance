import Foundation

/// Yahoo Finance WebSocket 클라이언트
/// 
/// URLSessionWebSocketTask를 사용하여 Yahoo Finance의 실시간 데이터 스트리밍을 제공합니다.
/// yfinance Python 라이브러리의 WebSocket 클라이언트와 호환되는 기능을 제공합니다.
///
/// ## 사용 예시
/// ```swift
/// let client = YFWebSocketClient()
/// 
/// // 메시지 핸들러 설정
/// client.onMessage = { message in
///     print("Received: \(message.symbol ?? "Unknown") - \(message.price ?? 0)")
/// }
/// 
/// // 연결 및 구독
/// try await client.connect()
/// try await client.subscribe(["AAPL", "BTC-USD"])
/// ```
public final class YFWebSocketClient: NSObject, @unchecked Sendable {
    
    // MARK: - Configuration
    
    /// WebSocket URL (Yahoo Finance 스트리밍 서버)
    public static let defaultURL = URL(string: "wss://streamer.finance.yahoo.com/?version=2")!
    
    /// 하트비트 구독 간격 (초)
    public static let heartbeatInterval: TimeInterval = 15.0
    
    // MARK: - Properties
    
    private let url: URL
    private let verbose: Bool
    private let urlSession: URLSession
    
    /// 현재 연결 상태
    @Published public private(set) var state: YFWebSocketState = .disconnected
    
    /// 현재 구독 정보
    @Published public private(set) var subscription: YFSubscription = YFSubscription(symbols: [])
    
    /// 메시지 핸들러
    public var onMessage: YFLiveStreamHandler?
    
    /// 상태 변경 핸들러
    public var onStateChange: YFWebSocketStateHandler?
    
    // MARK: - Private Properties
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var heartbeatTask: Task<Void, Never>?
    private let messageDecoder = YFLiveMessageDecoder()
    
    // MARK: - AsyncStream Support
    
    private var messageContinuation: AsyncStream<YFLiveStreamMessage>.Continuation?
    private var stateContinuation: AsyncStream<YFWebSocketState>.Continuation?
    
    /// 실시간 메시지 스트림
    /// 
    /// WebSocket에서 수신되는 모든 메시지를 AsyncStream으로 제공합니다.
    ///
    /// ## 사용 예시
    /// ```swift
    /// let client = YFWebSocketClient()
    /// try await client.connect()
    /// try await client.subscribe(["AAPL", "BTC-USD"])
    /// 
    /// for await message in client.messageStream {
    ///     print("Received: \(message.symbol ?? "Unknown") - \(message.price ?? 0)")
    /// }
    /// ```
    public lazy var messageStream: AsyncStream<YFLiveStreamMessage> = {
        AsyncStream { continuation in
            self.messageContinuation = continuation
            
            continuation.onTermination = { @Sendable _ in
                // 스트림 종료시 정리 작업
            }
        }
    }()
    
    /// 연결 상태 스트림
    /// 
    /// WebSocket 연결 상태 변경을 AsyncStream으로 제공합니다.
    ///
    /// ## 사용 예시
    /// ```swift
    /// let client = YFWebSocketClient()
    /// 
    /// Task {
    ///     for await state in client.stateStream {
    ///         switch state {
    ///         case .connected:
    ///             print("WebSocket 연결됨")
    ///         case .disconnected:
    ///             print("WebSocket 연결 해제됨")
    ///         case .error(let message):
    ///             print("WebSocket 에러: \(message)")
    ///         default:
    ///             break
    ///         }
    ///     }
    /// }
    /// 
    /// try await client.connect()
    /// ```
    public lazy var stateStream: AsyncStream<YFWebSocketState> = {
        AsyncStream { continuation in
            self.stateContinuation = continuation
            
            // 현재 상태를 즉시 전송
            continuation.yield(self.state)
            
            continuation.onTermination = { @Sendable _ in
                // 스트림 종료시 정리 작업
            }
        }
    }()
    
    // MARK: - Initialization
    
    /// WebSocket 클라이언트 초기화
    /// - Parameters:
    ///   - url: WebSocket 서버 URL (기본값: Yahoo Finance 스트리밍 서버)
    ///   - verbose: 디버그 로그 출력 여부
    ///   - urlSession: URLSession 인스턴스 (기본값: .shared)
    public init(
        url: URL = defaultURL,
        verbose: Bool = false,
        urlSession: URLSession = .shared
    ) {
        self.url = url
        self.verbose = verbose
        self.urlSession = urlSession
        super.init()
    }
    
    // MARK: - Connection Management
    
    /// WebSocket 연결
    /// - Throws: 연결 실패 시 에러
    @MainActor
    public func connect() async throws {
        guard state != .connected else { return }
        
        setState(.connecting)
        
        if verbose {
            print("[YFWebSocket] Connecting to \(url.absoluteString)")
        }
        
        // 기존 연결 정리
        await disconnect()
        
        // 새 WebSocket 태스크 생성
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        
        setState(.connected)
        
        // 메시지 수신 시작
        startListening()
        
        if verbose {
            print("[YFWebSocket] Connected successfully")
        }
    }
    
    /// WebSocket 연결 해제
    @MainActor
    public func disconnect() async {
        // 하트비트 태스크 취소
        heartbeatTask?.cancel()
        heartbeatTask = nil
        
        // WebSocket 태스크 취소
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        
        // AsyncStream 정리
        messageContinuation?.finish()
        stateContinuation?.finish()
        messageContinuation = nil
        stateContinuation = nil
        
        setState(.disconnected)
        
        if verbose {
            print("[YFWebSocket] Disconnected")
        }
    }
    
    // MARK: - Subscription Management
    
    /// 심볼 구독
    /// - Parameter symbols: 구독할 심볼 배열
    /// - Throws: 구독 실패 시 에러
    public func subscribe(_ symbols: [String]) async throws {
        guard let webSocketTask = webSocketTask else {
            throw YFError.webSocketError(.notConnected("WebSocket not connected"))
        }
        
        let message = ["subscribe": symbols]
        let jsonData = try JSONSerialization.data(withJSONObject: message)
        
        try await webSocketTask.send(.data(jsonData))
        
        // 구독 상태 업데이트
        subscription = subscription.adding(symbols)
        
        // 하트비트 시작 (아직 시작되지 않았다면)
        if heartbeatTask == nil {
            startHeartbeat()
        }
        
        if verbose {
            print("[YFWebSocket] Subscribed to: \(symbols.joined(separator: ", "))")
        }
    }
    
    /// 심볼 구독 해제
    /// - Parameter symbols: 구독 해제할 심볼 배열
    /// - Throws: 구독 해제 실패 시 에러
    public func unsubscribe(_ symbols: [String]) async throws {
        guard let webSocketTask = webSocketTask else {
            throw YFError.webSocketError(.notConnected("WebSocket not connected"))
        }
        
        let message = ["unsubscribe": symbols]
        let jsonData = try JSONSerialization.data(withJSONObject: message)
        
        try await webSocketTask.send(.data(jsonData))
        
        // 구독 상태 업데이트
        subscription = subscription.removing(symbols)
        
        if verbose {
            print("[YFWebSocket] Unsubscribed from: \(symbols.joined(separator: ", "))")
        }
    }
    
    // MARK: - Private Methods
    
    /// 상태 변경
    private func setState(_ newState: YFWebSocketState) {
        state = newState
        onStateChange?(newState)
        stateContinuation?.yield(newState)
    }
    
    /// 메시지 수신 시작
    private func startListening() {
        guard let webSocketTask = webSocketTask else { return }
        
        Task {
            do {
                while !Task.isCancelled {
                    let message = try await webSocketTask.receive()
                    await handleMessage(message)
                }
            } catch {
                await handleError(error)
            }
        }
    }
    
    /// 하트비트 시작
    private func startHeartbeat() {
        heartbeatTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Self.heartbeatInterval))
                
                guard !Task.isCancelled, !subscription.symbols.isEmpty else { continue }
                
                do {
                    try await subscribe(Array(subscription.symbols))
                    
                    if verbose {
                        print("[YFWebSocket] Heartbeat sent for symbols: \(subscription.symbols.joined(separator: ", "))")
                    }
                } catch {
                    if verbose {
                        print("[YFWebSocket] Heartbeat failed: \(error)")
                    }
                }
            }
        }
    }
    
    /// 메시지 처리
    @MainActor
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) async {
        do {
            let data: Data
            
            switch message {
            case .data(let messageData):
                data = messageData
            case .string(let messageString):
                guard let stringData = messageString.data(using: .utf8) else {
                    throw YFError.webSocketError(.messageDecodingFailed("Failed to convert string message to data"))
                }
                data = stringData
            @unknown default:
                throw YFError.webSocketError(.messageDecodingFailed("Unknown message type"))
            }
            
            // JSON 파싱
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let encodedMessage = json["message"] as? String else {
                throw YFError.webSocketError(.messageDecodingFailed("Invalid message format"))
            }
            
            // 메시지 디코딩
            let decodedMessage = messageDecoder.decode(encodedMessage)
            
            // 핸들러 호출 및 AsyncStream 전송
            onMessage?(decodedMessage)
            messageContinuation?.yield(decodedMessage)
            
        } catch {
            let errorMessage = YFLiveStreamMessage(
                error: "Message processing failed: \(error.localizedDescription)"
            )
            onMessage?(errorMessage)
            messageContinuation?.yield(errorMessage)
            
            if verbose {
                print("[YFWebSocket] Message processing error: \(error)")
            }
        }
    }
    
    /// 에러 처리
    @MainActor
    private func handleError(_ error: Error) async {
        setState(.error(error.localizedDescription))
        
        if verbose {
            print("[YFWebSocket] Error: \(error)")
        }
        
        // 재연결 시도
        try? await Task.sleep(for: .seconds(3))
        
        do {
            try await connect()
            
            // 기존 구독 복원
            if !subscription.symbols.isEmpty {
                try await subscribe(Array(subscription.symbols))
            }
        } catch {
            if verbose {
                print("[YFWebSocket] Reconnection failed: \(error)")
            }
        }
    }
}

// MARK: - Message Decoder

/// 라이브 스트림 메시지 디코더
/// 
/// Yahoo Finance의 Base64로 인코딩된 Protocol Buffers 메시지를 디코딩합니다.
/// Protocol Buffers의 기본적인 파싱을 구현하여 실시간 가격 데이터를 추출합니다.
private final class YFLiveMessageDecoder: Sendable {
    
    /// Base64로 인코딩된 메시지 디코딩
    /// - Parameter base64Message: Base64 인코딩된 메시지
    /// - Returns: 파싱된 라이브 스트림 메시지
    func decode(_ base64Message: String) -> YFLiveStreamMessage {
        // Base64 디코딩
        guard let decodedData = Data(base64Encoded: base64Message) else {
            return YFLiveStreamMessage(raw: ["base64_data": base64Message], error: "Failed to decode base64 message")
        }
        
        // Protocol Buffers 간단한 파싱 시도
        let parsedData = parseProtobufData(decodedData)
        
        return YFLiveStreamMessage(
            symbol: parsedData["symbol"] as? String,
            price: parsedData["price"] as? Double,
            change: parsedData["change"] as? Double,
            changePercent: parsedData["changePercent"] as? Double,
            volume: parsedData["volume"] as? Int64,
            marketState: parsedData["marketState"] as? String,
            lastTradeTime: parsedData["lastTradeTime"] as? Int64,
            dayHigh: parsedData["dayHigh"] as? Double,
            dayLow: parsedData["dayLow"] as? Double,
            raw: parsedData,
            error: nil
        )
    }
    
    /// Protocol Buffers 데이터의 기본적인 파싱
    /// - Parameter data: Protocol Buffers 바이너리 데이터
    /// - Returns: 파싱된 필드 딕셔너리
    private func parseProtobufData(_ data: Data) -> [String: Sendable] {
        var result: [String: Sendable] = [:]
        var offset = 0
        
        // Protocol Buffers 와이어 포맷의 기본적인 파싱
        // 완전한 구현이 아닌, Yahoo Finance의 PricingData 구조에 맞춘 간단한 파싱
        while offset < data.count {
            guard let (tag, wireType, newOffset) = readTag(from: data, at: offset) else {
                break
            }
            
            offset = newOffset
            
            switch wireType {
            case 0: // Varint
                if let (value, nextOffset) = readVarint(from: data, at: offset) {
                    assignValue(value, forTag: tag, to: &result)
                    offset = nextOffset
                }
            case 1: // 64-bit
                if offset + 8 <= data.count {
                    let value = data.subdata(in: offset..<offset+8).withUnsafeBytes { $0.load(as: Double.self) }
                    assignDoubleValue(value, forTag: tag, to: &result)
                    offset += 8
                }
            case 2: // Length-delimited (strings, bytes)
                if let (length, nextOffset) = readVarint(from: data, at: offset),
                   nextOffset + Int(length) <= data.count {
                    let stringData = data.subdata(in: nextOffset..<nextOffset+Int(length))
                    if let string = String(data: stringData, encoding: .utf8) {
                        assignStringValue(string, forTag: tag, to: &result)
                    }
                    offset = nextOffset + Int(length)
                }
            case 5: // 32-bit
                if offset + 4 <= data.count {
                    let value = data.subdata(in: offset..<offset+4).withUnsafeBytes { $0.load(as: Float.self) }
                    assignDoubleValue(Double(value), forTag: tag, to: &result)
                    offset += 4
                }
            default:
                // 알려지지 않은 타입, 스킵
                break
            }
        }
        
        return result
    }
    
    /// Protocol Buffers 태그 읽기
    private func readTag(from data: Data, at offset: Int) -> (tag: Int, wireType: Int, newOffset: Int)? {
        guard let (value, newOffset) = readVarint(from: data, at: offset) else { return nil }
        let tag = Int(value >> 3)
        let wireType = Int(value & 0x7)
        return (tag, wireType, newOffset)
    }
    
    /// Protocol Buffers Varint 읽기
    private func readVarint(from data: Data, at offset: Int) -> (value: UInt64, newOffset: Int)? {
        var result: UInt64 = 0
        var shift: UInt64 = 0
        var currentOffset = offset
        
        while currentOffset < data.count {
            let byte = data[currentOffset]
            result |= UInt64(byte & 0x7F) << shift
            currentOffset += 1
            
            if byte & 0x80 == 0 {
                return (result, currentOffset)
            }
            
            shift += 7
            if shift >= 64 {
                return nil // 너무 큰 varint
            }
        }
        
        return nil
    }
    
    /// 태그에 따른 값 할당 (정수)
    private func assignValue(_ value: UInt64, forTag tag: Int, to result: inout [String: Sendable]) {
        switch tag {
        case 1: result["symbol"] = String(value) // 임시 구현
        case 2: result["lastTradeTime"] = Int64(value)
        case 3: result["volume"] = Int64(value)
        case 4: result["marketState"] = String(value) // 임시 구현
        default: break
        }
    }
    
    /// 태그에 따른 값 할당 (실수)
    private func assignDoubleValue(_ value: Double, forTag tag: Int, to result: inout [String: Sendable]) {
        switch tag {
        case 5: result["price"] = value
        case 6: result["change"] = value
        case 7: result["changePercent"] = value
        case 8: result["dayHigh"] = value
        case 9: result["dayLow"] = value
        default: break
        }
    }
    
    /// 태그에 따른 값 할당 (문자열)
    private func assignStringValue(_ value: String, forTag tag: Int, to result: inout [String: Sendable]) {
        switch tag {
        case 1: result["symbol"] = value
        case 4: result["marketState"] = value
        default: break
        }
    }
}