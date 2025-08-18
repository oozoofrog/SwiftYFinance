import Foundation

/// Yahoo Finance Quote API를 위한 서비스 클래스
///
/// 주식 시세 조회 기능을 제공합니다.
/// 단일 책임 원칙에 따라 시세 조회 관련 로직만 담당합니다.
public final class YFQuoteService: YFBaseService {
    
    /// 주식 시세 조회
    ///
    /// - Parameter ticker: 조회할 주식 심볼  
    /// - Returns: 주식 시세 데이터
    /// - Throws: API 호출 중 발생하는 에러
    public func fetch(ticker: YFTicker) async throws -> YFQuote {
        try validateClientReference()
        
        // CSRF 인증 시도 (실패해도 기본 요청으로 진행)
        guard let client = client else {
            throw YFError.apiError("YFClient reference is nil")
        }
        
        let isAuthenticated = await client.session.isCSRFAuthenticated
        if !isAuthenticated {
            do {
                try await client.session.authenticateCSRF()
            } catch {
                // CSRF 인증 실패시 기본 요청으로 진행
            }
        }
        
        // 요청 URL 구성 및 인증된 요청 수행
        let requestURL = try await buildQuoteSummaryURL(ticker: ticker)
        let (data, _) = try await authenticatedURLRequest(url: requestURL)
        
        // JSON 파싱 (디버깅 로그 추가)
        print("📋 [DEBUG] Quote API 응답 데이터 크기: \(data.count) bytes")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📋 [DEBUG] Quote API 응답 내용 (처음 500자): \(responseString.prefix(500))")
        } else {
            print("❌ [DEBUG] Quote API 응답을 UTF-8로 디코딩 실패")
        }
        
        let quoteSummaryResponse = try parseJSON(data: data, type: QuoteSummaryResponse.self)
        
        // 에러 응답 처리
        if let error = quoteSummaryResponse.quoteSummary.error {
            throw YFError.apiError(error.description)
        }
        
        // 결과 데이터 처리
        guard let results = quoteSummaryResponse.quoteSummary.result,
              let result = results.first,
              let priceData = result.price else {
            throw YFError.apiError("No quote data available")
        }
        
        // YFQuote 객체 생성
        let quote = YFQuote(
            ticker: ticker,
            regularMarketPrice: priceData.regularMarketPrice ?? 0.0,
            regularMarketVolume: priceData.regularMarketVolume ?? 0,
            marketCap: priceData.marketCap ?? 0.0,
            shortName: priceData.shortName ?? ticker.symbol,
            regularMarketTime: Date(timeIntervalSince1970: TimeInterval(priceData.regularMarketTime ?? 0)),
            regularMarketOpen: priceData.regularMarketOpen ?? 0.0,
            regularMarketHigh: priceData.regularMarketDayHigh ?? 0.0,
            regularMarketLow: priceData.regularMarketDayLow ?? 0.0,
            regularMarketPreviousClose: priceData.regularMarketPreviousClose ?? 0.0,
            isRealtime: false,
            postMarketPrice: priceData.postMarketPrice,
            postMarketTime: priceData.postMarketTime != nil ? Date(timeIntervalSince1970: TimeInterval(priceData.postMarketTime!)) : nil,
            postMarketChangePercent: priceData.postMarketChangePercent,
            preMarketPrice: priceData.preMarketPrice,
            preMarketTime: priceData.preMarketTime != nil ? Date(timeIntervalSince1970: TimeInterval(priceData.preMarketTime!)) : nil,
            preMarketChangePercent: priceData.preMarketChangePercent
        )
        
        return quote
    }
    
    
    // MARK: - Private Helper Methods
    private func buildQuoteSummaryURL(ticker: YFTicker) async throws -> URL {
        guard let client = client else {
            throw YFError.apiError("YFClient reference is nil")
        }
        // CSRF 인증 상태에 따라 base URL 선택
        let isAuthenticated = await client.session.isCSRFAuthenticated
        let baseURL = isAuthenticated ? 
            client.session.baseURL.absoluteString : 
            "https://query1.finance.yahoo.com"
        
        var components = URLComponents(string: "\(baseURL)/v10/finance/quoteSummary/\(ticker.symbol)")!
        components.queryItems = [
            URLQueryItem(name: "modules", value: "price,summaryDetail"),
            URLQueryItem(name: "corsDomain", value: "finance.yahoo.com"),
            URLQueryItem(name: "formatted", value: "false")
        ]
        
        guard let url = components.url else {
            throw YFError.invalidRequest
        }
        
        // CSRF 인증된 경우 crumb 추가
        return isAuthenticated ? await client.session.addCrumbIfNeeded(to: url) : url
    }
}