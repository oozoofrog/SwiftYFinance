import Foundation

/// Yahoo Finance API 엔드포인트 URL 상수
///
/// yfinance-reference 기반으로 실제 Yahoo Finance API의 완전한 URL을 정의합니다.
/// 각 API별 URL을 명확하게 정의하여 서비스 구현 시 일관성을 보장합니다.
/// 호스트와 경로가 통합되어 개발 시 혼란을 최소화합니다.
public struct YFPaths {
    
    // MARK: - Core APIs (query2.finance.yahoo.com)
    
    /// Quote Summary API URL - 종목별 상세 정보
    /// 사용 서비스: YFQuoteSummaryService (예정)
    public static let quoteSummary = "https://query2.finance.yahoo.com/v10/finance/quoteSummary"
    
    /// Chart API URL - 과거 가격 데이터
    /// 사용 서비스: YFChartService
    public static let chart = "https://query2.finance.yahoo.com/v8/finance/chart"
    
    /// Search API URL - 종목 검색
    /// 사용 서비스: YFSearchService
    public static let search = "https://query2.finance.yahoo.com/v1/finance/search"
    
    /// Options API URL - 옵션 체인
    /// 사용 서비스: YFOptionsService
    public static let options = "https://query2.finance.yahoo.com/v7/finance/options"
    
    // MARK: - Query1 APIs (query1.finance.yahoo.com)
    
    /// Quote API URL - 실시간 시세 (query1 전용)
    /// 사용 서비스: YFQuoteService
    public static let quote = "https://query1.finance.yahoo.com/v7/finance/quote"
    
    /// Screener API URL - 종목 스크리닝
    /// 사용 서비스: YFScreenerService
    public static let screener = "https://query1.finance.yahoo.com/v1/finance/screener"
    
    /// Market Summary API URL - 시장 요약
    /// 사용 서비스: YFQuoteService (marketSummary 메서드)
    public static let marketSummary = "https://query1.finance.yahoo.com/v6/finance/quote/marketSummary"
    
    /// Market Time API URL - 시장 시간 정보
    public static let marketTime = "https://query1.finance.yahoo.com/v6/finance/markettime"
    
    /// Earnings Visualization API URL - 실적 차트 시각화 데이터
    public static let earningsVisualization = "https://query1.finance.yahoo.com/v1/finance/visualization"
    
    /// Lookup API URL - 종목 조회
    /// 사용 서비스: YFSearchService (lookup 메서드)
    public static let lookup = "https://query1.finance.yahoo.com/v1/finance/lookup"
    
    // MARK: - Fundamentals Timeseries API (query1.finance.yahoo.com)
    
    /// Fundamentals Timeseries API URL - 재무제표 시계열 데이터
    /// 사용 서비스: YFFundamentalsTimeseriesService
    /// 주의: 이 API는 특별한 형식의 경로를 사용함
    public static let fundamentalsTimeseries = "https://query1.finance.yahoo.com/ws/fundamentals-timeseries/v1/finance/timeseries"
}