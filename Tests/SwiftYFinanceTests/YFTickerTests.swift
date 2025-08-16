import Testing
@testable import SwiftYFinance

struct YFTickerTests {
    @Test("Basic Ticker Creation")
    func testTickerInitWithSymbol() {
        let ticker = YFTicker(symbol: "AAPL")
        #expect(ticker.symbol == "AAPL")
    }
    
    @Test("Symbol Normalization")
    func testTickerSymbolNormalization() {
        // 빈 문자열 처리
        let emptyTicker = YFTicker(symbol: "")
        #expect(emptyTicker.symbol == "")
        
        // 공백 제거
        let spaceTicker = YFTicker(symbol: "   AAPL   ")
        #expect(spaceTicker.symbol == "AAPL")
        
        // 소문자를 대문자로 변환
        let lowercaseTicker = YFTicker(symbol: "aapl")
        #expect(lowercaseTicker.symbol == "AAPL")
        
        // 특수 문자 허용 (API에서 검증)
        let specialTicker = YFTicker(symbol: "AAPL@#$")
        #expect(specialTicker.symbol == "AAPL@#$")
        
        // 긴 심볼 허용 (API에서 검증)
        let longTicker = YFTicker(symbol: "VERYLONGTICKERSYMBOL")
        #expect(longTicker.symbol == "VERYLONGTICKERSYMBOL")
    }
    
    @Test("Ticker Description")
    func testTickerDescription() {
        let ticker = YFTicker(symbol: "AAPL")
        #expect(ticker.description == "YFTicker(symbol: AAPL)")
    }
}