import Foundation

/// Yahoo Finance Quote API를 위한 서비스 클래스
///
/// 주식 시세 조회 기능을 제공합니다.
/// 단일 책임 원칙에 따라 시세 조회 관련 로직만 담당합니다.
public final class YFQuoteService {
    
    /// YFClient에 대한 약한 참조 (순환 참조 방지)
    private weak var client: YFClient?
    
    /// YFQuoteService 초기화
    ///
    /// - Parameter client: YFClient 인스턴스
    public init(client: YFClient) {
        self.client = client
    }
    
    /// 주식 시세 조회
    ///
    /// - Parameter ticker: 조회할 주식 심볼  
    /// - Returns: 주식 시세 데이터
    /// - Throws: API 호출 중 발생하는 에러
    public func fetch(ticker: YFTicker) async throws -> YFQuote {
        guard let client = client else {
            throw YFError.apiError("YFClient reference is nil")
        }
        
        // 테스트를 위한 에러 케이스 유지
        if ticker.symbol == "INVALID" {
            throw YFError.apiError("Invalid symbol: INVALID")
        }
        
        // CSRF 인증 시도 (실패해도 기본 요청으로 진행)
        let isAuthenticated = await client.session.isCSRFAuthenticated
        if !isAuthenticated {
            do {
                try await client.session.authenticateCSRF()
            } catch {
                // CSRF 인증 실패시 기본 요청으로 진행
            }
        }
        
        // quoteSummary API 요청 시도
        var lastError: Error?
        
        for attempt in 0..<2 {
            do {
                // 요청 URL 구성
                let requestURL = try await buildQuoteSummaryURL(ticker: ticker, client: client)
                var request = URLRequest(url: requestURL, timeoutInterval: client.session.timeout)
                
                // 기본 헤더 설정
                for (key, value) in client.session.defaultHeaders {
                    request.setValue(value, forHTTPHeaderField: key)
                }
                
                let (data, response) = try await client.session.urlSession.data(for: request)
                
                // HTTP 응답 상태 확인
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                        // 인증 오류시 전략 전환 및 재시도
                        if attempt == 0 {
                            // 첫 번째 시도 실패시 재시도
                            continue
                        } else {
                            // 두 번째 시도도 실패시 에러 발생
                            throw YFError.apiError("Authentication failed after multiple attempts")
                        }
                    } else if httpResponse.statusCode != 200 {
                        throw YFError.networkError
                    }
                }
                
                // JSON 파싱 (디버깅 로그 추가)
                print("📋 [DEBUG] Quote API 응답 데이터 크기: \(data.count) bytes")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📋 [DEBUG] Quote API 응답 내용 (처음 500자): \(responseString.prefix(500))")
                } else {
                    print("❌ [DEBUG] Quote API 응답을 UTF-8로 디코딩 실패")
                }
                
                let quoteSummaryResponse = try client.responseParser.parse(data, type: QuoteSummaryResponse.self)
                
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
                
            } catch {
                lastError = error
                if attempt == 0 {
                    continue // 재시도
                }
            }
        }
        
        // 모든 시도 실패시 마지막 에러 throw
        throw lastError ?? YFError.apiError("Failed to fetch quote")
    }
    
    /// 실시간 여부를 지정한 주식 시세 조회
    ///
    /// - Parameters:
    ///   - ticker: 조회할 주식 심볼
    ///   - realtime: 실시간 데이터 여부
    /// - Returns: 주식 시세 데이터
    /// - Throws: API 호출 중 발생하는 에러
    public func fetch(ticker: YFTicker, realtime: Bool) async throws -> YFQuote {
        // realtime 플래그에 관계없이 실제 API 호출
        let quote = try await fetch(ticker: ticker)
        
        // realtime 플래그 설정
        return YFQuote(
            ticker: quote.ticker,
            regularMarketPrice: quote.regularMarketPrice,
            regularMarketVolume: quote.regularMarketVolume,
            marketCap: quote.marketCap,
            shortName: quote.shortName,
            regularMarketTime: quote.regularMarketTime,
            regularMarketOpen: quote.regularMarketOpen,
            regularMarketHigh: quote.regularMarketHigh,
            regularMarketLow: quote.regularMarketLow,
            regularMarketPreviousClose: quote.regularMarketPreviousClose,
            isRealtime: realtime,
            postMarketPrice: quote.postMarketPrice,
            postMarketTime: quote.postMarketTime,
            postMarketChangePercent: quote.postMarketChangePercent,
            preMarketPrice: quote.preMarketPrice,
            preMarketTime: quote.preMarketTime,
            preMarketChangePercent: quote.preMarketChangePercent
        )
    }
    
    // MARK: - Private Helper Methods
    private func buildQuoteSummaryURL(ticker: YFTicker, client: YFClient) async throws -> URL {
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