import Foundation

/// 종목 검색 및 자동완성 서비스
///
/// Yahoo Finance API를 통해 종목 검색, 자동완성 제안 등의 기능을 제공합니다.
/// 검색 결과는 캐시되어 성능을 최적화합니다.
/// Sendable 프로토콜을 준수하여 concurrent 환경에서 안전하게 사용할 수 있습니다.
/// Protocol + Struct 설계로 @unchecked 없이도 완전한 thread safety를 보장합니다.
public struct YFSearchService: YFService {
    
    /// YFClient 참조
    public let client: YFClient
    
    /// 디버깅 모드 활성화 여부
    public let debugEnabled: Bool
    
    /// 공통 로직을 처리하는 핵심 구조체
    private let core: YFServiceCore
    
    /// YFSearchService 초기화
    /// - Parameters:
    ///   - client: YFClient 인스턴스
    ///   - debugEnabled: 디버깅 로그 활성화 여부 (기본값: false)
    public init(client: YFClient, debugEnabled: Bool = false) {
        self.client = client
        self.debugEnabled = debugEnabled
        self.core = YFServiceCore(client: client, debugEnabled: debugEnabled)
    }
    
    /// 회사명으로 검색을 수행합니다
    /// 
    /// 간단한 회사명 검색을 위한 편의 메서드입니다.
    /// 내부적으로 YFSearchQuery를 생성하여 고급 검색을 호출합니다.
    ///
    /// ## 사용 예시
    /// ```swift
    /// let client = YFClient()
    /// let results = try await client.search.find(companyName: "Apple")
    /// for result in results {
    ///     print("\(result.symbol): \(result.shortName)")
    /// }
    /// ```
    ///
    /// - Parameter companyName: 검색할 회사명
    /// - Returns: 검색 결과 배열
    /// - Throws: 검색 실패 시 YFError
    public func find(companyName: String) async throws -> [YFSearchResult] {
        let query = YFSearchQuery(term: companyName)
        return try await find(query: query)
    }
    
    /// 고급 검색을 수행합니다
    /// 
    /// YFSearchQuery를 사용하여 상세한 검색 조건을 지정할 수 있습니다.
    /// 결과 개수 제한, 종목 유형 필터링 등이 가능합니다.
    /// 검색 결과는 1분간 캐시되어 동일한 검색에 대한 성능을 최적화합니다.
    ///
    /// ## 사용 예시
    /// ```swift
    /// let query = YFSearchQuery(
    ///     term: "technology",
    ///     maxResults: 20,
    ///     quoteTypes: [.equity, .etf]
    /// )
    /// let results = try await client.search.find(query: query)
    /// ```
    ///
    /// - Parameter query: 검색 쿼리 조건
    /// - Returns: 검색 결과 배열
    /// - Throws: 검색 실패 시 YFError
    public func find(query: YFSearchQuery) async throws -> [YFSearchResult] {
        // 캐시에서 먼저 확인
        let cacheKey = query.term
        if let cachedResults = await YFSearchCache.shared.get(for: cacheKey) {
            return cachedResults
        }
        
        // Rate limiting과 함께 API 호출
        let results = try await performSearch(query: query)
        
        // 결과를 캐시에 저장
        await YFSearchCache.shared.set(results, for: cacheKey)
        
        return results
    }
    
    /// 검색어 자동완성 제안을 반환합니다
    /// 
    /// 사용자가 입력한 prefix를 기반으로 관련된 회사명들을 제안합니다.
    /// 입력 필드의 자동완성 기능 구현에 유용합니다.
    ///
    /// ## 사용 예시
    /// ```swift
    /// let suggestions = try await client.search.suggestions(prefix: "App")
    /// // ["Apple Inc.", "Applied Materials Inc.", ...] 
    /// ```
    ///
    /// - Parameter prefix: 검색어 prefix
    /// - Returns: 제안된 회사명 배열
    /// - Throws: 검색 실패 시 YFError
    public func suggestions(prefix: String) async throws -> [String] {
        guard !prefix.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        
        let results = try await find(companyName: prefix)
        return results.compactMap { $0.longName ?? $0.shortName }
    }
    
    // MARK: - Private Search Implementation
    
    /// 실제 검색 API 호출을 수행합니다 (인증된 세션 사용)
    /// - Parameter query: 검색 쿼리
    /// - Returns: 검색 결과 배열
    /// - Throws: 네트워크 또는 파싱 에러
    private func performSearch(query: YFSearchQuery) async throws -> [YFSearchResult] {
        guard query.isValid else {
            throw YFError.invalidParameter("검색어가 유효하지 않습니다")
        }
        
        // CSRF 인증 시도
        await ensureCSRFAuthentication()
        
        let url = try await buildSearchURL(for: query)
        let (data, _) = try await core.authenticatedRequest(url: url)
        
        // API 응답 디버깅 로그
        logAPIResponse(data, serviceName: "Search")
        
        return try parseSearchResponse(data)
    }
    
    /// 검색 URL 구성
    private func buildSearchURL(for query: YFSearchQuery) async throws -> URL {
        let parameters = query.toURLParameters()
        return try await core.apiBuilder()
            .host(YFHosts.query2)
            .path(YFPaths.search)
            .parameters(parameters)
            .build()
    }
    
    /// 검색 응답 JSON 파싱
    private func parseSearchResponse(_ data: Data) throws -> [YFSearchResult] {
        let searchResponse = try core.parseJSON(data: data, type: YFSearchResponse.self)
        return searchResponse.quotes ?? []
    }
}

// MARK: - Search Response Models

/// Yahoo Finance 검색 API 응답 구조
private struct YFSearchResponse: Decodable {
    let quotes: [YFSearchResult]?
    let news: [YFSearchNewsItem]?
    let nav: [YFSearchNavItem]?
    
    private enum CodingKeys: String, CodingKey {
        case quotes, news, nav
    }
}

/// 검색 결과에 포함된 뉴스 아이템
private struct YFSearchNewsItem: Decodable {
    let uuid: String?
    let title: String?
    let publisher: String?
    
    private enum CodingKeys: String, CodingKey {
        case uuid, title, publisher
    }
}

/// 검색 결과에 포함된 네비게이션 아이템
private struct YFSearchNavItem: Decodable {
    let navName: String?
    let navUrl: String?
    
    private enum CodingKeys: String, CodingKey {
        case navName, navUrl
    }
}