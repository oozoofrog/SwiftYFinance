import Foundation

// MARK: - YFClient Search Extensions

extension YFClient {
    
    /// 회사명으로 검색을 수행합니다
    /// 
    /// 간단한 회사명 검색을 위한 편의 메서드입니다.
    /// 내부적으로 YFSearchQuery를 생성하여 고급 검색을 호출합니다.
    ///
    /// ## 사용 예시
    /// ```swift
    /// let client = YFClient()
    /// let results = try await client.search(companyName: "Apple")
    /// for result in results {
    ///     print("\(result.symbol): \(result.shortName)")
    /// }
    /// ```
    ///
    /// - Parameter companyName: 검색할 회사명
    /// - Returns: 검색 결과 배열
    /// - Throws: 검색 실패 시 YFError
    public func search(companyName: String) async throws -> [YFSearchResult] {
        let query = YFSearchQuery(term: companyName)
        return try await search(query: query)
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
    /// let results = try await client.search(query: query)
    /// ```
    ///
    /// - Parameter query: 검색 쿼리 조건
    /// - Returns: 검색 결과 배열
    /// - Throws: 검색 실패 시 YFError
    public func search(query: YFSearchQuery) async throws -> [YFSearchResult] {
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
    /// let suggestions = try await client.searchSuggestions(prefix: "App")
    /// // ["Apple Inc.", "Applied Materials Inc.", ...] 
    /// ```
    ///
    /// - Parameter prefix: 검색어 prefix
    /// - Returns: 제안된 회사명 배열
    /// - Throws: 검색 실패 시 YFError
    public func searchSuggestions(prefix: String) async throws -> [String] {
        guard !prefix.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        
        let results = try await search(companyName: prefix)
        return results.compactMap { $0.longName ?? $0.shortName }
    }
}

// MARK: - Private Search Implementation

extension YFClient {
    
    /// 실제 검색 API 호출을 수행합니다 (인증된 세션 사용)
    /// - Parameter query: 검색 쿼리
    /// - Returns: 검색 결과 배열
    /// - Throws: 네트워크 또는 파싱 에러
    private func performSearch(query: YFSearchQuery) async throws -> [YFSearchResult] {
        guard query.isValid else {
            throw YFError.invalidParameter("검색어가 유효하지 않습니다")
        }
        
        let url = try buildSearchURL(for: query)
        let (data, response) = try await session.makeAuthenticatedRequest(url: url)
        
        try validateHTTPResponse(response)
        return try parseSearchResponse(data)
    }
    
    /// 검색 URL 구성
    private func buildSearchURL(for query: YFSearchQuery) throws -> URL {
        let baseURL = "https://query2.finance.yahoo.com/v1/finance/search"
        guard var urlComponents = URLComponents(string: baseURL) else {
            throw YFError.invalidURL
        }
        
        let parameters = query.toURLParameters()
        urlComponents.queryItems = parameters.map { key, value in
            URLQueryItem(name: key, value: value)
        }
        
        guard let url = urlComponents.url else {
            throw YFError.invalidURL
        }
        
        return url
    }
    
    /// HTTP 응답 검증
    private func validateHTTPResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw YFError.networkErrorWithMessage("Invalid response type")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw YFError.networkErrorWithMessage("HTTP \(httpResponse.statusCode)")
        }
    }
    
    /// 검색 응답 JSON 파싱
    private func parseSearchResponse(_ data: Data) throws -> [YFSearchResult] {
        do {
            let searchResponse = try JSONDecoder().decode(YFSearchResponse.self, from: data)
            return searchResponse.quotes ?? []
        } catch {
            throw YFError.parsingErrorWithMessage("검색 결과 파싱 실패: \(error.localizedDescription)")
        }
    }
}

// MARK: - Search Response Models

/// Yahoo Finance 검색 API 응답 구조
private struct YFSearchResponse: Codable {
    let quotes: [YFSearchResult]?
    let news: [YFSearchNewsItem]?
    let nav: [YFSearchNavItem]?
    
    private enum CodingKeys: String, CodingKey {
        case quotes, news, nav
    }
}

/// 검색 결과에 포함된 뉴스 아이템
private struct YFSearchNewsItem: Codable {
    let uuid: String?
    let title: String?
    let publisher: String?
    
    private enum CodingKeys: String, CodingKey {
        case uuid, title, publisher
    }
}

/// 검색 결과에 포함된 네비게이션 아이템
private struct YFSearchNavItem: Codable {
    let navName: String?
    let navUrl: String?
    
    private enum CodingKeys: String, CodingKey {
        case navName, navUrl
    }
}