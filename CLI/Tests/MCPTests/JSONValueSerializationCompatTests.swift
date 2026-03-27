/// JSONValue + JSONSerialization 호환성 검증 테스트
///
/// 검증 전략:
/// (a) JSONSerialization.jsonObject로 직접 파싱한 Foundation 객체
/// (b) JSONDecoder로 JSONValue 파싱 후 toJSONObject()로 변환한 객체
/// 두 결과를 JSONSerialization.data로 재직렬화 후 재파싱하여 NSDictionary/NSArray 레벨 비교
///
/// 픽스처: Yahoo Finance API 응답 모양의 실제 JSON 구조 10개 이상

import Testing
import Foundation
@testable import SwiftYFinanceMCP

// MARK: - 헬퍼

/// 두 Any 객체의 의미적 동등성 검증 (재직렬화 후 비교)
///
/// 딕셔너리 키 순서가 비결정적이므로 바이트 비교 대신
/// NSObject 레벨 equatable 비교를 사용합니다.
private func semanticEqual(_ a: Any, _ b: Any) -> Bool {
    // NSNull
    if a is NSNull, b is NSNull { return true }
    // NSNumber (Bool, Int, Double 공통)
    if let na = a as? NSNumber, let nb = b as? NSNumber {
        return na.isEqual(nb)
    }
    // NSString
    if let sa = a as? String, let sb = b as? String {
        return sa == sb
    }
    // Array
    if let aa = a as? [Any], let ab = b as? [Any] {
        guard aa.count == ab.count else { return false }
        return zip(aa, ab).allSatisfy { semanticEqual($0.0, $0.1) }
    }
    // Dictionary
    if let da = a as? [String: Any], let db = b as? [String: Any] {
        guard da.keys.sorted() == db.keys.sorted() else { return false }
        return da.keys.allSatisfy { key in
            guard let va = da[key], let vb = db[key] else { return false }
            return semanticEqual(va, vb)
        }
    }
    return false
}

/// JSONSerialization 경유 파싱
private func parseViaJSONSerialization(_ json: String) throws -> Any {
    let data = json.data(using: .utf8)!
    return try JSONSerialization.jsonObject(with: data, options: [])
}

/// JSONDecoder → JSONValue → toJSONObject() 경유 파싱
private func parseViaJSONValue(_ json: String) throws -> Any {
    let data = json.data(using: .utf8)!
    let jsonValue = try JSONDecoder().decode(JSONValue.self, from: data)
    return jsonValue.toJSONObject()
}

// MARK: - 픽스처 데이터

/// Yahoo Finance 시세 응답 픽스처
private let quoteResponseJSON = """
{
  "quoteResponse": {
    "result": [
      {
        "symbol": "AAPL",
        "shortName": "Apple Inc.",
        "regularMarketPrice": 189.95,
        "regularMarketChange": 2.35,
        "regularMarketChangePercent": 1.2525,
        "regularMarketVolume": 58234100,
        "marketCap": 2940000000000,
        "fiftyTwoWeekHigh": 199.62,
        "fiftyTwoWeekLow": 124.17,
        "trailingPE": 30.21
      }
    ],
    "error": null
  }
}
"""

/// Yahoo Finance 검색 응답 픽스처
private let searchResponseJSON = """
{
  "quotes": [
    {
      "exchange": "NMS",
      "shortname": "Apple Inc.",
      "quoteType": "EQUITY",
      "symbol": "AAPL",
      "index": "quotes",
      "score": 1831380.0,
      "typeDisp": "Equity",
      "longname": "Apple Inc.",
      "isYahooFinance": true
    },
    {
      "exchange": "NMS",
      "shortname": "Microsoft Corporation",
      "quoteType": "EQUITY",
      "symbol": "MSFT",
      "index": "quotes",
      "score": 1590000.0,
      "typeDisp": "Equity",
      "longname": "Microsoft Corporation",
      "isYahooFinance": true
    }
  ],
  "count": 2
}
"""

/// Yahoo Finance 차트 응답 픽스처
private let chartResponseJSON = """
{
  "chart": {
    "result": [
      {
        "meta": {
          "currency": "USD",
          "symbol": "AAPL",
          "exchangeName": "NMS",
          "instrumentType": "EQUITY",
          "firstTradeDate": 345479400,
          "regularMarketTime": 1705003200,
          "gmtoffset": -18000,
          "timezone": "EST",
          "exchangeTimezoneName": "America/New_York",
          "regularMarketPrice": 189.95,
          "chartPreviousClose": 187.60
        },
        "timestamp": [1704931800, 1704935400, 1704939000],
        "indicators": {
          "quote": [
            {
              "open": [187.15, 188.45, 189.00],
              "high": [189.20, 190.00, 190.50],
              "low": [186.50, 187.80, 188.20],
              "close": [188.45, 189.00, 189.95],
              "volume": [15234100, 12456700, 9876500]
            }
          ]
        }
      }
    ],
    "error": null
  }
}
"""

