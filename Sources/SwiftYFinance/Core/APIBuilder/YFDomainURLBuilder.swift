import Foundation

// MARK: - Domain API Builder

extension YFAPIURLBuilder {
    
    /// Domain API 전용 빌더
    /// 
    /// Yahoo Finance Domain API를 통해 섹터, 산업, 시장별 정보를 조회합니다.
    /// yfinance Python 라이브러리의 domain 모듈과 호환됩니다.
    ///
    /// ## 사용 예시
    /// ```swift
    /// // 섹터 정보 조회
    /// let sectorURL = try await YFAPIURLBuilder.domain(session: session)
    ///     .sector(.technology)
    ///     .build()
    /// 
    /// // 특정 산업 정보 조회
    /// let industryURL = try await YFAPIURLBuilder.domain(session: session)
    ///     .industry("semiconductors")
    ///     .build()
    /// 
    /// // 시장 정보 조회  
    /// let marketURL = try await YFAPIURLBuilder.domain(session: session)
    ///     .market(.us)
    ///     .build()
    /// ```
    public struct DomainBuilder: Sendable {
        private let session: YFSession
        private let baseURL = "https://query1.finance.yahoo.com/v1/finance"
        private var domainType: YFDomainType?
        private var domainKey: String = ""
        private var parameters: [String: String] = [:]
        
        init(session: YFSession) {
            self.session = session
        }
        
        private init(session: YFSession, domainType: YFDomainType?, domainKey: String, parameters: [String: String]) {
            self.session = session
            self.domainType = domainType
            self.domainKey = domainKey
            self.parameters = parameters
        }
        
        /// 섹터별 정보 조회
        /// - Parameter sector: 조회할 섹터
        /// - Returns: 새로운 빌더 인스턴스
        public func sector(_ sector: YFSector) -> DomainBuilder {
            return DomainBuilder(
                session: session,
                domainType: .sector,
                domainKey: sector.rawValue,
                parameters: parameters
            )
        }
        
        /// 커스텀 섹터 키로 조회
        /// - Parameter key: 섹터 키 문자열
        /// - Returns: 새로운 빌더 인스턴스
        public func sectorKey(_ key: String) -> DomainBuilder {
            return DomainBuilder(
                session: session,
                domainType: .sector,
                domainKey: key,
                parameters: parameters
            )
        }
        
        /// 산업별 정보 조회
        /// - Parameter industry: 산업 키 문자열
        /// - Returns: 새로운 빌더 인스턴스
        public func industry(_ industry: String) -> DomainBuilder {
            return DomainBuilder(
                session: session,
                domainType: .industry,
                domainKey: industry,
                parameters: parameters
            )
        }
        
        /// 시장별 정보 조회
        /// - Parameter market: 조회할 시장
        /// - Returns: 새로운 빌더 인스턴스
        public func market(_ market: YFMarket) -> DomainBuilder {
            return DomainBuilder(
                session: session,
                domainType: .market,
                domainKey: market.rawValue,
                parameters: parameters
            )
        }
        
        /// 커스텀 시장 키로 조회
        /// - Parameter key: 시장 키 문자열
        /// - Returns: 새로운 빌더 인스턴스
        public func marketKey(_ key: String) -> DomainBuilder {
            return DomainBuilder(
                session: session,
                domainType: .market,
                domainKey: key,
                parameters: parameters
            )
        }
        
        /// 조회 개수 제한
        /// - Parameter count: 최대 결과 개수
        /// - Returns: 새로운 빌더 인스턴스
        public func count(_ count: Int) -> DomainBuilder {
            var newParams = parameters
            newParams["count"] = String(count)
            return DomainBuilder(session: session, domainType: domainType, domainKey: domainKey, parameters: newParams)
        }
        
        /// 오프셋 설정
        /// - Parameter offset: 결과 시작 위치
        /// - Returns: 새로운 빌더 인스턴스
        public func offset(_ offset: Int) -> DomainBuilder {
            var newParams = parameters
            newParams["offset"] = String(offset)
            return DomainBuilder(session: session, domainType: domainType, domainKey: domainKey, parameters: newParams)
        }
        
        /// 정렬 필드 설정
        /// - Parameter field: 정렬 기준 필드
        /// - Returns: 새로운 빌더 인스턴스
        public func sortField(_ field: String) -> DomainBuilder {
            var newParams = parameters
            newParams["sortField"] = field
            return DomainBuilder(session: session, domainType: domainType, domainKey: domainKey, parameters: newParams)
        }
        
        /// 정렬 순서 설정
        /// - Parameter ascending: 오름차순 여부 (기본값: false)
        /// - Returns: 새로운 빌더 인스턴스
        public func sortOrder(ascending: Bool = false) -> DomainBuilder {
            var newParams = parameters
            newParams["sortType"] = ascending ? "ASC" : "DESC"
            return DomainBuilder(session: session, domainType: domainType, domainKey: domainKey, parameters: newParams)
        }
        
        /// 추가 파라미터 설정
        /// - Parameters:
        ///   - key: 파라미터 키
        ///   - value: 파라미터 값
        /// - Returns: 새로운 빌더 인스턴스
        public func parameter(_ key: String, _ value: String) -> DomainBuilder {
            var newParams = parameters
            newParams[key] = value
            return DomainBuilder(session: session, domainType: domainType, domainKey: domainKey, parameters: newParams)
        }
        
        /// URL 구성
        /// - Returns: 구성된 URL
        /// - Throws: URL 구성 실패 시
        public func build() async throws -> URL {
            guard let domainType = domainType, !domainKey.isEmpty else {
                throw YFError.invalidParameter("Domain type and key cannot be empty")
            }
            
            let urlWithPath = "\(baseURL)/\(domainType.rawValue)/\(domainKey)"
            return try await YFAPIURLBuilder.buildURL(baseURL: urlWithPath, parameters: parameters, session: session)
        }
    }
}

// MARK: - Convenience Extensions

extension YFAPIURLBuilder.DomainBuilder {
    
    /// 기술 섹터의 주요 산업들 조회
    /// - Returns: 새로운 빌더 인스턴스
    public func technologySector() -> YFAPIURLBuilder.DomainBuilder {
        return sector(.technology)
    }
    
    /// 의료 섹터의 주요 산업들 조회
    /// - Returns: 새로운 빌더 인스턴스
    public func healthcareSector() -> YFAPIURLBuilder.DomainBuilder {
        return sector(.healthcare)
    }
    
    /// 금융 서비스 섹터의 주요 산업들 조회
    /// - Returns: 새로운 빌더 인스턴스
    public func financialServicesSector() -> YFAPIURLBuilder.DomainBuilder {
        return sector(.financialServices)
    }
    
    /// 미국 시장 정보 조회
    /// - Returns: 새로운 빌더 인스턴스
    public func usMarket() -> YFAPIURLBuilder.DomainBuilder {
        return market(.us)
    }
    
    /// 반도체 산업 정보 조회
    /// - Returns: 새로운 빌더 인스턴스
    public func semiconductorIndustry() -> YFAPIURLBuilder.DomainBuilder {
        return industry("semiconductors")
    }
    
    /// 소프트웨어 인프라 산업 정보 조회
    /// - Returns: 새로운 빌더 인스턴스
    public func softwareInfrastructureIndustry() -> YFAPIURLBuilder.DomainBuilder {
        return industry("software-infrastructure")
    }
}