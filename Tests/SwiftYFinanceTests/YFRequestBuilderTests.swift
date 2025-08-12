import Testing
import Foundation
@testable import SwiftYFinance

struct YFRequestBuilderTests {
    @Test
    func testRequestBuilderBaseURL() throws {
        let session = YFSession()
        let builder = YFRequestBuilder(session: session)
        
        let request1 = try builder
            .path("/v8/finance/chart/AAPL")
            .build()
        
        #expect(request1.url?.absoluteString == "https://query1.finance.yahoo.com/v8/finance/chart/AAPL")
        
        let customSession = YFSession(baseURL: URL(string: "https://custom.yahoo.com")!)
        let customBuilder = YFRequestBuilder(session: customSession)
        
        let request2 = try customBuilder
            .path("/api/ticker")
            .build()
        
        #expect(request2.url?.absoluteString == "https://custom.yahoo.com/api/ticker")
    }
    
    @Test
    func testRequestBuilderQueryParams() throws {
        let session = YFSession()
        let builder = YFRequestBuilder(session: session)
        
        let request1 = try builder
            .path("/v8/finance/chart/AAPL")
            .queryParam("interval", "1d")
            .queryParam("range", "1mo")
            .build()
        
        #expect(request1.url?.absoluteString.contains("interval=1d") == true)
        #expect(request1.url?.absoluteString.contains("range=1mo") == true)
        #expect(request1.url?.absoluteString.contains("?") == true)
        #expect(request1.url?.absoluteString.contains("&") == true)
        
        let request2 = try builder
            .path("/v8/finance/quote")
            .queryParams(["symbols": "AAPL,MSFT", "fields": "regularMarketPrice"])
            .build()
        
        #expect(request2.url?.absoluteString.contains("symbols=AAPL,MSFT") == true)
        #expect(request2.url?.absoluteString.contains("fields=regularMarketPrice") == true)
    }
    
    @Test
    func testRequestBuilderHeaders() throws {
        let session = YFSession()
        let builder = YFRequestBuilder(session: session)
        
        let request1 = try builder
            .path("/v8/finance/chart/AAPL")
            .header("Custom-Header", "CustomValue")
            .header("Another-Header", "AnotherValue")
            .build()
        
        #expect(request1.value(forHTTPHeaderField: "Custom-Header") == "CustomValue")
        #expect(request1.value(forHTTPHeaderField: "Another-Header") == "AnotherValue")
        #expect(request1.value(forHTTPHeaderField: "User-Agent")?.contains("SwiftYFinance") == true)
        
        let request2 = try builder
            .path("/api/test")
            .headers(["X-API-Key": "secret", "X-Request-ID": "12345"])
            .build()
        
        #expect(request2.value(forHTTPHeaderField: "X-API-Key") == "secret")
        #expect(request2.value(forHTTPHeaderField: "X-Request-ID") == "12345")
    }
}