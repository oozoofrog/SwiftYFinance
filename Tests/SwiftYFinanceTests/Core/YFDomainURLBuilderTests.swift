import Foundation
import Testing
@testable import SwiftYFinance

/// Domain URL Builder 테스트
@Suite("Domain URL Builder Tests")
struct YFDomainURLBuilderTests {
    
    let session = YFSession()
    
    // MARK: - Basic URL Construction Tests
    
    @Test("기본 도메인 빌더 없이 빌드 시 에러 발생")
    func testBuildWithoutDomain() async throws {
        await #expect(throws: YFError.invalidParameter("Domain type and key cannot be empty")) {
            _ = try await YFAPIURLBuilder.domain(session: session)
                .build()
        }
    }
    
    // MARK: - Sector API Tests
    
    @Test("섹터 API URL 구성 테스트")
    func testSectorAPIConstruction() async throws {
        let url = try await YFAPIURLBuilder.domain(session: session)
            .sector(.technology)
            .build()
        
        let urlString = url.absoluteString
        #expect(urlString.contains("https://query1.finance.yahoo.com/v1/finance/sectors/technology"))
    }
    
    @Test("기술 섹터 편의 메서드 테스트")
    func testTechnologySectorConvenience() async throws {
        let url = try await YFAPIURLBuilder.domain(session: session)
            .technologySector()
            .build()
        
        let urlString = url.absoluteString
        #expect(urlString.contains("sectors/technology"))
    }
    
    @Test("커스텀 섹터 키 테스트")
    func testCustomSectorKey() async throws {
        let customSector = "custom-sector"
        let url = try await YFAPIURLBuilder.domain(session: session)
            .sectorKey(customSector)
            .build()
        
        let urlString = url.absoluteString
        #expect(urlString.contains("sectors/\(customSector)"))
    }
    
    @Test("의료 섹터 테스트")
    func testHealthcareSector() async throws {
        let url = try await YFAPIURLBuilder.domain(session: session)
            .sector(.healthcare)
            .count(50)
            .build()
        
        let urlString = url.absoluteString
        #expect(urlString.contains("sectors/healthcare"))
        #expect(urlString.contains("count=50"))
    }
    
    // MARK: - Industry API Tests
    
    @Test("산업 API URL 구성 테스트")
    func testIndustryAPIConstruction() async throws {
        let industry = "semiconductors"
        let url = try await YFAPIURLBuilder.domain(session: session)
            .industry(industry)
            .build()
        
        let urlString = url.absoluteString
        #expect(urlString.contains("https://query1.finance.yahoo.com/v1/finance/industries/semiconductors"))
    }
    
    @Test("반도체 산업 편의 메서드 테스트")
    func testSemiconductorIndustryConvenience() async throws {
        let url = try await YFAPIURLBuilder.domain(session: session)
            .semiconductorIndustry()
            .build()
        
        let urlString = url.absoluteString
        #expect(urlString.contains("industries/semiconductors"))
    }
    
    @Test("소프트웨어 인프라 산업 테스트")
    func testSoftwareInfrastructureIndustry() async throws {
        let url = try await YFAPIURLBuilder.domain(session: session)
            .softwareInfrastructureIndustry()
            .offset(10)
            .build()
        
        let urlString = url.absoluteString
        #expect(urlString.contains("industries/software-infrastructure"))
        #expect(urlString.contains("offset=10"))
    }
    
    // MARK: - Market API Tests
    
    @Test("시장 API URL 구성 테스트")
    func testMarketAPIConstruction() async throws {
        let url = try await YFAPIURLBuilder.domain(session: session)
            .market(.us)
            .build()
        
        let urlString = url.absoluteString
        #expect(urlString.contains("https://query1.finance.yahoo.com/v1/finance/markets/us"))
    }
    
    @Test("미국 시장 편의 메서드 테스트")
    func testUSMarketConvenience() async throws {
        let url = try await YFAPIURLBuilder.domain(session: session)
            .usMarket()
            .build()
        
        let urlString = url.absoluteString
        #expect(urlString.contains("markets/us"))
    }
    
    @Test("커스텀 시장 키 테스트")
    func testCustomMarketKey() async throws {
        let customMarket = "kr"
        let url = try await YFAPIURLBuilder.domain(session: session)
            .marketKey(customMarket)
            .build()
        
        let urlString = url.absoluteString
        #expect(urlString.contains("markets/\(customMarket)"))
    }
    
    @Test("다양한 시장 테스트")
    func testVariousMarkets() async throws {
        let markets: [YFMarket] = [.japan, .china, .europe, .canada]
        
        for market in markets {
            let url = try await YFAPIURLBuilder.domain(session: session)
                .market(market)
                .build()
            
            let urlString = url.absoluteString
            #expect(urlString.contains("markets/\(market.rawValue)"))
        }
    }
    
    // MARK: - Parameter Tests
    
    @Test("카운트 파라미터 테스트")
    func testCountParameter() async throws {
        let url = try await YFAPIURLBuilder.domain(session: session)
            .sector(.financialServices)
            .count(100)
            .build()
        
        let urlString = url.absoluteString
        #expect(urlString.contains("count=100"))
    }
    
    @Test("오프셋 파라미터 테스트")
    func testOffsetParameter() async throws {
        let url = try await YFAPIURLBuilder.domain(session: session)
            .industry("biotechnology")
            .offset(25)
            .build()
        
        let urlString = url.absoluteString
        #expect(urlString.contains("offset=25"))
    }
    
    @Test("정렬 파라미터 테스트")
    func testSortParameters() async throws {
        let url = try await YFAPIURLBuilder.domain(session: session)
            .market(.asiaPacific)
            .sortField("marketCap")
            .sortOrder(ascending: false)
            .build()
        
        let urlString = url.absoluteString
        #expect(urlString.contains("sortField=marketCap"))
        #expect(urlString.contains("sortType=DESC"))
    }
    
    @Test("오름차순 정렬 테스트")
    func testAscendingSortOrder() async throws {
        let url = try await YFAPIURLBuilder.domain(session: session)
            .sector(.energy)
            .sortOrder(ascending: true)
            .build()
        
        let urlString = url.absoluteString
        #expect(urlString.contains("sortType=ASC"))
    }
    
    @Test("커스텀 파라미터 테스트")
    func testCustomParameter() async throws {
        let url = try await YFAPIURLBuilder.domain(session: session)
            .sector(.utilities)
            .parameter("customKey", "customValue")
            .build()
        
        let urlString = url.absoluteString
        #expect(urlString.contains("customKey=customValue"))
    }
    
    // MARK: - Method Chaining Tests
    
    @Test("메서드 체이닝 조합 테스트")
    func testMethodChaining() async throws {
        let url = try await YFAPIURLBuilder.domain(session: session)
            .sector(.basicMaterials)
            .count(50)
            .offset(10)
            .sortField("volume")
            .sortOrder(ascending: false)
            .parameter("extra", "value")
            .build()
        
        let urlString = url.absoluteString
        #expect(urlString.contains("sectors/basic-materials"))
        #expect(urlString.contains("count=50"))
        #expect(urlString.contains("offset=10"))
        #expect(urlString.contains("sortField=volume"))
        #expect(urlString.contains("sortType=DESC"))
        #expect(urlString.contains("extra=value"))
    }
    
    // MARK: - Domain Enum Tests
    
    @Test("섹터 한글명 테스트")
    func testSectorDisplayNames() {
        #expect(YFSector.technology.displayName == "기술")
        #expect(YFSector.healthcare.displayName == "의료")
        #expect(YFSector.financialServices.displayName == "금융서비스")
        #expect(YFSector.energy.displayName == "에너지")
    }
    
    @Test("시장 한글명 테스트")
    func testMarketDisplayNames() {
        #expect(YFMarket.us.displayName == "미국")
        #expect(YFMarket.japan.displayName == "일본")
        #expect(YFMarket.china.displayName == "중국")
        #expect(YFMarket.europe.displayName == "유럽")
    }
    
    @Test("섹터 주요 산업군 테스트")
    func testSectorMajorIndustries() {
        let techIndustries = YFSector.technology.majorIndustries
        #expect(techIndustries.contains("semiconductors"))
        #expect(techIndustries.contains("software-infrastructure"))
        
        let healthcareIndustries = YFSector.healthcare.majorIndustries
        #expect(healthcareIndustries.contains("biotechnology"))
        #expect(healthcareIndustries.contains("drug-manufacturers-general"))
    }
}