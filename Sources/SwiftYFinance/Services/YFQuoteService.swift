import Foundation

/// Yahoo Finance Quote API를 위한 서비스 구조체
///
/// 주식 시세 조회 기능을 제공합니다.
/// 단일 책임 원칙에 따라 시세 조회 관련 로직만 담당합니다.
/// Sendable 프로토콜을 준수하여 concurrent 환경에서 안전하게 사용할 수 있습니다.
/// Protocol + Struct 설계로 @unchecked 없이도 완전한 thread safety를 보장합니다.
/// nonisolated: 순수 데이터 서비스 — actor isolation 불필요, 라이브러리 소비자의 모든 컨텍스트에서 안전
public nonisolated struct YFQuoteService: YFService {
    
    /// YFClient 참조
    public let client: YFClient

    /// YFQuoteService 초기화
    /// - Parameter client: YFClient 인스턴스
    public init(client: YFClient) {
        self.client = client
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
        let requestURL = try await buildQuoteURL(tickers: [ticker])
        let quoteResponse = try await performFetch(url: requestURL, type: YFQuoteResponse.self, serviceName: "Quote")

        guard let result = quoteResponse.result?.first else {
            throw YFError.invalidResponse
        }
        return result
    }

    /// 여러 심볼의 실시간 주식 시세 조회
    ///
    /// Yahoo Finance에서 지정된 주식 심볼들의 현재 시장 데이터를 조회합니다.
    /// 이 메서드는 여러 심볼을 한 번의 API 호출로 일괄 처리할 수 있습니다.
    ///
    /// - Parameter symbols: 주식 티커 심볼 배열 (예: ["AAPL", "GOOGL", "MSFT"])
    /// - Returns: 요청한 모든 심볼의 시세 데이터를 담은 `YFQuoteResponse`
    /// - Throws: 요청 실패 또는 잘못된 심볼의 경우 `YFError` 발생
    ///
    /// - Note: 이 메서드는 CSRF 토큰을 통한 인증이 필요하며, Yahoo Finance API에
    ///         안정적으로 접근하기 위해 브라우저 위장 기능을 사용합니다.
    ///
    /// 사용 예시:
    /// ```swift
    /// let quotes = try await quoteService.fetch(symbols: ["AAPL", "TSLA"])
    /// for quote in quotes.quoteResponse.result {
    ///     print("\(quote.symbol): $\(quote.regularMarketPrice)")
    /// }
    /// ```
    public func fetch(symbols: [String]) async throws -> YFQuoteResponse {
        let requestURL = try await buildQuoteURL(tickers: symbols.map(YFTicker.init))
        return try await performFetch(url: requestURL, type: YFQuoteResponse.self, serviceName: "Quote")
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
        let requestURL = try await buildQuoteURL(tickers: [ticker])

        // 인증이 필요한 Raw JSON 호출 (공통 메서드 사용)
        return try await performFetchRawJSON(url: requestURL, serviceName: "Quote")
    }
    
    /// Quote API 요청 URL을 구성합니다 (인증 필요)
    ///
    /// Python yfinance와 동일한 방식으로 formatted=false 파라미터를 사용합니다.
    /// crumb 파라미터는 YFServiceCore에서 자동으로 추가됩니다.
    ///
    /// - Parameter tickers: 조회할 주식 심볼 리스트
    /// - Returns: 구성된 API 요청 URL
    /// - Throws: URL 구성 중 발생하는 에러
    private func buildQuoteURL(tickers: [YFTicker]) async throws -> URL {
        return try await YFAPIURLBuilder.quote(session: client.session)
            .symbols(tickers.map(\.symbol))
            .parameter("formatted", "false")
            .build()
    }

}
