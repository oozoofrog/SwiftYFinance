import Foundation

/// Yahoo Finance WebSocket 메시지 데이터 모델
///
/// Yahoo Finance WebSocket에서 수신하는 실시간 주식 가격 데이터를 나타냅니다.
/// yfinance PricingData 프로토콜 버퍼 메시지에서 파싱된 필수 필드들을 포함합니다.
///
/// ## 주요 필드
/// - `symbol`: 종목 코드 (예: "AAPL", "BTC-USD")
/// - `price`: 현재 가격
/// - `timestamp`: 가격 업데이트 시간
/// - `currency`: 통화 코드 (예: "USD")
///
/// ## 사용 예시
/// ```swift
/// let message = YFWebSocketMessage(
///     symbol: "AAPL",
///     price: 150.0,
///     timestamp: Date(),
///     currency: "USD"
/// )
/// ```
///
/// - SeeAlso: `YFStreamingQuote` 실시간 스트리밍 쿼트 데이터
/// - SeeAlso: yfinance-reference/yfinance/pricing.proto
public struct YFWebSocketMessage: Codable, Equatable, Sendable {
    
    /// 종목 심볼/코드
    ///
    /// Yahoo Finance에서 사용하는 종목 식별자입니다.
    /// PricingData.id 필드에 해당합니다.
    ///
    /// ## 예시
    /// - 주식: "AAPL", "MSFT", "TSLA"
    /// - 암호화폐: "BTC-USD", "ETH-USD"
    /// - 지수: "^GSPC", "^IXIC"
    public let symbol: String
    
    /// 현재 가격
    ///
    /// 종목의 최신 거래 가격입니다.
    /// PricingData.price 필드에 해당합니다.
    public let price: Double
    
    /// 가격 업데이트 시간
    ///
    /// 해당 가격 정보가 업데이트된 시간입니다.
    /// PricingData.time 필드에 해당합니다.
    public let timestamp: Date
    
    /// 통화 코드
    ///
    /// 가격이 표시되는 통화입니다.
    /// PricingData.currency 필드에 해당합니다.
    ///
    /// ## 일반적인 값
    /// - "USD": 미국 달러
    /// - "EUR": 유로
    /// - "JPY": 일본 엔
    public let currency: String?
    
    /// YFWebSocketMessage 초기화
    ///
    /// - Parameters:
    ///   - symbol: 종목 심볼/코드
    ///   - price: 현재 가격
    ///   - timestamp: 가격 업데이트 시간
    ///   - currency: 통화 코드 (선택적)
    public init(
        symbol: String,
        price: Double,
        timestamp: Date,
        currency: String?
    ) {
        self.symbol = symbol
        self.price = price
        self.timestamp = timestamp
        self.currency = currency
    }
}