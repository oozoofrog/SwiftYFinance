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
    
    @Test
    func testSessionErrorHandling() async throws {
        // 네트워크 에러 처리 테스트
        let session = YFSession()
        let builder = YFRequestBuilder(session: session)
        
        // 404 에러 테스트: 잘못된 엔드포인트
        let invalidRequest = try builder
            .path("/invalid/endpoint/path")
            .build()
        
        do {
            let (_, response) = try await session.urlSession.data(for: invalidRequest)
            let httpResponse = response as? HTTPURLResponse
            // Yahoo Finance는 잘못된 엔드포인트에 대해 다양한 에러 코드 반환 가능
            #expect(httpResponse?.statusCode == 404 || httpResponse?.statusCode == 500 || httpResponse?.statusCode == 403)
        } catch {
            // 네트워크 에러도 예상되는 결과
            #expect(error is URLError)
        }
        
        // 타임아웃 테스트: 매우 짧은 타임아웃 설정
        let shortTimeoutSession = YFSession(timeout: 0.001)
        let timeoutBuilder = YFRequestBuilder(session: shortTimeoutSession)
        
        let timeoutRequest = try timeoutBuilder
            .path("/v8/finance/chart/AAPL")
            .build()
        
        do {
            let _ = try await shortTimeoutSession.urlSession.data(for: timeoutRequest)
            // 타임아웃이 발생하지 않으면 테스트 실패가 아님 (네트워크 상황에 따라)
        } catch let error as URLError {
            #expect(error.code == .timedOut || error.code == .networkConnectionLost)
        } catch {
            // 다른 네트워크 에러도 허용
        }
        
        // 잘못된 심볼로 403 에러 테스트
        let forbiddenRequest = try builder
            .path("/v8/finance/chart/INVALID_SYMBOL_TEST_123456789")
            .build()
        
        do {
            let (data, response) = try await session.urlSession.data(for: forbiddenRequest)
            let httpResponse = response as? HTTPURLResponse
            
            // Yahoo Finance는 잘못된 심볼에 대해 200을 반환하고 에러를 JSON에 포함할 수 있음
            if httpResponse?.statusCode == 200 {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let chart = json?["chart"] as? [String: Any]
                let error = chart?["error"] as? [String: Any]
                
                // 에러가 있거나 결과가 null인 경우 확인
                let result = chart?["result"]
                #expect(error != nil || result == nil)
            } else {
                #expect(httpResponse?.statusCode == 404 || httpResponse?.statusCode == 403)
            }
        } catch {
            // 네트워크 에러도 예상되는 결과
            #expect(error is URLError)
        }
    }
    
    @Test
    func testSessionUserAgent() async throws {
        // User-Agent 헤더 설정 테스트
        let session = YFSession()
        let builder = YFRequestBuilder(session: session)
        
        // 실제 요청 생성
        let request = try builder
            .path("/v8/finance/chart/AAPL")
            .queryParam("range", "1d")
            .build()
        
        // User-Agent 헤더 확인
        let userAgent = request.value(forHTTPHeaderField: "User-Agent")
        #expect(userAgent != nil)
        
        // Yahoo Finance 호환 User-Agent 검증
        #expect(userAgent?.contains("Mozilla") == true)
        #expect(userAgent?.contains("AppleWebKit") == true)
        #expect(userAgent?.contains("Chrome") == true)
        #expect(userAgent?.contains("Safari") == true)
        
        // 실제 API 호출에서 User-Agent가 작동하는지 확인
        let (_, response) = try await session.urlSession.data(for: request)
        let httpResponse = response as? HTTPURLResponse
        #expect(httpResponse?.statusCode == 200)
        
        // 커스텀 User-Agent 테스트
        let customHeaders = ["User-Agent": "TestBot/1.0"]
        let customSession = YFSession(additionalHeaders: customHeaders)
        let customBuilder = YFRequestBuilder(session: customSession)
        
        let customRequest = try customBuilder
            .path("/v8/finance/chart/AAPL")
            .queryParam("range", "1d")
            .build()
        
        let customUserAgent = customRequest.value(forHTTPHeaderField: "User-Agent")
        #expect(customUserAgent == "TestBot/1.0")
        
        // 커스텀 User-Agent로도 API 호출이 가능한지 확인
        do {
            let (_, customResponse) = try await customSession.urlSession.data(for: customRequest)
            let customHttpResponse = customResponse as? HTTPURLResponse
            // Yahoo Finance가 특정 User-Agent를 차단할 수 있으므로 200 또는 403 모두 허용
            #expect(customHttpResponse?.statusCode == 200 || customHttpResponse?.statusCode == 403)
        } catch {
            // 네트워크 에러는 허용
            #expect(error is URLError)
        }
    }
}
