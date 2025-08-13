import Testing
import Foundation
@testable import SwiftYFinance

struct ErrorParsingTests {
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
    
    @Test
    func testParseErrorResponse() throws {
        let parser = YFResponseParser()
        
        // Test 1: Invalid symbol error (YFTickerMissingError 유형)
        let invalidSymbolJSON = """
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
        
        let invalidSymbolError = try parser.parseError(invalidSymbolJSON)
        #expect(invalidSymbolError != nil)
        #expect(invalidSymbolError!.code == "Not Found")
        #expect(invalidSymbolError!.description == "No data found, symbol may be delisted")
        
        // Test 2: Rate limit error (YFRateLimitError 유형)
        let rateLimitJSON = """
        {
            "chart": {
                "result": null,
                "error": {
                    "code": "Too Many Requests",
                    "description": "Rate limited. Try after a while."
                }
            }
        }
        """.data(using: .utf8)!
        
        let rateLimitError = try parser.parseError(rateLimitJSON)
        #expect(rateLimitError != nil)
        #expect(rateLimitError!.code == "Too Many Requests")
        #expect(rateLimitError!.description?.contains("Rate limited") == true)
        
        // Test 3: Invalid period error (YFInvalidPeriodError 유형)
        let invalidPeriodJSON = """
        {
            "chart": {
                "result": null,
                "error": {
                    "code": "Bad Request",
                    "description": "Invalid period '999d'. Valid periods are: 1d,5d,1mo,3mo,6mo,1y,2y,5y,10y,ytd,max"
                }
            }
        }
        """.data(using: .utf8)!
        
        let invalidPeriodError = try parser.parseError(invalidPeriodJSON)
        #expect(invalidPeriodError != nil)
        #expect(invalidPeriodError!.code == "Bad Request")
        #expect(invalidPeriodError!.description?.contains("Invalid period") == true)
        #expect(invalidPeriodError!.description?.contains("Valid periods") == true)
        
        // Test 4: Server error
        let serverErrorJSON = """
        {
            "chart": {
                "result": null,
                "error": {
                    "code": "Internal Server Error",
                    "description": "Yahoo Finance service temporarily unavailable"
                }
            }
        }
        """.data(using: .utf8)!
        
        let serverError = try parser.parseError(serverErrorJSON)
        #expect(serverError != nil)
        #expect(serverError!.code == "Internal Server Error")
        #expect(serverError!.description == "Yahoo Finance service temporarily unavailable")
        
        // Test 5: Missing description field
        let noDescriptionJSON = """
        {
            "chart": {
                "result": null,
                "error": {
                    "code": "Unknown Error"
                }
            }
        }
        """.data(using: .utf8)!
        
        let noDescriptionError = try parser.parseError(noDescriptionJSON)
        #expect(noDescriptionError != nil)
        #expect(noDescriptionError!.code == "Unknown Error")
        #expect(noDescriptionError!.description == nil)
        
        // Test 6: Valid response (no error)
        let validResponseJSON = """
        {
            "chart": {
                "result": [{"meta": {"symbol": "AAPL"}}],
                "error": null
            }
        }
        """.data(using: .utf8)!
        
        let noError = try parser.parseError(validResponseJSON)
        #expect(noError == nil)
        
        // Test 7: Malformed response (missing chart)
        let malformedJSON = """
        {
            "notChart": {
                "result": null
            }
        }
        """.data(using: .utf8)!
        
        let malformedError = try parser.parseError(malformedJSON)
        #expect(malformedError == nil)
        
        // Test 8: Empty error object (디코딩 실패 시 nil 반환)
        let emptyErrorJSON = """
        {
            "chart": {
                "result": null,
                "error": {}
            }
        }
        """.data(using: .utf8)!
        
        let emptyError = try parser.parseError(emptyErrorJSON)
        #expect(emptyError == nil)
    }
}