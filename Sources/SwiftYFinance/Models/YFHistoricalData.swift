import Foundation

/// 주식의 과거 가격 데이터 컬렉션
///
/// 특정 기간 동안의 OHLCV(Open, High, Low, Close, Volume) 데이터를 포함합니다.
/// Yahoo Finance API에서 조회한 과거 데이터의 완전한 집합을 나타냅니다.
///
/// ## 주요 특징
/// - **기간 범위**: 시작일과 종료일 검증
/// - **정렬된 데이터**: 가격 데이터가 날짜 순으로 정렬
/// - **빈 데이터 처리**: isEmpty로 데이터 존재 여부 확인
/// - **데이터 개수**: count로 총 거래일 수 확인
///
/// ## 사용 예시
/// ```swift
/// let client = YFClient()
/// let history = try await client.fetchPriceHistory(
///     symbol: "AAPL", 
///     period: .oneYear
/// )
///
/// if !history.isEmpty {
///     print("기간: \(history.startDate) ~ \(history.endDate)")
///     print("총 \(history.count)일간의 데이터")
///     
///     // 최신 가격
///     if let latest = history.prices.last {
///         print("최신 종가: $\(latest.close)")
///     }
///     
///     // 수익률 계산
///     if let first = history.prices.first, 
///        let last = history.prices.last {
///         let totalReturn = (last.adjClose - first.adjClose) / first.adjClose * 100
///         print("총 수익률: \(totalReturn.formatted(.number.precision(.fractionLength(2))))%")
///     }
/// }
/// ```
public struct YFHistoricalData: Codable {
    
    /// 주식 심볼 정보
    public let ticker: YFTicker
    
    /// 과거 가격 데이터 배열
    ///
    /// 날짜 순으로 정렬된 YFPrice 객체들의 컬렉션
    public let prices: [YFPrice]
    
    /// 데이터 조회 시작일
    ///
    /// 요청한 과거 데이터의 시작 날짜
    public let startDate: Date
    
    /// 데이터 조회 종료일
    ///
    /// 요청한 과거 데이터의 종료 날짜
    public let endDate: Date
    
    /// 데이터 존재 여부
    ///
    /// 가격 데이터가 비어있는지 확인합니다.
    /// - Returns: 가격 데이터가 없으면 true
    public var isEmpty: Bool {
        prices.isEmpty
    }
    
    /// 총 거래일 수
    ///
    /// 포함된 가격 데이터의 개수를 반환합니다.
    /// - Returns: 가격 데이터 배열의 크기
    public var count: Int {
        prices.count
    }
    
    /// YFHistoricalData 초기화
    ///
    /// 과거 가격 데이터 컬렉션을 생성합니다.
    /// 시작일과 종료일의 유효성을 검증합니다.
    ///
    /// - Parameters:
    ///   - ticker: 주식 심볼
    ///   - prices: 과거 가격 데이터 배열
    ///   - startDate: 데이터 조회 시작일
    ///   - endDate: 데이터 조회 종료일
    /// - Throws: ``YFError/invalidDateRange`` 시작일이 종료일보다 늦은 경우
    public init(
        ticker: YFTicker,
        prices: [YFPrice],
        startDate: Date,
        endDate: Date
    ) throws {
        guard startDate <= endDate else {
            throw YFError.invalidDateRange
        }
        
        self.ticker = ticker
        self.prices = prices
        self.startDate = startDate
        self.endDate = endDate
    }
}