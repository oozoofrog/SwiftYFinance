import Foundation

/// 실시간 스트리밍 주식 쿼트 데이터
///
/// Yahoo Finance WebSocket에서 수신하는 실시간 주식 가격 및 거래 정보를 나타냅니다.
/// `YFWebSocketMessage`를 기반으로 하되, 스트리밍에 특화된 추가 정보를 포함합니다.
///
/// ## 주요 필드
/// - `symbol`: 종목 코드
/// - `price`: 현재 가격
/// - `timestamp`: 가격 업데이트 시간
/// - `change`: 변동 금액 (선택적)
/// - `changePercent`: 변동 비율 (선택적)
/// - `volume`: 거래량 (선택적)
///
/// ## 사용 예시
/// ```swift
/// let quote = YFStreamingQuote(
///     symbol: "AAPL",
///     price: 150.0,
///     timestamp: Date()
/// )
/// 
/// // WebSocket 메시지에서 변환
/// let quote = YFStreamingQuote(from: webSocketMessage)
/// 
/// // 실시간 업데이트
/// let updated = quote.updated(price: 152.5, timestamp: Date(), change: 2.5)
/// ```
///
/// - SeeAlso: `YFWebSocketMessage` WebSocket 원시 메시지 데이터
public struct YFStreamingQuote: Codable, Equatable, Sendable {
    
    /// 종목 심볼/코드
    ///
    /// Yahoo Finance에서 사용하는 종목 식별자입니다.
    public let symbol: String
    
    /// 현재 가격
    ///
    /// 종목의 최신 거래 가격입니다.
    public let price: Double
    
    /// 가격 업데이트 시간
    ///
    /// 해당 가격 정보가 업데이트된 시간입니다.
    public let timestamp: Date
    
    /// 변동 금액
    ///
    /// 이전 종가 대비 변동 금액입니다.
    /// 양수는 상승, 음수는 하락을 의미합니다.
    public let change: Double?
    
    /// 변동 비율 (%)
    ///
    /// 이전 종가 대비 변동 비율입니다.
    /// 백분율로 표시됩니다 (예: 1.5는 1.5% 상승)
    public let changePercent: Double?
    
    /// 거래량
    ///
    /// 해당 시점까지의 누적 거래량입니다.
    public let volume: Int?
    
    /// 기본 YFStreamingQuote 초기화
    ///
    /// - Parameters:
    ///   - symbol: 종목 심볼/코드
    ///   - price: 현재 가격
    ///   - timestamp: 가격 업데이트 시간
    ///   - change: 변동 금액 (선택적)
    ///   - changePercent: 변동 비율 (선택적)
    ///   - volume: 거래량 (선택적)
    public init(
        symbol: String,
        price: Double,
        timestamp: Date,
        change: Double? = nil,
        changePercent: Double? = nil,
        volume: Int? = nil
    ) {
        self.symbol = symbol
        self.price = price
        self.timestamp = timestamp
        self.change = change
        self.changePercent = changePercent
        self.volume = volume
    }
    
    /// YFWebSocketMessage에서 YFStreamingQuote 생성
    ///
    /// WebSocket에서 수신한 원시 메시지를 스트리밍 쿼트로 변환합니다.
    /// 변동 정보는 초기값으로 nil로 설정됩니다.
    ///
    /// - Parameter message: WebSocket 메시지
    public init(from message: YFWebSocketMessage) {
        self.symbol = message.symbol
        self.price = message.price
        self.timestamp = message.timestamp
        self.change = nil
        self.changePercent = nil
        self.volume = nil
    }
    
    /// 실시간 업데이트된 새로운 YFStreamingQuote 생성
    ///
    /// 기존 쿼트를 기반으로 새로운 가격 정보로 업데이트된 쿼트를 생성합니다.
    /// 심볼은 기존과 동일하게 유지됩니다.
    ///
    /// - Parameters:
    ///   - price: 새로운 가격
    ///   - timestamp: 새로운 업데이트 시간
    ///   - change: 새로운 변동 금액 (선택적)
    ///   - changePercent: 새로운 변동 비율 (선택적)
    ///   - volume: 새로운 거래량 (선택적)
    /// - Returns: 업데이트된 새로운 YFStreamingQuote
    public func updated(
        price: Double,
        timestamp: Date,
        change: Double? = nil,
        changePercent: Double? = nil,
        volume: Int? = nil
    ) -> YFStreamingQuote {
        return YFStreamingQuote(
            symbol: self.symbol,
            price: price,
            timestamp: timestamp,
            change: change,
            changePercent: changePercent,
            volume: volume
        )
    }
}