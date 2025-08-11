import Testing
@testable import SwiftYFinance

struct YFTickerTests {
    @Test
    func testTickerInitWithSymbol() throws {
        let ticker = try YFTicker(symbol: "AAPL")
        #expect(ticker.symbol == "AAPL")
    }
    
    @Test
    func testTickerSymbolValidation() throws {
        #expect(throws: YFError.invalidSymbol) {
            _ = try YFTicker(symbol: "")
        }
        
        #expect(throws: YFError.invalidSymbol) {
            _ = try YFTicker(symbol: "   ")
        }
        
        #expect(throws: YFError.invalidSymbol) {
            _ = try YFTicker(symbol: "AAPL@#$")
        }
        
        #expect(throws: YFError.invalidSymbol) {
            _ = try YFTicker(symbol: "VERYLONGTICKERSYMBOL")
        }
        
        let validTicker = try YFTicker(symbol: "aapl")
        #expect(validTicker.symbol == "AAPL")
    }
    
    @Test
    func testTickerDescription() throws {
        let ticker = try YFTicker(symbol: "AAPL")
        #expect(ticker.description == "YFTicker(symbol: AAPL)")
    }
}