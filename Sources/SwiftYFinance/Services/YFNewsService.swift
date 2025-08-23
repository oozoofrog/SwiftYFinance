import Foundation

/// Yahoo Finance 뉴스 데이터 조회 서비스
///
/// Protocol + Struct 아키텍처를 따르는 뉴스 조회 전용 서비스입니다.
/// YFServiceCore를 통한 composition 패턴을 사용하여 공통 기능을 활용합니다.
/// Sendable 프로토콜을 준수하여 완전한 thread-safety를 보장합니다.
public struct YFNewsService: YFService {
    
    /// YFClient 참조
    public let client: YFClient
    
    
    /// 공통 기능을 제공하는 서비스 코어
    private let core: YFServiceCore
    
    /// YFNewsService 초기화
    /// - Parameter client: YFClient 인스턴스
    public init(client: YFClient) {
        self.client = client
        self.core = YFServiceCore(client: client)
    }
    
    // MARK: - Public Methods
    
    /// Raw JSON 뉴스 데이터 조회
    ///
    /// CLI나 raw 데이터가 필요한 경우 사용합니다.
    ///
    /// - Parameters:
    ///   - ticker: 뉴스를 조회할 종목
    ///   - count: 조회할 뉴스 개수 (기본값: 10, 최대 40)
    /// - Returns: Raw JSON 데이터
    /// - Throws: API 호출 중 발생하는 에러
    public func fetchRawJSON(
        ticker: YFTicker,
        count: Int = 10
    ) async throws -> Data {
        
        let url = try await buildNewsURL(ticker: ticker, count: count)
        return try await performFetchRawJSON(url: url, serviceName: "News")
    }
    
    /// 종목 관련 뉴스 조회
    ///
    /// 지정된 종목과 관련된 최신 뉴스를 조회합니다.
    ///
    /// - Parameters:
    ///   - ticker: 뉴스를 조회할 종목
    ///   - count: 조회할 뉴스 개수 (기본값: 10)
    /// - Returns: 뉴스 기사 배열
    /// - Throws: API 호출 중 발생하는 에러
    public func fetchNews(
        ticker: YFTicker,
        count: Int = 10
    ) async throws -> [YFNewsArticle] {
        
        return try await performNewsAPIRequest(ticker: ticker, count: count)
    }
    
    /// 다중 종목 뉴스 조회
    ///
    /// 여러 종목에 대한 뉴스를 일괄 조회합니다.
    ///
    /// - Parameters:
    ///   - tickers: 뉴스를 조회할 종목들
    ///   - count: 각 종목당 조회할 뉴스 개수 (기본값: 5)
    /// - Returns: 종목별 뉴스 딕셔너리
    /// - Throws: API 호출 중 발생하는 에러
    public func fetchMultipleNews(
        tickers: [YFTicker],
        count: Int = 5
    ) async throws -> [YFTicker: [YFNewsArticle]] {
        
        var result: [YFTicker: [YFNewsArticle]] = [:]
        
        // 순차적으로 처리 (동시성 문제 회피)
        for ticker in tickers {
            do {
                let news = try await performNewsAPIRequest(ticker: ticker, count: count)
                result[ticker] = news
            } catch {
                // 개별 종목 실패 시 빈 배열로 처리
                result[ticker] = []
            }
        }
        
        return result
    }
    
    // MARK: - Private Helper Methods
    
    /// 뉴스 API 요청 수행 (공통 로직)
    ///
    /// 단일 종목에 대한 뉴스 API 요청을 수행하고 결과를 파싱합니다.
    ///
    /// - Parameters:
    ///   - ticker: 뉴스를 조회할 종목
    ///   - count: 조회할 뉴스 개수
    /// - Returns: 뉴스 기사 배열
    /// - Throws: API 호출 중 발생하는 에러
    private func performNewsAPIRequest(
        ticker: YFTicker,
        count: Int
    ) async throws -> [YFNewsArticle] {
        
        let url = try await buildNewsURL(ticker: ticker, count: count)
        
        // 새로운 응답 구조 사용
        let response = try await performFetch(url: url, type: YFNewsResponse.self, serviceName: "News")
        
        return Array((response.news ?? []).prefix(count))
    }
    
    /// 뉴스 API URL 구성
    private func buildNewsURL(ticker: YFTicker, count: Int) async throws -> URL {
        return try await YFAPIURLBuilder.news(session: client.session)
            .symbol(ticker.symbol)
            .count(count)
            .disableFuzzyQuery()
            .build()
    }
    
    /// URL에서 쿼리 파라미터 추출
    private func extractQueryParameters(from url: URL) -> [String: String] {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return [:]
        }
        
        var parameters: [String: String] = [:]
        for item in queryItems {
            parameters[item.name] = item.value ?? ""
        }
        return parameters
    }
}