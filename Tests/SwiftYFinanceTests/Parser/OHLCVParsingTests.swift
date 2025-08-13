import Testing
import Foundation
@testable import SwiftYFinance

struct OHLCVParsingTests {
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
}