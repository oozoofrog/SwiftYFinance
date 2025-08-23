import Foundation
import Testing
@testable import SwiftYFinance

/// Custom Screener 테스트
@Suite("Custom Screener Tests")
struct YFCustomScreenerTests {
    
    let session = YFSession()
    
    // MARK: - Basic Query Construction Tests
    
    @Test("기본 EQ 쿼리 생성 테스트")
    func testBasicEQQuery() {
        let query = YFScreenerQuery.eq("region", "us")
        let dict = query.toDictionary()
        
        #expect(dict["operator"] as? String == "EQ")
        let operands = dict["operands"] as? [Any]
        #expect(operands?.count == 2)
        #expect(operands?[0] as? String == "region")
        #expect(operands?[1] as? String == "us")
    }
    
    @Test("GT 쿼리 생성 테스트")
    func testGTQuery() {
        let query = YFScreenerQuery.gt("intradaymarketcap", 10_000_000_000)
        let dict = query.toDictionary()
        
        #expect(dict["operator"] as? String == "GT")
        let operands = dict["operands"] as? [Any]
        #expect(operands?.count == 2)
        #expect(operands?[0] as? String == "intradaymarketcap")
        #expect(operands?[1] as? Double == 10_000_000_000)
    }
    
    @Test("BETWEEN 쿼리 생성 테스트")
    func testBetweenQuery() {
        let query = YFScreenerQuery.between("peratio.lasttwelvemonths", min: 5.0, max: 20.0)
        let dict = query.toDictionary()
        
        #expect(dict["operator"] as? String == "BTWN")
        let operands = dict["operands"] as? [Any]
        #expect(operands?.count == 3)
        #expect(operands?[0] as? String == "peratio.lasttwelvemonths")
        #expect(operands?[1] as? Double == 5.0)
        #expect(operands?[2] as? Double == 20.0)
    }
    
    @Test("IS-IN 쿼리 생성 테스트")
    func testIsInQuery() {
        let query = YFScreenerQuery.isIn("sector", ["Technology", "Healthcare"])
        let dict = query.toDictionary()
        
        // IS-IN은 OR + EQ 조합으로 변환되어야 함
        #expect(dict["operator"] as? String == "OR")
        let operands = dict["operands"] as? [[String: Any]]
        #expect(operands?.count == 2)
        
        // 첫 번째 EQ 쿼리
        let firstEQ = operands?[0]
        #expect(firstEQ?["operator"] as? String == "EQ")
        let firstOperands = firstEQ?["operands"] as? [Any]
        #expect(firstOperands?[1] as? String == "Technology")
        
        // 두 번째 EQ 쿼리
        let secondEQ = operands?[1]
        #expect(secondEQ?["operator"] as? String == "EQ")
        let secondOperands = secondEQ?["operands"] as? [Any]
        #expect(secondOperands?[1] as? String == "Healthcare")
    }
    
    // MARK: - Complex Query Tests
    
    @Test("AND 쿼리 조합 테스트")
    func testAndQuery() {
        let query = YFScreenerQuery.and([
            .eq("region", "us"),
            .gte("intradaymarketcap", 1_000_000_000),
            .eq("sector", "Technology")
        ])
        
        let dict = query.toDictionary()
        #expect(dict["operator"] as? String == "AND")
        
        let operands = dict["operands"] as? [[String: Any]]
        #expect(operands?.count == 3)
        
        // 첫 번째 조건: region = us
        let firstCondition = operands?[0]
        #expect(firstCondition?["operator"] as? String == "EQ")
        
        // 두 번째 조건: marketcap >= 1B
        let secondCondition = operands?[1]
        #expect(secondCondition?["operator"] as? String == "GTE")
        
        // 세 번째 조건: sector = Technology
        let thirdCondition = operands?[2]
        #expect(thirdCondition?["operator"] as? String == "EQ")
    }
    
    @Test("중첩된 논리 연산 테스트")
    func testNestedLogicalQuery() {
        let query = YFScreenerQuery.and([
            .eq("region", "us"),
            .or([
                .eq("sector", "Technology"),
                .eq("sector", "Healthcare")
            ]),
            .gte("intradaymarketcap", 5_000_000_000)
        ])
        
        let dict = query.toDictionary()
        #expect(dict["operator"] as? String == "AND")
        
        let operands = dict["operands"] as? [[String: Any]]
        #expect(operands?.count == 3)
        
        // 두 번째 조건은 OR 쿼리여야 함
        let orCondition = operands?[1]
        #expect(orCondition?["operator"] as? String == "OR")
        
        let orOperands = orCondition?["operands"] as? [[String: Any]]
        #expect(orOperands?.count == 2)
    }
    
    // MARK: - Predefined Query Tests
    
    @Test("사전 정의된 쿼리 테스트")
    func testPredefinedQueries() {
        // US 주식 필터
        let usQuery = YFScreenerQuery.usEquities
        let usDict = usQuery.toDictionary()
        #expect(usDict["operator"] as? String == "EQ")
        
        // 대형주 필터
        let largeCapQuery = YFScreenerQuery.largeCap
        let largeCapDict = largeCapQuery.toDictionary()
        #expect(largeCapDict["operator"] as? String == "GTE")
        
        // 기술주 필터
        let techQuery = YFScreenerQuery.technology
        let techDict = techQuery.toDictionary()
        #expect(techDict["operator"] as? String == "EQ")
    }
    