/// Yahoo Finance 뉴스 픽스처
private let newsResponseJSON = """
{
  "items": {
    "result": [
      {
        "uuid": "abc123",
        "title": "Apple Reports Record Q4 Earnings",
        "publisher": "Reuters",
        "link": "https://finance.yahoo.com/news/apple-q4-2024",
        "providerPublishTime": 1705003200,
        "type": "STORY",
        "relatedTickers": ["AAPL", "SPY"]
      }
    ]
  }
}
"""

/// Yahoo Finance 옵션 체인 픽스처
private let optionsResponseJSON = """
{
  "optionChain": {
    "result": [
      {
        "underlyingSymbol": "AAPL",
        "expirationDates": [1705968000, 1708560000],
        "strikes": [170.0, 175.0, 180.0, 185.0, 190.0],
        "hasMiniOptions": false,
        "options": [
          {
            "expirationDate": 1705968000,
            "hasMiniOptions": false,
            "calls": [
              {
                "contractSymbol": "AAPL240123C00190000",
                "strike": 190.0,
                "currency": "USD",
                "lastPrice": 2.45,
                "change": 0.35,
                "percentChange": 16.67,
                "volume": 1234,
                "openInterest": 5678,
                "bid": 2.40,
                "ask": 2.50,
                "impliedVolatility": 0.2845
              }
            ],
            "puts": []
          }
        ]
      }
    ],
    "error": null
  }
}
"""

/// Yahoo Finance 스크리너 응답 픽스처
private let screenerResponseJSON = """
{
  "finance": {
    "result": [
      {
        "start": 0,
        "count": 3,
        "total": 3,
        "quotes": [
          {
            "language": "en-US",
            "region": "US",
            "quoteType": "EQUITY",
            "typeDisp": "Equity",
            "quoteSourceName": "Nasdaq Real Time Price",
            "triggerable": false,
            "customPriceAlertConfidence": "NONE",
            "symbol": "NVDA",
            "shortName": "NVIDIA Corporation",
            "marketCap": 1200000000000
          }
        ]
      }
    ],
    "error": null
  }
}
"""

/// Yahoo Finance QuoteSummary 재무제표 픽스처
private let quoteSummaryJSON = """
{
  "quoteSummary": {
    "result": [
      {
        "balanceSheetHistory": {
          "balanceSheetStatements": [
            {
              "maxAge": 1,
              "endDate": {"raw": 1696118400, "fmt": "2023-10-01"},
              "totalAssets": {"raw": 352755000000, "fmt": "352.755B"},
              "totalLiab": {"raw": 290437000000, "fmt": "290.437B"},
              "totalStockholderEquity": {"raw": 62146000000, "fmt": "62.146B"}
            }
          ]
        }
      }
    ],
    "error": null
  }
}
"""

/// 중첩 null 값 포함 픽스처
private let nestedNullsJSON = """
{
  "data": {
    "field1": null,
    "field2": {
      "nested": null,
      "value": 42
    },
    "field3": [null, "string", null, 123]
  }
}
"""

/// 혼합 숫자 타입 픽스처 (Int/Double/Bool 혼재)
private let mixedNumericTypesJSON = """
{
  "intField": 42,
  "doubleField": 3.14159,
  "boolTrue": true,
  "boolFalse": false,
  "largeInt": 9007199254740992,
  "negativeInt": -12345,
  "smallDouble": 0.000001,
  "zeroInt": 0,
  "zeroDouble": 0.0
}
"""

/// 유니코드 + 특수문자 픽스처
private let unicodeSpecialCharsJSON = """
{
  "korean": "주식 시장",
  "japanese": "株式市場",
  "emoji": "📈📉",
  "escaped": "line1\\nline2",
  "tab": "col1\\tcol2",
  "quote": "say \\"hello\\"",
  "backslash": "path\\\\to\\\\file",
  "url": "https://finance.yahoo.com/quote/AAPL?p=AAPL&.tsrc=fin-srch"
}
"""

/// 빈 배열/객체 혼합 픽스처
private let emptyStructuresJSON = """
{
  "emptyArray": [],
  "emptyObject": {},
  "arrayWithEmpty": [[], {}, null],
  "objectWithEmpty": {
    "arr": [],
    "obj": {}
  }
}
"""

/// 매우 긴 문자열 배열 픽스처
private let longStringArrayJSON: String = {
    let tickers = (0..<50).map { "TICK\($0)" }
    let jsonArray = tickers.map { "\"\($0)\"" }.joined(separator: ", ")
    return "{\"tickers\": [\(jsonArray)], \"count\": 50}"
}()

