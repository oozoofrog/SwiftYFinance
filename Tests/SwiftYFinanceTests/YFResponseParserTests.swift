import Testing
import Foundation
@testable import SwiftYFinance

struct YFResponseParserTests {
    @Test
    func testResponseParserValidJSON() throws {
        let parser = YFResponseParser()
        
        let jsonData = """
        {
            "chart": {
                "result": [{
                    "meta": {
                        "symbol": "AAPL",
                        "regularMarketPrice": 150.25,
                        "regularMarketTime": 1234567890
                    },
                    "indicators": {
                        "quote": [{
                            "open": [149.0, 150.0],
                            "high": [151.0, 152.0],
                            "low": [148.0, 149.0],
                            "close": [150.0, 151.0],
                            "volume": [1000000, 1100000]
                        }]
                    }
                }]
            }
        }
        """.data(using: .utf8)!
        
        let result = try parser.parse(jsonData, type: ChartResponse.self)
        
        #expect(result.chart.result.count == 1)
        #expect(result.chart.result[0].meta.symbol == "AAPL")
        #expect(result.chart.result[0].meta.regularMarketPrice == 150.25)
        
        let quotes = result.chart.result[0].indicators.quote[0]
        #expect(quotes.open.count == 2)
        #expect(quotes.open[0] == 149.0)
    }
    
    @Test
    func testResponseParserInvalidJSON() throws {
        let parser = YFResponseParser()
        
        let invalidJSON1 = "not json at all".data(using: .utf8)!
        #expect(throws: YFError.parsingError) {
            _ = try parser.parse(invalidJSON1, type: ChartResponse.self)
        }
        
        let invalidJSON2 = """
        {
            "chart": {
                "missing_closing_bracket": true
        }
        """.data(using: .utf8)!
        #expect(throws: YFError.parsingError) {
            _ = try parser.parse(invalidJSON2, type: ChartResponse.self)
        }
        
        let wrongStructureJSON = """
        {
            "wrong": "structure",
            "no": "chart"
        }
        """.data(using: .utf8)!
        #expect(throws: YFError.parsingError) {
            _ = try parser.parse(wrongStructureJSON, type: ChartResponse.self)
        }
        
        let emptyData = Data()
        #expect(throws: YFError.parsingError) {
            _ = try parser.parse(emptyData, type: ChartResponse.self)
        }
    }
    
    @Test
    func testResponseParserErrorHandling() throws {
        let parser = YFResponseParser()
        
        // Test Yahoo Finance error response
        let errorResponseJSON = """
        {
            "chart": {
                "result": null,
                "error": {
                    "code": "Not Found",
                    "description": "No data found, symbol may be delisted"
                }
            }
        }
        """.data(using: .utf8)!
        
        let errorResult = try parser.parseError(errorResponseJSON)
        #expect(errorResult?.code == "Not Found")
        #expect(errorResult?.description?.contains("delisted") == true)
        
        // Test response without error
        let validResponseJSON = """
        {
            "chart": {
                "result": [{"meta": {"symbol": "AAPL"}}]
            }
        }
        """.data(using: .utf8)!
        
        let noError = try parser.parseError(validResponseJSON)
        #expect(noError == nil)
        
        // Test malformed error response
        let malformedErrorJSON = """
        {
            "something": "else"
        }
        """.data(using: .utf8)!
        
        let malformedError = try parser.parseError(malformedErrorJSON)
        #expect(malformedError == nil)
    }
}

struct ChartResponse: Codable {
    let chart: Chart
}

struct Chart: Codable {
    let result: [ChartResult]
}

struct ChartResult: Codable {
    let meta: Meta
    let indicators: Indicators
}

struct Meta: Codable {
    let symbol: String
    let regularMarketPrice: Double
    let regularMarketTime: Int
}

struct Indicators: Codable {
    let quote: [Quote]
}

struct Quote: Codable {
    let open: [Double]
    let high: [Double]
    let low: [Double]
    let close: [Double]
    let volume: [Int]
}