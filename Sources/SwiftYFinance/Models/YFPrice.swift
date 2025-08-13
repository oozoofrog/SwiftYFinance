import Foundation

/// 개별 거래일의 가격 정보 (OHLCV)
///
/// 주식의 일간 또는 분간 거래 데이터를 나타냅니다.
/// Open, High, Low, Close, Volume과 수정종가를 포함합니다.
///
/// ## OHLCV 데이터
/// - **Open**: 시가 (해당 기간 첫 거래가)
/// - **High**: 고가 (해당 기간 최고 거래가)
/// - **Low**: 저가 (해당 기간 최저 거래가)  
/// - **Close**: 종가 (해당 기간 마지막 거래가)
/// - **Volume**: 거래량 (해당 기간 총 거래주식수)
/// - **Adjusted Close**: 수정종가 (배당, 분할 조정)
///
/// ## 사용 예시
/// ```swift
/// let client = YFClient()
/// let history = try await client.fetchPriceHistory(
///     symbol: "AAPL", 
///     period: .oneMonth
/// )
///
/// for price in history.prices {
///     let change = ((price.close - price.open) / price.open) * 100
///     print("날짜: \(price.date.formatted(.dateTime.day().month().year()))")
///     print("종가: $\(price.close), 변화율: \(change.formatted(.number.precision(.fractionLength(2))))%")
/// }
/// ```
///
/// ## 수정종가 활용
/// ```swift
/// // 배당 및 분할 조정된 수익률 계산
/// let totalReturn = (currentPrice.adjClose - startPrice.adjClose) / startPrice.adjClose
/// ```
public struct YFPrice: Equatable, Comparable, Codable {
    
    /// 거래일 (또는 분 단위 타임스탬프)
    public let date: Date
    
    /// 시가 - 해당 기간 첫 거래가 (USD)
    public let open: Double
    
    /// 고가 - 해당 기간 최고 거래가 (USD)
    public let high: Double
    
    /// 저가 - 해당 기간 최저 거래가 (USD)
    public let low: Double
    
    /// 종가 - 해당 기간 마지막 거래가 (USD)
    public let close: Double
    
    /// 수정종가 - 배당 및 분할 조정 종가 (USD)
    ///
    /// 주식분할, 배당금 지급 등을 고려하여 조정된 가격
    /// 장기 수익률 계산시 이 값을 사용해야 정확합니다.
    public let adjClose: Double
    
    /// 거래량 - 해당 기간 총 거래 주식 수
    public let volume: Int
    
    /// YFPrice 초기화
    ///
    /// OHLCV 데이터로 가격 정보를 생성합니다.
    ///
    /// - Parameters:
    ///   - date: 거래일 또는 분 단위 타임스탬프
    ///   - open: 시가 (USD)
    ///   - high: 고가 (USD)
    ///   - low: 저가 (USD)
    ///   - close: 종가 (USD)
    ///   - adjClose: 수정종가 (USD)
    ///   - volume: 거래량
    public init(
        date: Date,
        open: Double,
        high: Double,
        low: Double,
        close: Double,
        adjClose: Double,
        volume: Int
    ) {
        self.date = date
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.adjClose = adjClose
        self.volume = volume
    }
    
    /// 날짜 기준 비교 연산자
    ///
    /// YFPrice 객체들을 날짜 순서로 정렬할 때 사용됩니다.
    ///
    /// - Parameters:
    ///   - lhs: 좌측 YFPrice 객체
    ///   - rhs: 우측 YFPrice 객체
    /// - Returns: lhs의 날짜가 rhs보다 이르면 true
    public static func < (lhs: YFPrice, rhs: YFPrice) -> Bool {
        lhs.date < rhs.date
    }
}