import Testing
@testable import SwiftYFinance

struct YFQuoteAPITests {
    
    @Test("YFQuoteAPI file exists")
    func testYFQuoteAPIFileExists() async throws {
        // TDD Green: YFQuoteAPI.swift 파일이 존재하고 fetchQuote 메서드가 분리되어 있는지 테스트
        let client = YFClient()
        
        // INVALID 심볼로 에러 케이스 테스트 (실제 네트워크 호출 없이 구조 확인)
        let invalidTicker = try YFTicker(symbol: "INVALID")
        
        do {
            _ = try await client.fetchQuote(ticker: invalidTicker)
            Issue.record("Should have thrown invalidSymbol error")
        } catch YFError.invalidSymbol {
            // 예상된 에러 - YFQuoteAPI extension이 정상 동작함
            #expect(Bool(true))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
        
        // realtime 파라미터가 있는 메서드도 동일하게 테스트
        do {
            _ = try await client.fetchQuote(ticker: invalidTicker, realtime: true)
            Issue.record("Should have thrown invalidSymbol error")
        } catch YFError.invalidSymbol {
            // 예상된 에러 - YFQuoteAPI extension이 정상 동작함
            #expect(Bool(true))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}