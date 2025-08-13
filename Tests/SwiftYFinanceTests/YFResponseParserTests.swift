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
                    "timestamp": [1234567890, 1234567950],
                    "indicators": {
                        "quote": [{
                            "open": [149.0, 150.0],
                            "high": [151.0, 152.0],
                            "low": [148.0, 149.0],
                            "close": [150.0, 151.0],
                            "volume": [1000000, 1100000]
                        }],
                        "adjclose": [{
                            "adjclose": [150.0, 151.0]
                        }]
                    }
                }],
                "error": null
            }
        }
        """.data(using: .utf8)!
        
        let result = try parser.parse(jsonData, type: ChartResponse.self)
        
        #expect(result.chart.result?.count == 1)
        #expect(result.chart.result?[0].meta.symbol == "AAPL")
        #expect(result.chart.result?[0].meta.regularMarketPrice == 150.25)
        
        let quotes = result.chart.result?[0].indicators.quote[0]
        #expect(quotes?.open.count == 2)
        #expect(quotes?.open[0] == 149.0)
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
    
    @Test
    func testParseChartResponse() async throws {
        // 실제 Yahoo chart JSON 파싱 테스트
        let session = YFSession()
        let builder = YFRequestBuilder(session: session)
        let parser = YFResponseParser()
        
        // 실제 Yahoo Finance API에서 데이터 가져오기
        let request = try builder
            .path("/v8/finance/chart/AAPL")
            .queryParam("interval", "1d")
            .queryParam("range", "5d")
            .build()
        
        let (data, response) = try await session.urlSession.data(for: request)
        let httpResponse = response as? HTTPURLResponse
        #expect(httpResponse?.statusCode == 200)
        
        // 실제 Yahoo Finance JSON 파싱
        let chartResponse = try parser.parse(data, type: ChartResponse.self)
        
        // 파싱 성공 확인
        #expect(chartResponse.chart.result != nil)
        #expect(chartResponse.chart.result!.count > 0)
        
        let result = chartResponse.chart.result![0]
        
        // 메타데이터 검증
        #expect(result.meta.symbol == "AAPL")
        if let marketPrice = result.meta.regularMarketPrice {
            #expect(marketPrice > 0)
        }
        
        // 타임스탬프 데이터 검증
        if let timestamps = result.timestamp {
            #expect(timestamps.count > 0)
            
            // OHLCV 데이터 검증
            let quote = result.indicators.quote[0]
            #expect(quote.open.count > 0)
            #expect(quote.high.count > 0)
            #expect(quote.low.count > 0)
            #expect(quote.close.count > 0)
            #expect(quote.volume.count > 0)
            
            // 데이터 일관성 검증
            #expect(quote.open.count == quote.high.count)
            #expect(quote.open.count == quote.low.count)
            #expect(quote.open.count == quote.close.count)
            #expect(quote.open.count == quote.volume.count)
            #expect(quote.open.count == timestamps.count)
            
            // 가격 데이터 유효성 검증 (nil 값 처리)
            for i in 0..<timestamps.count {
                if let open = quote.open[i],
                   let high = quote.high[i],
                   let low = quote.low[i],
                   let close = quote.close[i],
                   let volume = quote.volume[i] {
                    
                    // 기본 유효성 검증
                    #expect(open > 0)
                    #expect(high > 0)
                    #expect(low > 0)
                    #expect(close > 0)
                    #expect(volume >= 0)
                    
                    // 가격 관계 검증
                    #expect(high >= max(open, close))
                    #expect(low <= min(open, close))
                }
            }
            
            // adjusted close 데이터 검증 (별도 indicators.adjclose 구조)
            if let adjCloseArray = result.indicators.adjclose?.first?.adjclose {
                #expect(adjCloseArray.count == quote.close.count)
                for adjClose in adjCloseArray {
                    if let adjClose = adjClose {
                        #expect(adjClose > 0)
                    }
                }
            }
            
            // 타임스탬프를 Date로 변환하여 검증
            for timestamp in timestamps {
                let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
                // 최근 1년 내의 데이터인지 확인
                let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
                #expect(date >= oneYearAgo)
                #expect(date <= Date())
            }
        }
    }
}