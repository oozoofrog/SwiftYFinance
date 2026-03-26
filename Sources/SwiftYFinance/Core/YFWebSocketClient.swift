import Foundation

/// Yahoo Finance WebSocket 클라이언트
///
/// URLSessionWebSocketTask를 사용하여 Yahoo Finance의 실시간 데이터 스트리밍을 제공합니다.
/// yfinance Python 라이브러리의 WebSocket 클라이언트와 호환되는 기능을 제공합니다.
///
/// Swift 6.1 actor 기반으로 구현되어 Combine 의존 없이 순수 AsyncStream을 제공합니다.
///
/// ## 사용 예시
/// ```swift
/// let client = YFWebSocketClient()
///
/// // 연결 및 구독
/// let (messages, states) = await client.streams()
/// try await client.connect()
/// try await client.subscribe(["AAPL", "BTC-USD"])
///
/// for await message in messages {
///     print("Received: \(message.symbol ?? "Unknown") - \(message.price ?? 0)")
/// }
/// ```
public actor YFWebSocketClient {

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
    public private(set) var state: YFWebSocketState = .disconnected

    /// 현재 구독 정보
    public private(set) var subscription: YFSubscription = YFSubscription(symbols: [])

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
    /// `streams()` 메서드를 통해 메시지 스트림과 상태 스트림을 동시에 얻을 수 있습니다.
    public private(set) var messageStream: AsyncStream<YFLiveStreamMessage>

    /// 연결 상태 스트림
    ///
    /// WebSocket 연결 상태 변경을 AsyncStream으로 제공합니다.
    public private(set) var stateStream: AsyncStream<YFWebSocketState>

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

        // AsyncStream을 init에서 생성하여 lazy 없이 안전하게 초기화
        var messageCont: AsyncStream<YFLiveStreamMessage>.Continuation?
        let msgStream = AsyncStream<YFLiveStreamMessage> { continuation in
            messageCont = continuation
        }

        var stateCont: AsyncStream<YFWebSocketState>.Continuation?
        let stateStreamValue = AsyncStream<YFWebSocketState> { continuation in
            stateCont = continuation
            // 초기 상태 전송
            continuation.yield(.disconnected)
        }

        self.messageStream = msgStream
        self.stateStream = stateStreamValue
        self.messageContinuation = messageCont
        self.stateContinuation = stateCont
    }

    // MARK: - Stream API

    /// 메시지 스트림과 상태 스트림을 동시에 반환합니다
    ///
    /// - Returns: (메시지 스트림, 상태 스트림) 튜플
    public func streams() -> (AsyncStream<YFLiveStreamMessage>, AsyncStream<YFWebSocketState>) {
        return (messageStream, stateStream)
    }

    // MARK: - Connection Management

    /// WebSocket 연결
    /// - Throws: 연결 실패 시 에러
    public func connect() async throws {
        guard state != .connected else { return }

        setState(.connecting)

        if verbose {
            YFLogger.webSocket.info("WebSocket 연결 중: \(url.absoluteString)")
        }

        // 기존 연결 정리
        await disconnectInternal()

        // 새 WebSocket 태스크 생성
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()

        setState(.connected)

        // 메시지 수신 시작
        startListening()

        if verbose {
            YFLogger.webSocket.info("WebSocket 연결 완료")
        }
    }

    /// WebSocket 연결 해제
    public func disconnect() async {
        await disconnectInternal()
    }

    // MARK: - Subscription Management

    /// 심볼 구독
    /// - Parameter symbols: 구독할 심볼 배열
    /// - Throws: 구독 실패 시 에러
    public func subscribe(_ symbols: [String]) async throws {
        guard let webSocketTask else {
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
            YFLogger.webSocket.info("구독 완료: \(symbols.joined(separator: ", "))")
        }
    }

    /// 심볼 구독 해제
    /// - Parameter symbols: 구독 해제할 심볼 배열
    /// - Throws: 구독 해제 실패 시 에러
    public func unsubscribe(_ symbols: [String]) async throws {
        guard let webSocketTask else {
            throw YFError.webSocketError(.notConnected("WebSocket not connected"))
        }

        let message = ["unsubscribe": symbols]
        let jsonData = try JSONSerialization.data(withJSONObject: message)

        try await webSocketTask.send(.data(jsonData))

        // 구독 상태 업데이트
        subscription = subscription.removing(symbols)

        if verbose {
            YFLogger.webSocket.info("구독 해제: \(symbols.joined(separator: ", "))")
        }
    }

    // MARK: - Private Methods

    /// 상태 변경 (internal)
    private func setState(_ newState: YFWebSocketState) {
        state = newState
        stateContinuation?.yield(newState)
    }

    /// WebSocket 연결 해제 (internal)
    private func disconnectInternal() async {
        // 하트비트 태스크 취소
        heartbeatTask?.cancel()
        heartbeatTask = nil

        // WebSocket 태스크 취소
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil

        setState(.disconnected)

        if verbose {
            YFLogger.webSocket.info("WebSocket 연결 해제됨")
        }
    }

    /// 메시지 수신 시작
    private func startListening() {
        guard let webSocketTask else { return }

        Task { [weak webSocketTask] in
            guard let webSocketTask else { return }
            do {
                while !Task.isCancelled {
                    let message = try await webSocketTask.receive()
                    await self.handleMessage(message)
                }
            } catch {
                await self.handleError(error)
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
                } catch {
                    if verbose {
                        YFLogger.webSocket.error("하트비트 실패: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    /// 메시지 처리
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
            messageContinuation?.yield(decodedMessage)

        } catch {
            let errorMessage = YFLiveStreamMessage(
                error: "Message processing failed: \(error.localizedDescription)"
            )
            messageContinuation?.yield(errorMessage)

            if verbose {
                YFLogger.webSocket.error("메시지 처리 오류: \(error.localizedDescription)")
            }
        }
    }

    /// 에러 처리
    private func handleError(_ error: Error) async {
        setState(.error(error.localizedDescription))

        if verbose {
            YFLogger.webSocket.error("WebSocket 오류: \(error.localizedDescription)")
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
                YFLogger.webSocket.error("재연결 실패: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Message Decoder

/// 라이브 스트림 메시지 디코더
///
/// Yahoo Finance의 Base64로 인코딩된 Protocol Buffers 메시지를 디코딩합니다.
private final class YFLiveMessageDecoder: Sendable {

    /// Base64로 인코딩된 메시지 디코딩
    /// - Parameter base64Message: Base64 인코딩된 메시지
    /// - Returns: 파싱된 라이브 스트림 메시지
    func decode(_ base64Message: String) -> YFLiveStreamMessage {
        guard let decodedData = Data(base64Encoded: base64Message) else {
            return YFLiveStreamMessage(raw: ["base64_data": base64Message], error: "Failed to decode base64 message")
        }

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
    private func parseProtobufData(_ data: Data) -> [String: Sendable] {
        var result: [String: Sendable] = [:]
        var offset = 0

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
            case 2: // Length-delimited
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
                break
            }
        }

        return result
    }

    private func readTag(from data: Data, at offset: Int) -> (tag: Int, wireType: Int, newOffset: Int)? {
        guard let (value, newOffset) = readVarint(from: data, at: offset) else { return nil }
        return (Int(value >> 3), Int(value & 0x7), newOffset)
    }

    private func readVarint(from data: Data, at offset: Int) -> (value: UInt64, newOffset: Int)? {
        var result: UInt64 = 0
        var shift: UInt64 = 0
        var currentOffset = offset

        while currentOffset < data.count {
            let byte = data[currentOffset]
            result |= UInt64(byte & 0x7F) << shift
            currentOffset += 1

            if byte & 0x80 == 0 { return (result, currentOffset) }

            shift += 7
            if shift >= 64 { return nil }
        }

        return nil
    }

    private func assignValue(_ value: UInt64, forTag tag: Int, to result: inout [String: Sendable]) {
        switch tag {
        case 1: result["symbol"] = String(value)
        case 2: result["lastTradeTime"] = Int64(value)
        case 3: result["volume"] = Int64(value)
        case 4: result["marketState"] = String(value)
        default: break
        }
    }

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

    private func assignStringValue(_ value: String, forTag tag: Int, to result: inout [String: Sendable]) {
        switch tag {
        case 1: result["symbol"] = value
        case 4: result["marketState"] = value
        default: break
        }
    }
}
