import Foundation

/// Yahoo Finance API URL 구성을 위한 통합 빌더 시스템
///
/// API 엔드포인트 정의와 URL 구성 로직을 완전히 통합한 도메인별 빌더입니다.
/// 각 API별 전용 빌더를 제공하여 타입 안전성과 사용성을 보장합니다.
///
/// ## 사용 예시
/// ```swift
/// // Quote API
/// let quoteURL = try await YFAPIURLBuilder.quote(session: session)
///     .symbol("AAPL")
///     .build()
///
/// // Chart API  
/// let chartURL = try await YFAPIURLBuilder.chart(session: session)
///     .symbol("MSFT")
///     .period(.oneYear)
///     .interval(.oneDay)
///     .build()
/// ```
public struct YFAPIURLBuilder: Sendable {
    
    // MARK: - Static Factory Methods
    
    /// Quote API 빌더 생성
    /// - Parameter session: YFSession 인스턴스
    /// - Returns: Quote API 전용 빌더
    public static func quote(session: YFSession) -> QuoteBuilder {
        return QuoteBuilder(session: session)
    }
    
    /// Chart API 빌더 생성
    /// - Parameter session: YFSession 인스턴스
    /// - Returns: Chart API 전용 빌더
    public static func chart(session: YFSession) -> ChartBuilder {
        return ChartBuilder(session: session)
    }
    
    /// Search API 빌더 생성
    /// - Parameter session: YFSession 인스턴스
    /// - Returns: Search API 전용 빌더
    public static func search(session: YFSession) -> SearchBuilder {
        return SearchBuilder(session: session)
    }
    
    /// Options API 빌더 생성
    /// - Parameter session: YFSession 인스턴스
    /// - Returns: Options API 전용 빌더
    public static func options(session: YFSession) -> OptionsBuilder {
        return OptionsBuilder(session: session)
    }
    
    /// Screener API 빌더 생성
    /// - Parameter session: YFSession 인스턴스
    /// - Returns: Screener API 전용 빌더
    public static func screener(session: YFSession) -> ScreenerBuilder {
        return ScreenerBuilder(session: session)
    }
    
    /// Fundamentals Timeseries API 빌더 생성
    /// - Parameter session: YFSession 인스턴스
    /// - Returns: Fundamentals API 전용 빌더
    public static func fundamentals(session: YFSession) -> FundamentalsBuilder {
        return FundamentalsBuilder(session: session)
    }
    
    /// News API 빌더 생성 (Search API 기반)
    /// - Parameter session: YFSession 인스턴스
    /// - Returns: News API 전용 빌더
    public static func news(session: YFSession) -> NewsBuilder {
        return NewsBuilder(session: session)
    }
}








// MARK: - Common URL Building Helper

extension YFAPIURLBuilder {
    
    /// 공통 URL 구성 헬퍼
    /// - Parameters:
    ///   - baseURL: 기본 URL
    ///   - parameters: 쿼리 파라미터
    ///   - session: YFSession 인스턴스
    /// - Returns: 구성된 URL
    /// - Throws: URL 구성 실패 시
    public static func buildURL(
        baseURL: String, 
        parameters: [String: String], 
        session: YFSession
    ) async throws -> URL {
        guard var urlComponents = URLComponents(string: baseURL) else {
            throw YFError.invalidURL
        }
        
        // 쿼리 파라미터 추가
        if !parameters.isEmpty {
            urlComponents.queryItems = parameters.map { key, value in
                URLQueryItem(name: key, value: value)
            }
        }
        
        guard let url = urlComponents.url else {
            throw YFError.invalidURL
        }
        
        // CSRF 인증된 경우 crumb 파라미터 추가
        let isAuthenticated = await session.isCSRFAuthenticated
        return isAuthenticated ? await session.addCrumbIfNeeded(to: url) : url
    }
}