import Testing
import Foundation
@testable import SwiftYFinance

/// YFServiceCore.parseJSON() @concurrent 함수 직접 단위 테스트
///
/// YFServiceCore.parseJSON()은 @concurrent async throws 함수입니다.
/// CPU-bound JSON 파싱이 concurrent thread pool에서 올바르게 실행되는지 검증합니다.
@Suite("YFServiceCore 단위 테스트 - @concurrent parseJSON() 직접 검증")
struct YFServiceCoreTests {

    // MARK: - 테스트 픽스처

    /// MockNetworkProvider를 사용한 YFServiceCore 인스턴스
    let core: YFServiceCore = {
        let client = TestFixtures.mockClient(provider: .success)
        return YFServiceCore(client: client)
    }()

    // MARK: - 정상 파싱 테스트

    @Test("parseJSON() — 유효한 JSON을 YFQuoteResponse로 파싱")
    func testParseJSONValidQuoteResponse() async throws {
        let json = """
            {
                "quoteResponse": {
                    "result": [{
                        "symbol": "GOOGL",
                        "longName": "Alphabet Inc.",
                        "shortName": "Alphabet",
                        "quoteType": "EQUITY",
                        "regularMarketPrice": 165.20,
                        "regularMarketVolume": 20000000,
                        "marketCap": 2100000000000,
                        "currency": "USD",
                        "exchange": "NMS",
                        "fullExchangeName": "Nasdaq Global Select Market",
                        "exchangeTimezoneName": "America/New_York",
                        "exchangeTimezoneShortName": "EST"
                    }],
                    "error": null
                }
            }
            """
        let data = try #require(json.data(using: .utf8))

        // @concurrent parseJSON() 직접 await 호출
        let response: YFQuoteResponse = try await core.parseJSON(data: data, type: YFQuoteResponse.self)

        let results = try #require(response.result)
        #expect(results.count == 1)
        #expect(results.first?.basicInfo.symbol == "GOOGL")
        #expect(results.first?.basicInfo.longName == "Alphabet Inc.")
    }

    @Test("parseJSON() — YFQuoteBasicInfo 단일 모델 파싱")
    func testParseJSONBasicInfo() async throws {
        let json = """
            {
                "symbol": "NVDA",
                "longName": "NVIDIA Corporation",
                "shortName": "NVIDIA",
                "quoteType": "EQUITY"
            }
            """
        let data = try #require(json.data(using: .utf8))

        // @concurrent parseJSON() 직접 await 호출
        let basicInfo: YFQuoteBasicInfo = try await core.parseJSON(data: data, type: YFQuoteBasicInfo.self)

        #expect(basicInfo.symbol == "NVDA")
        #expect(basicInfo.longName == "NVIDIA Corporation")
        #expect(basicInfo.quoteType == "EQUITY")
    }

    @Test("parseJSON() — 빈 quoteResponse result 파싱")
    func testParseJSONEmptyResult() async throws {
        let json = """
            {
                "quoteResponse": {
                    "result": [],
                    "error": null
                }
            }
            """
        let data = try #require(json.data(using: .utf8))

        let response: YFQuoteResponse = try await core.parseJSON(data: data, type: YFQuoteResponse.self)

        let results = try #require(response.result)
        #expect(results.isEmpty)
    }

    // MARK: - 에러 처리 테스트

    @Test("parseJSON() — 잘못된 JSON 입력 시 YFError.parsingError throw")
    func testParseJSONInvalidJSONThrowsParsingError() async throws {
        let invalidData = try #require("{ invalid json }".data(using: .utf8))

        do {
            _ = try await core.parseJSON(data: invalidData, type: YFQuoteResponse.self)
            #expect(false, "파싱 에러가 발생해야 함")
        } catch let error as YFError {
            if case .parsingError = error {
                // 예상된 에러
            } else {
                #expect(false, "YFError.parsingError가 아닌 다른 에러: \(error)")
            }
        }
    }

    @Test("parseJSON() — 비어있는 Data 입력 시 YFError.parsingError throw")
    func testParseJSONEmptyDataThrowsParsingError() async throws {
        let emptyData = Data()

        do {
            _ = try await core.parseJSON(data: emptyData, type: YFQuoteResponse.self)
            #expect(false, "파싱 에러가 발생해야 함")
        } catch let error as YFError {
            if case .parsingError = error {
                // 예상된 에러
            } else {
                #expect(false, "YFError.parsingError가 아닌 다른 에러: \(error)")
            }
        }
    }

    // MARK: - @concurrent 동작 검증

    @Test("parseJSON() — 병렬 호출 시 데이터 레이스 없이 정상 동작")
    func testParseJSONConcurrentCallsNoDataRace() async throws {
        let json = """
            {"symbol": "AMZN", "longName": "Amazon.com, Inc."}
            """
        let data = try #require(json.data(using: .utf8))

        // 여러 @concurrent parseJSON() 호출을 동시에 실행
        async let result1: YFQuoteBasicInfo = try core.parseJSON(data: data, type: YFQuoteBasicInfo.self)
        async let result2: YFQuoteBasicInfo = try core.parseJSON(data: data, type: YFQuoteBasicInfo.self)
        async let result3: YFQuoteBasicInfo = try core.parseJSON(data: data, type: YFQuoteBasicInfo.self)

        let (r1, r2, r3) = try await (result1, result2, result3)

        #expect(r1.symbol == "AMZN")
        #expect(r2.symbol == "AMZN")
        #expect(r3.symbol == "AMZN")
    }

    @Test("parseJSON() — 다른 타입을 동시에 파싱해도 안전")
    func testParseJSONDifferentTypesConcurrently() async throws {
        let basicInfoJSON = """
            {"symbol": "TSLA", "longName": "Tesla, Inc."}
            """
        let quoteResponseJSON = """
            {
                "quoteResponse": {
                    "result": [],
                    "error": null
                }
            }
            """
        let basicInfoData = try #require(basicInfoJSON.data(using: .utf8))
        let quoteResponseData = try #require(quoteResponseJSON.data(using: .utf8))

        // 서로 다른 타입을 동시에 @concurrent 파싱
        async let basicInfo: YFQuoteBasicInfo = try core.parseJSON(data: basicInfoData, type: YFQuoteBasicInfo.self)
        async let quoteResponse: YFQuoteResponse = try core.parseJSON(data: quoteResponseData, type: YFQuoteResponse.self)

        let (b, q) = try await (basicInfo, quoteResponse)

        #expect(b.symbol == "TSLA")
        #expect(q.result?.isEmpty == true)
    }
}
