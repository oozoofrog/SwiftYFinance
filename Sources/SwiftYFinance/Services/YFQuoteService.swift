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
    
    
    /// 공통 로직을 처리하는 핵심 구조체
    private let core: YFServiceCore
    
    /// YFQuoteService 초기화
    /// - Parameter client: YFClient 인스턴스
    public init(client: YFClient) {
        self.client = client
        self.core = YFServiceCore(client: client)
    }
    
    /// 주식 시세 조회
    ///
    /// - Parameter ticker: 조회할 주식 심볼  
    /// - Returns: 주식 시세 데이터
    /// - Throws: API 호출 중 발생하는 에러
    public func fetch(ticker: YFTicker) async throws -> YFQuote {
        DebugPrint("🚀 [QuoteService] fetch() 시작 - 심볼: \(ticker.symbol)")
        
        do {
            // 요청 URL 구성
            DebugPrint("🔧 [QuoteService] URL 구성 중...")
            let requestURL = try await buildQuoteURL(ticker: ticker)
            DebugPrint("✅ [QuoteService] URL 구성 완료: \(requestURL)")
            
            // 공통 fetch 메서드 사용
            DebugPrint("📡 [QuoteService] API 호출 시작...")
            let quoteResponse = try await performFetch(url: requestURL, type: YFQuoteResponse.self, serviceName: "Quote")
            DebugPrint("✅ [QuoteService] API 호출 성공")
            
            // 응답에서 price 데이터 추출
            guard let quote = quoteResponse.quoteSummary?.result?.first?.price else {
                throw YFError.invalidResponse
            }
            
            DebugPrint("✅ [QuoteService] fetch() 완료")
            return quote
        } catch {
            DebugPrint("❌ [QuoteService] fetch() 실패: \(error)")
            throw error
        }
    }
    
    /// 주식 시세 원본 JSON 조회
    ///
    /// Yahoo Finance API에서 반환하는 원본 JSON 응답을 그대로 반환합니다.
    /// Swift 모델로 파싱하지 않고 원시 API 응답을 제공하여 클라이언트에서 직접 처리할 수 있습니다.
    ///
    /// - Parameter ticker: 조회할 주식 심볼
    /// - Returns: 원본 JSON 응답 데이터
    /// - Throws: API 호출 중 발생하는 에러
    public func fetchRawJSON(ticker: YFTicker) async throws -> Data {
        // 요청 URL 구성
        let requestURL = try await buildQuoteURL(ticker: ticker)
        
        // 공통 fetchRawJSON 메서드 사용
        return try await performFetchRawJSON(url: requestURL, serviceName: "Quote")
    }
    
    /// Quote API 요청 URL을 구성합니다
    ///
    /// - Parameter ticker: 조회할 주식 심볼
    /// - Returns: 구성된 API 요청 URL
    /// - Throws: URL 구성 중 발생하는 에러
    private func buildQuoteURL(ticker: YFTicker) async throws -> URL {
        return try await YFAPIURLBuilder.quote(session: client.session)
            .symbol(ticker.symbol)
            .parameter("crumb", "")  // yfinance에서는 빈 crumb 사용
            .build()
    }
    
}