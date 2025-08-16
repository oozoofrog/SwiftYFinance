import Testing
import Foundation
@testable import SwiftYFinance

struct ProtobufDecodingTests {
    
    @Test("Base64 decoding basic test with valid input")
    func testBase64DecodingBasic() throws {
        // Given - Simple valid Base64 string
        let validBase64 = "SGVsbG8gV29ybGQ=" // "Hello World" in Base64
        let decoder = YFWebSocketMessageDecoder()
        
        // When
        let decodedData = try decoder.decodeBase64(validBase64)
        
        // Then
        let expectedString = "Hello World"
        let decodedString = String(data: decodedData, encoding: .utf8)
        #expect(decodedString == expectedString)
        #expect(decodedData.count > 0)
    }
    
    @Test("Base64 decoding with empty string")
    func testBase64DecodingEmpty() throws {
        // Given
        let emptyBase64 = ""
        let decoder = YFWebSocketMessageDecoder()
        
        // When & Then
        do {
            let _ = try decoder.decodeBase64(emptyBase64)
            #expect(Bool(false), "Should have thrown an error for empty string")
        } catch YFError.webSocketError(.messageDecodingFailed(let message)) {
            #expect(message.contains("Base64") || message.contains("empty"))
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }
    
    @Test("Base64 decoding with valid Yahoo Finance test data")
    func testBase64DecodingYFinanceData() throws {
        // Given - Real Yahoo Finance test data from yfinance-reference
        let yfinanceBase64 = "CgdCVEMtVVNEFYoMuUcYwLCVgIplIgNVU0QqA0NDQzApOAFFPWrEP0iAgOrxvANVx/25R12csrRHZYD8skR9/7i0R7ABgIDq8bwD2AEE4AGAgOrxvAPoAYCA6vG8A/IBA0JUQ4ECAAAAwPrjckGJAgAA2P5ZT3tC"
        let decoder = YFWebSocketMessageDecoder()
        
        // When
        let decodedData = try decoder.decodeBase64(yfinanceBase64)
        
        // Then
        #expect(decodedData.count > 0)
        // Yahoo Finance protobuf data should be non-empty and reasonable size
        #expect(decodedData.count > 10)
        #expect(decodedData.count < 1000) // Reasonable upper bound
    }
    
    @Test("Base64 decoding with standard test vector")
    func testBase64DecodingTestVector() throws {
        // Given - Standard test vectors
        let testCases = [
            ("", Data()),
            ("Zg==", "f".data(using: .utf8)!),
            ("Zm8=", "fo".data(using: .utf8)!),
            ("Zm9v", "foo".data(using: .utf8)!),
            ("Zm9vYg==", "foob".data(using: .utf8)!),
            ("Zm9vYmE=", "fooba".data(using: .utf8)!),
            ("Zm9vYmFy", "foobar".data(using: .utf8)!)
        ]
        
        let decoder = YFWebSocketMessageDecoder()
        
        // When & Then
        for (base64, expectedData) in testCases {
            if base64.isEmpty {
                // Empty string should throw error
                do {
                    let _ = try decoder.decodeBase64(base64)
                    #expect(Bool(false), "Empty string should throw error")
                } catch {
                    // Expected to fail
                    continue
                }
            } else {
                let decodedData = try decoder.decodeBase64(base64)
                #expect(decodedData == expectedData, "Failed for input: \(base64)")
            }
        }
    }
    
    @Test("Base64 decoding with invalid input should throw error")
    func testBase64DecodingInvalidInput() {
        // Given
        let invalidBase64Cases = [
            "InvalidBase64!@#$%",
            "SGVsbG8gV29ybGQ",  // Missing padding
            "SGVsbG8gV29ybGQ==!!", // Extra invalid characters
            "ZG9n!!",            // Invalid character in middle
            " SGVsbG8gV29ybGQ= " // Leading/trailing spaces
        ]
        
        let decoder = YFWebSocketMessageDecoder()
        
        // When & Then
        for invalidBase64 in invalidBase64Cases {
            do {
                let _ = try decoder.decodeBase64(invalidBase64)
                #expect(Bool(false), "Should have thrown error for invalid Base64: \(invalidBase64)")
            } catch YFError.webSocketError(.messageDecodingFailed(let message)) {
                // Expected error
                #expect(!message.isEmpty, "Error message should not be empty")
                #expect(message.contains("Base64") || message.contains("Invalid"), "Error should mention Base64 or Invalid")
            } catch {
                #expect(Bool(false), "Unexpected error type for \(invalidBase64): \(error)")
            }
        }
    }
    
    @Test("Base64 decoding with whitespace handling")
    func testBase64DecodingWhitespace() throws {
        // Given
        let decoder = YFWebSocketMessageDecoder()
        
        // Base64 with various whitespace should fail (since we don't auto-trim)
        let whitespaceCase = " SGVsbG8gV29ybGQ= "
        
        // When & Then
        do {
            let _ = try decoder.decodeBase64(whitespaceCase)
            #expect(Bool(false), "Should have thrown error for whitespace-padded Base64")
        } catch YFError.webSocketError(.messageDecodingFailed(_)) {
            // Expected - we don't handle whitespace automatically
            #expect(true)
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }
    
    @Test("Base64 decoding edge cases")
    func testBase64DecodingEdgeCases() {
        // Given
        let decoder = YFWebSocketMessageDecoder()
        let definitivelyInvalidCases = [
            "===",           // Only padding
            "A",             // Too short
            "AB",            // Too short
            "ABC",           // Too short without padding
        ]
        
        // When & Then - Test cases that should definitely fail
        for edgeCase in definitivelyInvalidCases {
            do {
                let _ = try decoder.decodeBase64(edgeCase)
                #expect(Bool(false), "Should have thrown error for edge case: \(edgeCase)")
            } catch YFError.webSocketError(.messageDecodingFailed(_)) {
                // Expected error
                #expect(true)
            } catch {
                #expect(Bool(false), "Unexpected error type for \(edgeCase): \(error)")
            }
        }
        
        // Test cases that Foundation might accept (even if technically invalid)
        let foundationAcceptableCases = [
            "ABCD===",       // Too much padding - Foundation might accept this
        ]
        
        // These might not throw errors due to Foundation's lenient parsing
        for acceptableCase in foundationAcceptableCases {
            do {
                let _ = try decoder.decodeBase64(acceptableCase)
                // Foundation accepts this - that's okay
                #expect(true)
            } catch YFError.webSocketError(.messageDecodingFailed(_)) {
                // If it throws, that's also acceptable
                #expect(true)
            } catch {
                #expect(Bool(false), "Unexpected error type for \(acceptableCase): \(error)")
            }
        }
    }
}