import Testing
import Foundation
@testable import SwiftYFinance

/// YFResponseParser.parse() @concurrent 함수 직접 단위 테스트
///
/// YFResponseParser.parse()는 @concurrent async throws 함수입니다.
/// CPU-bound JSON 파싱이 concurrent thread pool에서 올바르게 실행되는지 검증합니다.
@Suite("YFResponseParser 단위 테스트 - @concurrent parse() 직접 검증")
struct YFResponseParserTests {

    // MARK: - 테스트 픽스처

    let parser = YFResponseParser()

    /// YFQuoteResponse 파싱을 위한 단순 JSON
    static let validQuoteResponseJSON = """
        {
            "quoteResponse": {
                "result": [{
                    "symbol": "AAPL",
                    "longName": "Apple Inc.",
                    "shortName": "Apple",
                    "quoteType": "EQUITY",
                    "regularMarketPrice": 175.50,
                    "regularMarketVolume": 60000000,
                    "marketCap": 2700000000000,
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

    /// 잘못된 형식의 JSON (파싱 실패 유도)
    static let invalidJSON = "{ invalid json }"

    /// 빈 JSON 객체
    static let emptyObjectJSON = "{}"

    // MARK: - 정상 파싱 테스트

    @Test("parse() — 유효한 JSON을 YFQuoteResponse로 파싱")
    func testParseValidQuoteResponse() async throws {
        let data = try #require(Self.validQuoteResponseJSON.data(using: .utf8))

        // @concurrent parse() 직접 await 호출
        let response: YFQuoteResponse = try await parser.parse(data, type: YFQuoteResponse.self)

        let results = try #require(response.result)
        #expect(results.count == 1)
        #expect(results.first?.basicInfo.symbol == "AAPL")
        #expect(results.first?.basicInfo.longName == "Apple Inc.")
    }

    @Test("parse() — YFQuoteBasicInfo 단일 모델 파싱")
    func testParseBasicInfo() async throws {
        let json = """
            {
                "symbol": "MSFT",
                "longName": "Microsoft Corporation",
                "shortName": "Microsoft",
                "quoteType": "EQUITY"
            }
            """
        let data = try #require(json.data(using: .utf8))

        // @concurrent parse() 직접 await 호출
        let basicInfo: YFQuoteBasicInfo = try await parser.parse(data, type: YFQuoteBasicInfo.self)

        #expect(basicInfo.symbol == "MSFT")
        #expect(basicInfo.longName == "Microsoft Corporation")
        #expect(basicInfo.quoteType == "EQUITY")
    }

    // MARK: - 에러 처리 테스트

    @Test("parse() — 잘못된 JSON 입력 시 YFError.parsingError throw")
    func testParseInvalidJSONThrowsParsingError() async throws {
        let data = try #require(Self.invalidJSON.data(using: .utf8))

        do {
            _ = try await parser.parse(data, type: YFQuoteResponse.self)
            #expect(false, "파싱 에러가 발생해야 함")
        } catch let error as YFError {
            if case .parsingError = error {
                // 예상된 에러
            } else {
                #expect(false, "YFError.parsingError가 아닌 다른 에러: \(error)")
            }
        }
    }

    @Test("parse() — 타입 불일치 시 parsingError throw")
    func testParseTypeMismatchThrowsParsingError() async throws {
        // 배열 JSON을 단일 객체 타입으로 파싱 시도
        let arrayJSON = "[1, 2, 3]"
        let data = try #require(arrayJSON.data(using: .utf8))

        do {
            _ = try await parser.parse(data, type: YFQuoteBasicInfo.self)
            #expect(false, "타입 불일치 에러가 발생해야 함")
        } catch let error as YFError {
            if case .parsingError = error {
                // 예상된 에러
            } else {
                #expect(false, "YFError.parsingError가 아닌 다른 에러: \(error)")
            }
        }
    }

    // MARK: - @concurrent 동작 검증

    @Test("parse() — 병렬 호출 시 데이터 레이스 없이 정상 동작")
    func testParseConcurrentCallsNodataRace() async throws {
        let data = try #require("""
            {"symbol": "TEST", "longName": "Test Corp"}
            """.data(using: .utf8))

        // 여러 @concurrent parse() 호출을 동시에 실행
        async let result1: YFQuoteBasicInfo = try parser.parse(data, type: YFQuoteBasicInfo.self)
        async let result2: YFQuoteBasicInfo = try parser.parse(data, type: YFQuoteBasicInfo.self)
        async let result3: YFQuoteBasicInfo = try parser.parse(data, type: YFQuoteBasicInfo.self)

        let (r1, r2, r3) = try await (result1, result2, result3)

        #expect(r1.symbol == "TEST")
        #expect(r2.symbol == "TEST")
        #expect(r3.symbol == "TEST")
    }

    // MARK: - parseError() 테스트

    @Test("parseError() — Yahoo Finance 에러 응답 파싱")
    func testParseError() throws {
        let errorJSON = """
            {
                "chart": {
                    "error": {
                        "code": "Not Found",
                        "description": "No data found for symbol INVALID"
                    }
                }
            }
            """
        let data = try #require(errorJSON.data(using: .utf8))

        let errorResponse = try parser.parseError(data)

        let unwrapped = try #require(errorResponse)
        #expect(unwrapped.code == "Not Found")
        #expect(unwrapped.description == "No data found for symbol INVALID")
    }

    @Test("parseError() — 에러 없는 응답 파싱 시 nil 반환")
    func testParseErrorReturnsNilForNonErrorResponse() throws {
        let data = try #require(Self.validQuoteResponseJSON.data(using: .utf8))

        // 에러 형식이 아닌 JSON은 nil 반환
        let errorResponse = try parser.parseError(data)
        #expect(errorResponse == nil)
    }
}
