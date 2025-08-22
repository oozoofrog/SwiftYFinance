import Foundation

/// Yahoo Finance 옵션 체인 데이터 조회 서비스
///
/// Protocol + Struct 아키텍처를 따르는 옵션 조회 전용 서비스입니다.
/// YFServiceCore를 통한 composition 패턴을 사용하여 공통 기능을 활용합니다.
/// Sendable 프로토콜을 준수하여 완전한 thread-safety를 보장합니다.
public struct YFOptionsService: YFService {
    
    /// YFClient 참조
    public let client: YFClient
    
    
    /// 공통 기능을 제공하는 서비스 코어
    private let core: YFServiceCore
    
    /// YFOptionsService 초기화
    /// - Parameter client: YFClient 인스턴스
    public init(client: YFClient) {
        self.client = client
        self.core = YFServiceCore(client: client)
    }
    
    // MARK: - Public Methods
    
    /// Raw JSON 옵션 체인 데이터 조회
    ///
    /// CLI나 raw 데이터가 필요한 경우 사용합니다.
    ///
    /// - Parameters:
    ///   - ticker: 조회할 종목
    ///   - expiration: 특정 만기일 (nil이면 모든 만기일)
    /// - Returns: Raw JSON 데이터
    /// - Throws: API 호출 중 발생하는 에러
    public func fetchRawJSON(for ticker: YFTicker, expiration: Date? = nil) async throws -> Data {
        // URL 구성
        let url = try await buildOptionsURL(ticker: ticker, expiration: expiration)
        return try await performFetchRawJSON(url: url, serviceName: "Options")
    }
    
    /// 옵션 체인 데이터를 조회합니다.
    ///
    /// - Parameters:
    ///   - ticker: 조회할 종목
    ///   - expiration: 특정 만기일 (nil이면 모든 만기일)
    /// - Returns: 옵션 체인 데이터
    public func fetchOptionsChain(for ticker: YFTicker, expiration: Date? = nil) async throws -> YFOptionsChain {
        // URL 구성
        let url = try await buildOptionsURL(ticker: ticker, expiration: expiration)
        
        // API 요청 수행 및 JSON 디코딩
        return try await performFetch(url: url, type: YFOptionsChain.self, serviceName: "Options")
    }
    
    // MARK: - Private Methods
    
    /// Options API 요청 URL을 구성합니다
    ///
    /// - Parameters:
    ///   - ticker: 조회할 종목
    ///   - expiration: 특정 만기일 (옵셔널)
    /// - Returns: 구성된 API 요청 URL
    /// - Throws: URL 구성 중 발생하는 에러
    private func buildOptionsURL(ticker: YFTicker, expiration: Date?) async throws -> URL {
        var builder = core.apiBuilder()
            .host(YFHosts.query2)
            .path("/v7/finance/options/\(ticker.symbol)")
        
        if let expiration = expiration {
            let timestamp = Int(expiration.timeIntervalSince1970)
            builder = builder.parameter("date", String(timestamp))
        }
        
        return try await builder.build()
    }
}