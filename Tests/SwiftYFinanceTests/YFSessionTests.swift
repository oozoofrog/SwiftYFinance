import Testing
import Foundation
@testable import SwiftYFinance

struct YFSessionTests {
    @Test
    func testSessionInit() {
        let session = YFSession()
        
        #expect(session.baseURL.absoluteString == "https://query1.finance.yahoo.com")
        #expect(session.timeout == 30.0)
        
        let customSession = YFSession(
            baseURL: URL(string: "https://custom.yahoo.com")!,
            timeout: 60.0
        )
        
        #expect(customSession.baseURL.absoluteString == "https://custom.yahoo.com")
        #expect(customSession.timeout == 60.0)
    }
    
    @Test
    func testSessionDefaultHeaders() {
        let session = YFSession()
        
        let headers = session.defaultHeaders
        
        #expect(headers["User-Agent"]?.contains("SwiftYFinance") == true)
        #expect(headers["Accept"] == "application/json")
        #expect(headers["Content-Type"] == "application/json")
        
        let customHeaders = ["Custom-Header": "CustomValue"]
        let sessionWithHeaders = YFSession(additionalHeaders: customHeaders)
        
        let combinedHeaders = sessionWithHeaders.defaultHeaders
        #expect(combinedHeaders["Custom-Header"] == "CustomValue")
        #expect(combinedHeaders["User-Agent"]?.contains("SwiftYFinance") == true)
    }
}
