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
            
            // 가격 데이터 유효성 검증 (-1.0은 null 값)
            for i in 0..<timestamps.count {
                let open = quote.open[i]
                let high = quote.high[i]
                let low = quote.low[i]
                let close = quote.close[i]
                let volume = quote.volume[i]
                
                // -1.0 값이 아닌 실제 데이터만 검증
                if open != -1.0 && high != -1.0 && low != -1.0 && close != -1.0 && volume != -1 {
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
                    // -1.0 값이 아닌 실제 데이터만 검증
                    if adjClose != -1.0 {
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
    
    @Test
    func testParseTimestamps() throws {
        // Unix timestamp 배열 (Python yfinance와 동일한 방식)
        let timestamps: [Int64] = [1234567890, 1234567950, 1234568010]
        
        // Swift에서 Unix timestamp를 Date로 변환
        let dates = timestamps.map { timestamp in
            Date(timeIntervalSince1970: TimeInterval(timestamp))
        }
        
        // 변환 결과 검증
        #expect(dates.count == 3)
        
        // 첫 번째 timestamp 검증 (1234567890 = 2009-02-13 23:31:30 UTC)
        let date1 = dates[0]
        let calendar = Calendar(identifier: .gregorian)
        let utcTimeZone = TimeZone(identifier: "UTC")!
        let components1 = calendar.dateComponents(in: utcTimeZone, from: date1)
        
        #expect(components1.year == 2009)
        #expect(components1.month == 2)
        #expect(components1.day == 13)
        #expect(components1.hour == 23)
        #expect(components1.minute == 31)
        #expect(components1.second == 30)
        
        // 두 번째 timestamp 검증 (1234567950 = 2009-02-13 23:32:30 UTC)
        let date2 = dates[1]
        let components2 = calendar.dateComponents(in: utcTimeZone, from: date2)
        
        #expect(components2.year == 2009)
        #expect(components2.month == 2)
        #expect(components2.day == 13)
        #expect(components2.hour == 23)
        #expect(components2.minute == 32)
        #expect(components2.second == 30)
        
        // 시간 순서 검증 (timestamps는 순차적으로 증가해야 함)
        for i in 1..<dates.count {
            #expect(dates[i] > dates[i-1])
        }
        
        // 시간 간격 검증 (60초 간격)
        let interval1to2 = dates[1].timeIntervalSince(dates[0])
        let interval2to3 = dates[2].timeIntervalSince(dates[1])
        
        #expect(interval1to2 == 60.0)
        #expect(interval2to3 == 60.0)
    }
    
    @Test
    func testParseOHLCV() throws {
        let parser = YFResponseParser()
        
        // Yahoo Finance Chart API 응답과 동일한 구조의 OHLCV 테스트 데이터
        let jsonData = """
        {
            "chart": {
                "result": [{
                    "meta": {
                        "symbol": "AAPL",
                        "regularMarketPrice": 150.25
                    },
                    "timestamp": [1234567890, 1234567950, 1234568010],
                    "indicators": {
                        "quote": [{
                            "open": [149.0, null, 151.0],
                            "high": [151.0, 152.0, 153.0],
                            "low": [148.0, null, 150.0],
                            "close": [150.0, 151.0, 152.0],
                            "volume": [1000000, null, 1200000]
                        }],
                        "adjclose": [{
                            "adjclose": [150.0, 151.0, null]
                        }]
                    }
                }]
            }
        }
        """.data(using: .utf8)!
        
        // JSON 파싱
        let chartResponse = try parser.parse(jsonData, type: ChartResponse.self)
        let result = chartResponse.chart.result![0]
        let timestamps = result.timestamp!
        let quote = result.indicators.quote[0]
        let adjCloseArray = result.indicators.adjclose?.first?.adjclose
        
        // OHLCV 배열 길이 검증
        #expect(quote.open.count == 3)
        #expect(quote.high.count == 3)
        #expect(quote.low.count == 3)
        #expect(quote.close.count == 3)
        #expect(quote.volume.count == 3)
        #expect(timestamps.count == 3)
        
        // null 값이 -1.0으로 변환되었는지 검증
        #expect(quote.open[0] == 149.0)      // 정상 값
        #expect(quote.open[1] == -1.0)       // null -> -1.0
        #expect(quote.open[2] == 151.0)      // 정상 값
        
        #expect(quote.high[0] == 151.0)      // 정상 값
        #expect(quote.high[1] == 152.0)      // 정상 값
        #expect(quote.high[2] == 153.0)      // 정상 값
        
        #expect(quote.low[0] == 148.0)       // 정상 값
        #expect(quote.low[1] == -1.0)        // null -> -1.0
        #expect(quote.low[2] == 150.0)       // 정상 값
        
        #expect(quote.close[0] == 150.0)     // 정상 값
        #expect(quote.close[1] == 151.0)     // 정상 값
        #expect(quote.close[2] == 152.0)     // 정상 값
        
        #expect(quote.volume[0] == 1000000)  // 정상 값
        #expect(quote.volume[1] == -1)       // null -> -1
        #expect(quote.volume[2] == 1200000)  // 정상 값
        
        // adjusted close 검증
        if let adjClose = adjCloseArray {
            #expect(adjClose.count == 3)
            #expect(adjClose[0] == 150.0)    // 정상 값
            #expect(adjClose[1] == 151.0)    // 정상 값
            #expect(adjClose[2] == -1.0)     // null -> -1.0
        }
        
        // YFPrice 객체로 변환하는 로직 검증 (null 값 제외)
        var validPrices: [YFPrice] = []
        
        for i in 0..<timestamps.count {
            let open = quote.open[i]
            let high = quote.high[i]
            let low = quote.low[i]
            let close = quote.close[i]
            let volume = quote.volume[i]
            
            // -1.0 값 (null)이 아닌 유효한 데이터만 처리
            if open != -1.0 && high != -1.0 && low != -1.0 && close != -1.0 && volume != -1 {
                let date = Date(timeIntervalSince1970: TimeInterval(timestamps[i]))
                let adjClose = (adjCloseArray != nil && i < adjCloseArray!.count) ? 
                              (adjCloseArray![i] == -1.0 ? close : adjCloseArray![i]) : close
                
                let price = YFPrice(
                    date: date,
                    open: open,
                    high: high,
                    low: low,
                    close: close,
                    adjClose: adjClose,
                    volume: volume
                )
                validPrices.append(price)
            }
        }
        
        // null 값이 있는 index 1은 제외되고 index 0, 2만 유효한 가격 데이터로 변환
        #expect(validPrices.count == 2)
        
        // 첫 번째 유효한 가격 데이터 (index 0)
        let price0 = validPrices[0]
        #expect(price0.open == 149.0)
        #expect(price0.high == 151.0)
        #expect(price0.low == 148.0)
        #expect(price0.close == 150.0)
        #expect(price0.adjClose == 150.0)
        #expect(price0.volume == 1000000)
        
        // 두 번째 유효한 가격 데이터 (index 2, adjClose는 null이므로 close 값 사용)
        let price2 = validPrices[1]
        #expect(price2.open == 151.0)
        #expect(price2.high == 153.0)
        #expect(price2.low == 150.0)
        #expect(price2.close == 152.0)
        #expect(price2.adjClose == 152.0)  // adjClose가 null이므로 close 값 사용
        #expect(price2.volume == 1200000)
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