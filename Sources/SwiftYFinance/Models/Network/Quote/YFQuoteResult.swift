import Foundation

// MARK: - Yahoo Finance Quote Result

/// 개별 종목의 price + summaryDetail 데이터 컨테이너
/// 
/// Yahoo Finance API가 제공하는 실시간 시세와 상세 분석 정보를 묶어 관리합니다.
public struct YFQuoteResult: Decodable, Sendable {
    
    /// 실시간 시세 및 거래 정보
    public let price: YFQuote?
    
    /// 종목 상세 분석 정보 (PE 비율, 배당률, 52주 최고/최저가 등)
    public let summaryDetail: YFQuoteSummaryDetail?
}