// MARK: - 테스트 스위트

@Suite("JSONValue + JSONSerialization 호환성")
struct JSONValueSerializationCompatTests {

    // MARK: - 기본 호환성 검증

    @Test("시세 응답 픽스처 — JSONSerialization vs JSONValue 의미적 동등성")
    func quoteResponseCompatibility() throws {
        let direct = try parseViaJSONSerialization(quoteResponseJSON)
        let viaJSONValue = try parseViaJSONValue(quoteResponseJSON)
        #expect(semanticEqual(direct, viaJSONValue), "시세 응답: JSONSerialization과 JSONValue 경유 결과가 다릅니다")
    }

    @Test("검색 응답 픽스처 — 배열 원소 의미적 동등성")
    func searchResponseCompatibility() throws {
        let direct = try parseViaJSONSerialization(searchResponseJSON)
        let viaJSONValue = try parseViaJSONValue(searchResponseJSON)
        #expect(semanticEqual(direct, viaJSONValue), "검색 응답: JSONSerialization과 JSONValue 경유 결과가 다릅니다")
    }

    @Test("차트 응답 픽스처 — 중첩 구조 의미적 동등성")
    func chartResponseCompatibility() throws {
        let direct = try parseViaJSONSerialization(chartResponseJSON)
        let viaJSONValue = try parseViaJSONValue(chartResponseJSON)
        #expect(semanticEqual(direct, viaJSONValue), "차트 응답: JSONSerialization과 JSONValue 경유 결과가 다릅니다")
    }

    @Test("뉴스 응답 픽스처 — 배열 내 문자열 의미적 동등성")
    func newsResponseCompatibility() throws {
        let direct = try parseViaJSONSerialization(newsResponseJSON)
        let viaJSONValue = try parseViaJSONValue(newsResponseJSON)
        #expect(semanticEqual(direct, viaJSONValue), "뉴스 응답: JSONSerialization과 JSONValue 경유 결과가 다릅니다")
    }

    @Test("옵션 체인 픽스처 — 복잡한 중첩 구조 의미적 동등성")
    func optionsResponseCompatibility() throws {
        let direct = try parseViaJSONSerialization(optionsResponseJSON)
        let viaJSONValue = try parseViaJSONValue(optionsResponseJSON)
        #expect(semanticEqual(direct, viaJSONValue), "옵션 체인: JSONSerialization과 JSONValue 경유 결과가 다릅니다")
    }

    @Test("스크리너 응답 픽스처 — 의미적 동등성")
    func screenerResponseCompatibility() throws {
        let direct = try parseViaJSONSerialization(screenerResponseJSON)
        let viaJSONValue = try parseViaJSONValue(screenerResponseJSON)
        #expect(semanticEqual(direct, viaJSONValue), "스크리너: JSONSerialization과 JSONValue 경유 결과가 다릅니다")
    }

    @Test("QuoteSummary 재무제표 픽스처 — 의미적 동등성")
    func quoteSummaryCompatibility() throws {
        let direct = try parseViaJSONSerialization(quoteSummaryJSON)
        let viaJSONValue = try parseViaJSONValue(quoteSummaryJSON)
        #expect(semanticEqual(direct, viaJSONValue), "QuoteSummary: JSONSerialization과 JSONValue 경유 결과가 다릅니다")
    }

    @Test("중첩 null 픽스처 — null 처리 호환성")
    func nestedNullsCompatibility() throws {
        let direct = try parseViaJSONSerialization(nestedNullsJSON)
        let viaJSONValue = try parseViaJSONValue(nestedNullsJSON)
        #expect(semanticEqual(direct, viaJSONValue), "중첩 null: JSONSerialization과 JSONValue 경유 결과가 다릅니다")
    }

    @Test("혼합 숫자 타입 픽스처 — Bool/Int/Double 구별 호환성")
    func mixedNumericTypesCompatibility() throws {
        let direct = try parseViaJSONSerialization(mixedNumericTypesJSON)
        let viaJSONValue = try parseViaJSONValue(mixedNumericTypesJSON)
        #expect(semanticEqual(direct, viaJSONValue), "혼합 숫자: JSONSerialization과 JSONValue 경유 결과가 다릅니다")
    }

    @Test("유니코드 + 특수문자 픽스처 — 문자열 호환성")
    func unicodeSpecialCharsCompatibility() throws {
        let direct = try parseViaJSONSerialization(unicodeSpecialCharsJSON)
        let viaJSONValue = try parseViaJSONValue(unicodeSpecialCharsJSON)
        #expect(semanticEqual(direct, viaJSONValue), "유니코드: JSONSerialization과 JSONValue 경유 결과가 다릅니다")
    }

