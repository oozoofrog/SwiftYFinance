import Testing
import Foundation
@testable import SwiftYFinance

struct YFSessionTests {
    @Test
    func testSessionInit() {
        let session = YFSession()
        
        #expect(session.baseURL.absoluteString == "https://query2.finance.yahoo.com")
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
        
        #expect(headers["User-Agent"]?.contains("Mozilla") == true)
        #expect(headers["Accept"] == "application/json")
        #expect(headers["Content-Type"] == "application/json")
        
        let customHeaders = ["Custom-Header": "CustomValue"]
        let sessionWithHeaders = YFSession(additionalHeaders: customHeaders)
        
        let combinedHeaders = sessionWithHeaders.defaultHeaders
        #expect(combinedHeaders["Custom-Header"] == "CustomValue")
        #expect(combinedHeaders["User-Agent"]?.contains("Mozilla") == true)
    }
    
    @Test
    func testSessionProxy() {
        let proxyConfig = [
            "HTTPSProxy": "proxy.example.com",
            "HTTPSPort": 8080
        ] as [String: Any]
        
        let sessionWithProxy = YFSession(proxy: proxyConfig)
        
        #expect(sessionWithProxy.proxy != nil)
        #expect(sessionWithProxy.proxy?["HTTPSProxy"] as? String == "proxy.example.com")
        #expect(sessionWithProxy.proxy?["HTTPSPort"] as? Int == 8080)
        
        let sessionWithoutProxy = YFSession()
        #expect(sessionWithoutProxy.proxy == nil)
    }
    
    @Test
    func testSessionRealRequest() async throws {
        // 실제 HTTP 요청 처리 테스트
        let session = YFSession()
        let builder = YFRequestBuilder(session: session)
        
        // 실제 Yahoo Finance API URL 생성
        let request = try builder
            .path("/v8/finance/chart/AAPL")
            .queryParam("interval", "1d")
            .queryParam("range", "5d")
            .build()
        
        // 실제 네트워크 호출 수행
        let (data, response) = try await session.urlSession.data(for: request)
        
        // HTTP 응답 확인
        let httpResponse = response as? HTTPURLResponse
        #expect(httpResponse?.statusCode == 200)
        
        // 데이터가 비어있지 않은지 확인
        #expect(data.count > 0)
        
        // JSON 파싱 가능한지 확인
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json != nil)
        
        // Yahoo Finance 응답 구조 확인
        let chart = json?["chart"] as? [String: Any]
        #expect(chart != nil)
        
        let result = chart?["result"] as? [[String: Any]]
        #expect(result?.first != nil)
        
        // 메타데이터 확인
        let meta = result?.first?["meta"] as? [String: Any]
        #expect(meta?["symbol"] as? String == "AAPL")
    }
}
