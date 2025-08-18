import Foundation

/// Yahoo Finance API 호스트 상수
///
/// yfinance Python 라이브러리와 동일한 호스트 구성을 제공합니다.
/// 단순하고 직접적인 호스트 참조로 검색성과 유지보수성을 보장합니다.
public struct YFHosts {
    /// Query1 호스트 - earnings, market summary, lookup, screener 등 특수 기능 API
    public static let query1 = URL(string: "https://query1.finance.yahoo.com")!
    
    /// Query2 호스트 - quoteSummary, chart, search 등 주요 데이터 API  
    public static let query2 = URL(string: "https://query2.finance.yahoo.com")!
    
    /// Finance 루트 호스트 - 웹 기반 API 및 인증
    public static let finance = URL(string: "https://finance.yahoo.com")!
    
    /// 기본 호스트 (대부분의 API가 사용)
    public static let `default` = query2
}

/// 자주 사용되는 API 엔드포인트 경로 상수
public struct YFPaths {
    /// Quote Summary API 경로
    public static let quoteSummary = "/v10/finance/quoteSummary"
    /// Chart API 경로  
    public static let chart = "/v8/finance/chart"
    /// Search API 경로
    public static let search = "/v1/finance/search"
    /// Earnings API 경로
    public static let earnings = "/v1/finance/visualization"
    /// Market Summary API 경로
    public static let marketSummary = "/v6/finance/quote/marketSummary"
    /// Screener API 경로
    public static let screener = "/v1/finance/screener"
    /// Lookup API 경로
    public static let lookup = "/v1/finance/lookup"
}