    // MARK: - URL Builder Tests
    
    @Test("쿼리 없이 빌드 시 에러 발생")
    func testBuildWithoutQuery() async throws {
        await #expect(throws: YFError.invalidParameter("Query cannot be empty for custom screener")) {
            _ = try await YFAPIURLBuilder.customScreener(session: session)
                .build()
        }
    }
    
    @Test("기본 커스텀 스크리너 URL 구성")
    func testBasicCustomScreenerURL() async throws {
        let query = YFScreenerQuery.eq("region", "us")
        let url = try await YFAPIURLBuilder.customScreener(session: session)
            .query(query)
            .build()
        
        let urlString = url.absoluteString
        #expect(urlString.contains("https://query1.finance.yahoo.com/v1/finance/screener"))
    }
    
    @Test("커스텀 스크리너 파라미터 테스트")
    func testCustomScreenerParameters() async throws {
        let query = YFScreenerQuery.and([
            .usEquities,
            .largeCap,
            .technology
        ])
        
        let builder = YFAPIURLBuilder.customScreener(session: session)
            .query(query)
            .count(50)
            .offset(10)
            .sortField("marketCap")
            .sortOrder(ascending: false)
        
        let url = try await builder.build()
        #expect(url.absoluteString.contains("screener"))
        
        // Request body 검증
        let requestBody = try builder.getRequestBody()
        let bodyDict = try JSONSerialization.jsonObject(with: requestBody) as? [String: Any]
        
        #expect(bodyDict?["count"] as? Int == 50)
        #expect(bodyDict?["offset"] as? Int == 10)
        #expect(bodyDict?["sortField"] as? String == "marketCap")
        #expect(bodyDict?["sortType"] as? String == "DESC")
        #expect(bodyDict?["query"] != nil)
    }
    
    @Test("HTTP 메서드 확인")
    func testHTTPMethod() {
        let builder = YFAPIURLBuilder.customScreener(session: session)
        #expect(builder.httpMethod == "POST")
    }
    
    // MARK: - JSON Body Tests
    
    @Test("JSON 요청 바디 생성 테스트")
    func testJSONRequestBody() async throws {
        let query = YFScreenerQuery.and([
            .eq("region", "us"),
            .gte("intradaymarketcap", 1_000_000_000)
        ])
        
        let builder = YFAPIURLBuilder.customScreener(session: session)
            .query(query)
            .count(25)
        
        let jsonData = try builder.getRequestBody()
        let bodyDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        
        #expect(bodyDict != nil)
        #expect(bodyDict?["count"] as? Int == 25)
        #expect(bodyDict?["offset"] as? Int == 0)
        #expect(bodyDict?["userId"] as? String == "")
        #expect(bodyDict?["userIdType"] as? String == "guid")
        
        let queryDict = bodyDict?["query"] as? [String: Any]
        #expect(queryDict?["operator"] as? String == "AND")
    }
    
    @Test("빈 쿼리로 Request Body 생성 시 에러")
    func testEmptyQueryRequestBody() throws {
        let builder = YFAPIURLBuilder.customScreener(session: session)
        
        #expect(throws: YFError.invalidParameter("Query cannot be empty for custom screener")) {
            _ = try builder.getRequestBody()
        }
    }
    
    // MARK: - Field Constants Tests
    
    @Test("필드 상수 테스트")
    func testFieldConstants() {
        #expect(YFScreenerQuery.Field.price == "intradayprice")
        #expect(YFScreenerQuery.Field.marketCap == "intradaymarketcap")
        #expect(YFScreenerQuery.Field.region == "region")
        #expect(YFScreenerQuery.Field.sector == "sector")
        #expect(YFScreenerQuery.Field.peRatio == "peratio.lasttwelvemonths")
    }
    
    // MARK: - Real-world Query Examples
    
    @Test("실제 활용 쿼리 예시 - 대형 기술주")
    func testRealWorldLargeTechQuery() throws {
        let query = YFScreenerQuery.and([
            .eq(YFScreenerQuery.Field.region, "us"),
            .eq(YFScreenerQuery.Field.sector, "Technology"),
            .gte(YFScreenerQuery.Field.marketCap, 10_000_000_000),
            .between(YFScreenerQuery.Field.peRatio, min: 10.0, max: 30.0),
            .gte(YFScreenerQuery.Field.volume, 1_000_000)
        ])
        
        let jsonData = try query.toJSONData()
        let dict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        
        #expect(dict?["operator"] as? String == "AND")
        let operands = dict?["operands"] as? [[String: Any]]
        #expect(operands?.count == 5)
    }
    
    @Test("실제 활용 쿼리 예시 - 저평가 배당주")
    func testRealWorldValueDividendQuery() throws {
        let query = YFScreenerQuery.and([
            .usEquities,
            .largeCap,
            .lte(YFScreenerQuery.Field.peRatio, 15.0),
            .gte("forward_dividend_yield", 3.0),
            .highVolume
        ])
        
        let dict = query.toDictionary()
        #expect(dict["operator"] as? String == "AND")
        
        let operands = dict["operands"] as? [[String: Any]]
        #expect(operands?.count == 5)
    }
}