import Foundation

/// Yahoo Finance Domain API 서비스
///
/// Yahoo Finance Domain API를 통한 섹터/산업/마켓 도메인 데이터 서비스입니다.
/// Protocol + Struct 아키텍처를 따르는 Domain API 전용 서비스입니다.
/// YFServiceCore를 통한 composition 패턴을 사용하여 공통 기능을 활용합니다.
/// Sendable 프로토콜을 준수하여 완전한 thread-safety를 보장합니다.
public struct YFDomainService: YFService {
    
    /// YFClient 참조
    public let client: YFClient
    
    /// 공통 기능을 제공하는 서비스 코어
    private let core: YFServiceCore
    
    /// YFDomainService 초기화
    /// - Parameter client: YFClient 인스턴스
    public init(client: YFClient) {
        self.client = client
        self.core = YFServiceCore(client: client)
    }
    
    // MARK: - Public Methods
    
    /// Raw JSON 섹터 데이터 조회
    ///
    /// CLI나 raw 데이터가 필요한 경우 사용합니다.
    ///
    /// - Parameter sector: 조회할 섹터 (기본값: technology)
    /// - Returns: Raw JSON 데이터
    /// - Throws: API 호출 중 발생하는 에러
    public func fetchRawJSON(sector: YFSector = .technology) async throws -> Data {
        let url = try await buildSectorURL(for: sector)
        return try await performFetchRawJSON(url: url, serviceName: "Domain")
    }
    
    /// Raw JSON 산업 데이터 조회
    ///
    /// CLI나 raw 데이터가 필요한 경우 사용합니다.
    ///
    /// - Parameter industry: 조회할 산업 키
    /// - Returns: Raw JSON 데이터
    /// - Throws: API 호출 중 발생하는 에러
    public func fetchRawJSON(industry: String) async throws -> Data {
        let url = try await buildIndustryURL(for: industry)
        return try await performFetchRawJSON(url: url, serviceName: "Domain")
    }
    
    /// Raw JSON 마켓 데이터 조회
    ///
    /// CLI나 raw 데이터가 필요한 경우 사용합니다.
    ///
    /// - Parameter market: 조회할 마켓 (기본값: us)
    /// - Returns: Raw JSON 데이터
    /// - Throws: API 호출 중 발생하는 에러
    public func fetchRawJSON(market: YFMarket = .us) async throws -> Data {
        let url = try await buildMarketURL(for: market)
        return try await performFetchRawJSON(url: url, serviceName: "Domain")
    }
    
    /// 특정 섹터 상세 데이터 조회 (권장)
    ///
    /// Yahoo Finance에서 제공하는 특정 섹터의 상세 시장 데이터를 조회합니다.
    /// 실제 API 응답 구조를 정확히 반영한 모델을 사용합니다.
    ///
    /// - Parameter sector: 조회할 섹터 (기본값: technology)
    /// - Returns: 섹터 상세 데이터
    /// - Throws: `YFError.invalidRequest` 등 API 오류
    public func fetchSectorDetails(_ sector: YFSector = .technology) async throws -> YFDomainSectorResponse {
        let url = try await buildSectorURL(for: sector)
        return try await performFetch(url: url, type: YFDomainSectorResponse.self, serviceName: "Domain")
    }
    
    
    /// 특정 산업 데이터 조회
    ///
    /// Yahoo Finance에서 제공하는 특정 산업의 시장 데이터를 조회합니다.
    ///
    /// - Parameter industry: 조회할 산업 키
    /// - Returns: 산업 데이터 배열
    /// - Throws: `YFError.invalidRequest` 등 API 오류
    public func fetchIndustry(_ industry: String) async throws -> [YFDomainResult] {
        let url = try await buildIndustryURL(for: industry)
        let domainResponse = try await performFetch(url: url, type: YFDomainResponse.self, serviceName: "Domain")
        return domainResponse.finance?.result ?? []
    }
    
    /// 특정 마켓 데이터 조회
    ///
    /// Yahoo Finance에서 제공하는 특정 마켓의 시장 데이터를 조회합니다.
    ///
    /// - Parameter market: 조회할 마켓 (기본값: us)
    /// - Returns: 마켓 데이터 배열
    /// - Throws: `YFError.invalidRequest` 등 API 오류
    public func fetchMarket(_ market: YFMarket = .us) async throws -> [YFDomainResult] {
        let url = try await buildMarketURL(for: market)
        let domainResponse = try await performFetch(url: url, type: YFDomainResponse.self, serviceName: "Domain")
        return domainResponse.finance?.result ?? []
    }
    
    // MARK: - Private Helper Methods
    
    /// 섹터 URL 구성 헬퍼
    private func buildSectorURL(for sector: YFSector) async throws -> URL {
        return try await YFAPIURLBuilder.domain(session: client.session)
            .sector(sector)
            .parameter("formatted", "false")
            .parameter("corsDomain", "finance.yahoo.com")
            .build()
    }
    
    /// 산업 URL 구성 헬퍼
    private func buildIndustryURL(for industry: String) async throws -> URL {
        return try await YFAPIURLBuilder.domain(session: client.session)
            .industry(industry)
            .parameter("formatted", "false")
            .parameter("corsDomain", "finance.yahoo.com")
            .build()
    }
    
    /// 마켓 URL 구성 헬퍼
    private func buildMarketURL(for market: YFMarket) async throws -> URL {
        return try await YFAPIURLBuilder.domain(session: client.session)
            .market(market)
            .parameter("formatted", "false")
            .parameter("corsDomain", "finance.yahoo.com")
            .build()
    }
}