    @Test("빈 구조체 혼합 픽스처 — 빈 배열/객체 호환성")
    func emptyStructuresCompatibility() throws {
        let direct = try parseViaJSONSerialization(emptyStructuresJSON)
        let viaJSONValue = try parseViaJSONValue(emptyStructuresJSON)
        #expect(semanticEqual(direct, viaJSONValue), "빈 구조체: JSONSerialization과 JSONValue 경유 결과가 다릅니다")
    }

    @Test("50개 티커 배열 픽스처 — 의미적 동등성")
    func longStringArrayCompatibility() throws {
        let direct = try parseViaJSONSerialization(longStringArrayJSON)
        let viaJSONValue = try parseViaJSONValue(longStringArrayJSON)
        #expect(semanticEqual(direct, viaJSONValue), "긴 배열: JSONSerialization과 JSONValue 경유 결과가 다릅니다")
    }

    // MARK: - 재직렬화 round-trip 검증

    @Test("시세 응답 — JSONValue 경유 재직렬화 후 재파싱 동등성")
    func quoteResponseReserializeRoundTrip() throws {
        let jsonData = quoteResponseJSON.data(using: .utf8)!

        // JSONValue 파싱 → 재직렬화
        let jsonValue = try JSONDecoder().decode(JSONValue.self, from: jsonData)
        let reserializedData = try JSONSerialization.data(withJSONObject: jsonValue.toJSONObject())

        // 재직렬화 결과를 다시 JSONValue로 파싱
        let reparsed = try JSONDecoder().decode(JSONValue.self, from: reserializedData)

        // 원본 JSONValue와 동등해야 함
        #expect(jsonValue == reparsed, "재직렬화 round-trip 후 JSONValue 동등성 실패")
    }

    @Test("차트 응답 — JSONValue 재직렬화 후 특정 필드 검증")
    func chartResponseFieldValidation() throws {
        let data = chartResponseJSON.data(using: .utf8)!
        let jsonValue = try JSONDecoder().decode(JSONValue.self, from: data)

        // 중첩 접근: chart.result[0].meta.symbol
        let symbol = jsonValue["chart"]?["result"]?[0]?["meta"]?["symbol"]?.stringValue
        #expect(symbol == "AAPL", "chart.result[0].meta.symbol은 'AAPL'이어야 합니다")

        // 중첩 배열 접근: chart.result[0].timestamp
        let timestamps = jsonValue["chart"]?["result"]?[0]?["timestamp"]?.arrayValue
        #expect(timestamps?.count == 3, "timestamp 배열은 3개 원소여야 합니다")
    }

    @Test("혼합 숫자 타입 — Bool이 Int로 오파싱되지 않음")
    func mixedNumericsBoolNotMistaken() throws {
        let data = mixedNumericTypesJSON.data(using: .utf8)!
        let jsonValue = try JSONDecoder().decode(JSONValue.self, from: data)

        // true/false는 .bool이어야 함
        if case .bool(let b) = jsonValue["boolTrue"] {
            #expect(b == true, "boolTrue는 true여야 합니다")
        } else {
            Issue.record("boolTrue가 .bool로 파싱되지 않았습니다: \(String(describing: jsonValue["boolTrue"]))")
        }

        // 42는 .int여야 함 (Double이 아님)
        if case .int(let i) = jsonValue["intField"] {
            #expect(i == 42, "intField는 42여야 합니다")
        } else {
            Issue.record("intField가 .int로 파싱되지 않았습니다: \(String(describing: jsonValue["intField"]))")
        }

        // 3.14159는 .number여야 함
        if case .number(let d) = jsonValue["doubleField"] {
            #expect(abs(d - 3.14159) < 0.00001, "doubleField는 3.14159여야 합니다")
        } else {
            Issue.record("doubleField가 .number로 파싱되지 않았습니다: \(String(describing: jsonValue["doubleField"]))")
        }
    }

    @Test("뉴스 응답 — 관련 티커 배열 접근")
    func newsResponseTickerArrayAccess() throws {
        let data = newsResponseJSON.data(using: .utf8)!
        let jsonValue = try JSONDecoder().decode(JSONValue.self, from: data)

        let tickers = jsonValue["items"]?["result"]?[0]?["relatedTickers"]?.arrayValue?
            .compactMap { $0.stringValue }
        #expect(tickers?.count == 2, "relatedTickers는 2개여야 합니다")
        #expect(tickers?.contains("AAPL") == true, "AAPL이 tickers에 포함되어야 합니다")
        #expect(tickers?.contains("SPY") == true, "SPY가 tickers에 포함되어야 합니다")
    }
}
