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
        
        #expect(request1.url?.absoluteString == "https://query2.finance.yahoo.com/v8/finance/chart/AAPL")
        
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
    
    /// 실제 User-Agent 헤더 설정 테스트
    @Test
    func testRequestBuilderHeaders() throws {
        let session = YFSession()
        let builder = YFRequestBuilder(session: session)
        
        // Yahoo Finance 호환 User-Agent 헤더 테스트
        let request1 = try builder
            .path("/v8/finance/chart/AAPL")
            .header("Custom-Header", "CustomValue")
            .header("Another-Header", "AnotherValue")
            .build()
        
        #expect(request1.value(forHTTPHeaderField: "Custom-Header") == "CustomValue")
        #expect(request1.value(forHTTPHeaderField: "Another-Header") == "AnotherValue")
        
        // 실제 Yahoo Finance 호환 User-Agent 확인
        let userAgent = request1.value(forHTTPHeaderField: "User-Agent")
        #expect(userAgent != nil)
        #expect(userAgent?.contains("Mozilla") == true)
        #expect(userAgent?.contains("AppleWebKit") == true || userAgent?.contains("Gecko") == true)
        
        // 다양한 헤더 설정 테스트
        let request2 = try builder
            .path("/v8/finance/chart/MSFT")
            .headers([
                "Accept": "application/json",
                "Accept-Language": "en-US,en;q=0.9",
                "Accept-Encoding": "gzip, deflate, br",
                "DNT": "1",
                "Connection": "keep-alive",
                "Upgrade-Insecure-Requests": "1"
            ])
            .build()
        
        #expect(request2.value(forHTTPHeaderField: "Accept") == "application/json")
        #expect(request2.value(forHTTPHeaderField: "Accept-Language") == "en-US,en;q=0.9")
        #expect(request2.value(forHTTPHeaderField: "Accept-Encoding") == "gzip, deflate, br")
        #expect(request2.value(forHTTPHeaderField: "DNT") == "1")
        #expect(request2.value(forHTTPHeaderField: "Connection") == "keep-alive")
        #expect(request2.value(forHTTPHeaderField: "Upgrade-Insecure-Requests") == "1")
        
        // User-Agent가 yfinance-reference의 USER_AGENTS와 유사한 형태인지 확인
        let userAgent2 = request2.value(forHTTPHeaderField: "User-Agent")
        #expect(userAgent2 != nil)
        
        // Chrome, Firefox, Safari, Edge 중 하나와 일치하는지 확인
        let validUserAgentPatterns = [
            "Chrome", "Firefox", "Safari", "Edge"
        ]
        let hasValidPattern = validUserAgentPatterns.contains { pattern in
            userAgent2?.contains(pattern) == true
        }
        #expect(hasValidPattern == true)
        
        // 기본 헤더들이 포함되어 있는지 확인
        #expect(request2.value(forHTTPHeaderField: "User-Agent") != nil)
        
        // 특정 Yahoo Finance 호환 User-Agent 설정 테스트
        let request3 = try builder
            .path("/v8/finance/chart/GOOGL")
            .header("User-Agent", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36")
            .build()
        
        let customUserAgent = request3.value(forHTTPHeaderField: "User-Agent")
        #expect(customUserAgent == "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36")
        #expect(customUserAgent?.contains("Chrome/133.0.0.0") == true)
        #expect(customUserAgent?.contains("Safari/537.36") == true)
    }
    
    /// Yahoo Finance chart API URL 생성 테스트
    @Test
    func testRequestBuilderChartURL() throws {
        let session = YFSession()
        let builder = YFRequestBuilder(session: session)
        
        // Yahoo Finance chart API URL 생성: /v8/finance/chart/{symbol}
        let request = try builder
            .path("/v8/finance/chart/AAPL")
            .build()
        
        #expect(request.url?.absoluteString == "https://query2.finance.yahoo.com/v8/finance/chart/AAPL")
        #expect(request.url?.scheme == "https")
        #expect(request.url?.host == "query2.finance.yahoo.com")
        #expect(request.url?.path == "/v8/finance/chart/AAPL")
        
        // 다른 심볼로도 테스트
        let request2 = try builder
            .path("/v8/finance/chart/MSFT")
            .build()
        
        #expect(request2.url?.absoluteString == "https://query2.finance.yahoo.com/v8/finance/chart/MSFT")
        #expect(request2.url?.path == "/v8/finance/chart/MSFT")
    }
    
    /// interval 파라미터 추가 테스트
    @Test
    func testRequestBuilderWithInterval() throws {
        let session = YFSession()
        let builder = YFRequestBuilder(session: session)
        
        // 1분 간격 파라미터 추가
        let request1 = try builder
            .path("/v8/finance/chart/AAPL")
            .queryParam("interval", "1m")
            .queryParam("range", "1d")
            .build()
        
        #expect(request1.url?.query?.contains("interval=1m") == true)
        #expect(request1.url?.query?.contains("range=1d") == true)
        #expect(request1.url?.absoluteString.contains("interval=1m") == true)
        
        // 5분 간격 파라미터 추가
        let request2 = try builder
            .path("/v8/finance/chart/MSFT")
            .queryParam("interval", "5m")
            .queryParam("range", "5d")
            .build()
        
        #expect(request2.url?.query?.contains("interval=5m") == true)
        #expect(request2.url?.query?.contains("range=5d") == true)
        
        // 일간 간격 파라미터 추가
        let request3 = try builder
            .path("/v8/finance/chart/GOOGL")
            .queryParam("interval", "1d")
            .queryParam("range", "1mo")
            .build()
        
        #expect(request3.url?.query?.contains("interval=1d") == true)
        #expect(request3.url?.query?.contains("range=1mo") == true)
        
        // 복합 파라미터 테스트 (includePrePost, events 포함)
        let request4 = try builder
            .path("/v8/finance/chart/TSLA")
            .queryParams([
                "interval": "1h",
                "range": "1wk",
                "includePrePost": "false",
                "events": "div,splits,capitalGains"
            ])
            .build()
        
        let query = request4.url?.query ?? ""
        #expect(query.contains("interval=1h"))
        #expect(query.contains("range=1wk"))
        #expect(query.contains("includePrePost=false"))
        #expect(query.contains("events=div,splits,capitalGains"))
    }
    
    /// period 파라미터 추가 테스트 (range vs period1/period2)
    @Test
    func testRequestBuilderWithPeriod() throws {
        let session = YFSession()
        let builder = YFRequestBuilder(session: session)
        
        // range 파라미터를 사용하는 period 방식
        let request1 = try builder
            .path("/v8/finance/chart/AAPL")
            .queryParam("range", "1d")
            .queryParam("interval", "1m")
            .build()
        
        #expect(request1.url?.query?.contains("range=1d") == true)
        #expect(request1.url?.query?.contains("interval=1m") == true)
        
        // 다양한 period 테스트
        let periods = ["1d", "5d", "1mo", "3mo", "6mo", "1y", "2y", "5y", "10y", "ytd", "max"]
        for period in periods {
            let request = try builder
                .path("/v8/finance/chart/MSFT")
                .queryParam("range", period)
                .queryParam("interval", "1d")
                .build()
            
            #expect(request.url?.query?.contains("range=\(period)") == true)
            #expect(request.url?.query?.contains("interval=1d") == true)
        }
        
        // period1/period2 파라미터를 사용하는 날짜 범위 방식
        let request2 = try builder
            .path("/v8/finance/chart/GOOGL")
            .queryParams([
                "period1": "1640995200", // 2022-01-01 timestamp
                "period2": "1643673600", // 2022-02-01 timestamp
                "interval": "1d"
            ])
            .build()
        
        let query2 = request2.url?.query ?? ""
        #expect(query2.contains("period1=1640995200"))
        #expect(query2.contains("period2=1643673600"))
        #expect(query2.contains("interval=1d"))
        
        // period와 interval 조합 테스트 (intraday vs interday)
        let request3 = try builder
            .path("/v8/finance/chart/TSLA")
            .queryParams([
                "range": "1d",
                "interval": "5m"  // intraday 간격
            ])
            .build()
        
        #expect(request3.url?.query?.contains("range=1d") == true)
        #expect(request3.url?.query?.contains("interval=5m") == true)
        
        let request4 = try builder
            .path("/v8/finance/chart/NVDA")
            .queryParams([
                "range": "1y",
                "interval": "1wk"  // weekly 간격
            ])
            .build()
        
        #expect(request4.url?.query?.contains("range=1y") == true)
        #expect(request4.url?.query?.contains("interval=1wk") == true)
    }
}