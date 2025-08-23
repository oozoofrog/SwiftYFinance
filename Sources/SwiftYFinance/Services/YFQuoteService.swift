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
    
    /// 주식 시세 조회 (인증 필요)
    ///
    /// Quote API는 Python yfinance 분석 결과 CSRF 인증이 필요한 것으로 확인되었습니다.
    /// 모든 요청이 crumb 파라미터와 함께 전송됩니다.
    ///
    /// - Parameter ticker: 조회할 주식 심볼  
    /// - Returns: 주식 시세 데이터
    /// - Throws: API 호출 중 발생하는 에러
    public func fetch(ticker: YFTicker) async throws -> YFQuote {
        DebugPrint("🚀 [QuoteService] fetch() 시작 - 심볼: \(ticker.symbol)")
        
        do {
            // URL 구성
            let requestURL = try await buildQuoteURL(ticker: ticker)
            
            // 인증이 필요한 API 호출 (공통 메서드 사용)
            let quoteResponse = try await performFetch(url: requestURL, type: YFQuoteResponse.self, serviceName: "Quote")
            
            // quoteResponse 구조에서 result 데이터 추출  
            guard let result = quoteResponse.quoteResponse?.result?.first else {
                throw YFError.invalidResponse
            }
            
            DebugPrint("✅ [QuoteService] fetch() 완료")
            return result
        } catch {
            DebugPrint("❌ [QuoteService] fetch() 실패: \(error)")
            throw error
        }
    }
    
    /// 주식 시세 원본 JSON 조회 (인증 필요)
    ///
    /// Yahoo Finance API에서 반환하는 원본 JSON 응답을 그대로 반환합니다.
    /// Swift 모델로 파싱하지 않고 원시 API 응답을 제공하여 클라이언트에서 직접 처리할 수 있습니다.
    ///
    /// - Parameter ticker: 조회할 주식 심볼
    /// - Returns: 원본 JSON 응답 데이터
    /// - Throws: API 호출 중 발생하는 에러
    public func fetchRawJSON(ticker: YFTicker) async throws -> Data {
        DebugPrint("🚀 [QuoteService] fetchRawJSON() 시작 - 심볼: \(ticker.symbol)")
        
        // URL 구성
        let requestURL = try await buildQuoteURL(ticker: ticker)
        
        // 인증이 필요한 Raw JSON 호출 (공통 메서드 사용)
        return try await performFetchRawJSON(url: requestURL, serviceName: "Quote")
    }
    
    /// Quote API 요청 URL을 구성합니다 (인증 필요)
    ///
    /// Python yfinance와 동일한 방식으로 formatted=false 파라미터를 사용합니다.
    /// crumb 파라미터는 YFServiceCore에서 자동으로 추가됩니다.
    ///
    /// - Parameter ticker: 조회할 주식 심볼
    /// - Returns: 구성된 API 요청 URL
    /// - Throws: URL 구성 중 발생하는 에러
    private func buildQuoteURL(ticker: YFTicker) async throws -> URL {
        return try await YFAPIURLBuilder.quote(session: client.session)
            .symbol(ticker.symbol)
            .parameter("formatted", "false")  // Python yfinance와 동일
            .build()  // 인증과 함께 빌드
    }
    
}