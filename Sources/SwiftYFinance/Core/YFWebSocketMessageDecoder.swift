import Foundation

/// Yahoo Finance WebSocket 메시지 디코더
///
/// Yahoo Finance WebSocket에서 수신하는 Base64 인코딩된 Protobuf 메시지를
/// Swift 객체로 변환하는 디코더입니다.
///
/// ## 기본 사용법
/// ```swift
/// let decoder = YFWebSocketMessageDecoder()
/// let data = try decoder.decodeBase64("SGVsbG8gV29ybGQ=")
/// let message = try decoder.decode("CgdCVEMtVVNE...")
/// ```
///
/// ## 지원하는 변환
/// - Base64 문자열 → Data
/// - Protobuf Data → YFWebSocketMessage (추후 구현)
///
/// - SeeAlso: `YFWebSocketMessage` WebSocket 메시지 데이터
/// - SeeAlso: yfinance-reference/yfinance/live.py _decode_message()
public class YFWebSocketMessageDecoder {
    
    /// YFWebSocketMessageDecoder 초기화
    ///
    /// 기본 설정으로 디코더를 생성합니다.
    public init() {
        // 기본 초기화
    }
    
    // MARK: - Base64 Decoding
    
    /// Base64 문자열을 Data로 디코딩
    ///
    /// Yahoo Finance WebSocket에서 수신하는 Base64 인코딩된 메시지를
    /// 원시 바이너리 데이터로 변환합니다.
    ///
    /// - Parameter base64String: Base64 인코딩된 문자열
    /// - Returns: 디코딩된 Data
    /// - Throws: `YFError.webSocketError(.messageDecodingFailed)` Base64 디코딩 실패 시
    ///
    /// ## 사용 예시
    /// ```swift
    /// let decoder = YFWebSocketMessageDecoder()
    /// let data = try decoder.decodeBase64("SGVsbG8gV29ybGQ=")
    /// // data contains "Hello World" as binary data
    /// ```
    public func decodeBase64(_ base64String: String) throws -> Data {
        // 빈 문자열 검증
        guard !base64String.isEmpty else {
            throw YFError.webSocketError(.messageDecodingFailed("Cannot decode empty Base64 string"))
        }
        
        // Base64 디코딩 시도
        guard let data = Data(base64Encoded: base64String) else {
            throw YFError.webSocketError(.messageDecodingFailed("Invalid Base64 string: \(base64String)"))
        }
        
        return data
    }
    
    // MARK: - WebSocket Message Decoding
    
    /// Base64 문자열을 YFWebSocketMessage로 디코딩
    ///
    /// Yahoo Finance WebSocket에서 수신하는 Base64 인코딩된 Protobuf 메시지를
    /// YFWebSocketMessage 객체로 변환합니다.
    ///
    /// - Parameter base64Message: Base64 인코딩된 Protobuf 메시지
    /// - Returns: 파싱된 YFWebSocketMessage
    /// - Throws: `YFError.webSocketError` 디코딩 또는 파싱 실패 시
    ///
    /// ## 사용 예시
    /// ```swift
    /// let decoder = YFWebSocketMessageDecoder()
    /// let message = try decoder.decode("CgdCVEMtVVNE...")
    /// print(message.symbol) // "BTC-USD"
    /// ```
    ///
    /// - Note: 현재는 기본 구현만 제공됩니다. Protobuf 파싱은 추후 구현 예정입니다.
    public func decode(_ base64Message: String) throws -> YFWebSocketMessage {
        // Base64 디코딩
        let data = try decodeBase64(base64Message)
        
        // TODO: Protobuf 파싱 구현 (Task 2.8에서 구현 예정)
        // 현재는 기본값으로 반환
        return YFWebSocketMessage(
            symbol: "UNKNOWN",
            price: 0.0,
            timestamp: Date(),
            currency: nil
        )
    }
}