import Foundation

/// Yahoo Finance Quote API를 위한 서비스 구조체
///
/// 주식 시세 조회 기능을 제공합니다.
/// 단일 책임 원칙에 따라 시세 조회 관련 로직만 담당합니다.
/// Sendable 프로토콜을 준수하여 concurrent 환경에서 안전하게 사용할 수 있습니다.
/// Protocol + Struct 설계로 @unchecked 없이도 완전한 thread safety를 보장합니다.
public struct YFQuoteService: YFService {
    
    /// YFClient 참조
    public let client: YFClient
    
    /// 디버깅 모드 활성화 여부
    public let debugEnabled: Bool
    
    /// 공통 로직을 처리하는 핵심 구조체
    private let core: YFServiceCore
    
    /// YFQuoteService 초기화
    /// - Parameters:
    ///   - client: YFClient 인스턴스
    ///   - debugEnabled: 디버깅 로그 활성화 여부 (기본값: false)
    public init(client: YFClient, debugEnabled: Bool = false) {
        self.client = client
        self.debugEnabled = debugEnabled
        self.core = YFServiceCore(client: client, debugEnabled: debugEnabled)
    }
    
    /// 주식 시세 조회
    ///
    /// - Parameter ticker: 조회할 주식 심볼  
    /// - Returns: 주식 시세 데이터
    /// - Throws: API 호출 중 발생하는 에러
    public func fetch(ticker: YFTicker) async throws -> YFQuote {
        // CSRF 인증 시도
        await ensureCSRFAuthentication()
        
        // 요청 URL 구성 및 인증된 요청 수행
        let requestURL = try await core.apiBuilder()
            .host(YFHosts.query2)
            .path(YFPaths.quoteSummary + "/\(ticker.symbol)")
            .parameter("modules", "price,summaryDetail")
            .parameter("corsDomain", "finance.yahoo.com")
            .parameter("formatted", "false")
            .build()
        let (data, _) = try await core.authenticatedURLRequest(url: requestURL)
        
        // API 응답 디버깅 로그
        logAPIResponse(data, serviceName: "Quote")
        
        let quoteSummaryResponse = try core.parseJSON(data: data, type: QuoteSummaryResponse.self)
        
        // 에러 응답 처리
        try handleYahooFinanceError(quoteSummaryResponse.quoteSummary.error?.description)
        
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
    
}