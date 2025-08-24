import Testing
import Foundation
@testable import SwiftYFinance

@Suite("YFQuoteService Tests")
struct YFQuoteServiceTests {
    
    // MARK: - 유효한 심볼 테스트
    
    @Test("AAPL 종목 기본 시세 조회")
    func testFetchQuoteWithValidSymbol_AAPL() async throws {
        // Given
        let client = YFClient()
        let ticker = YFTicker(symbol: "AAPL")
        
        // When
        let quote = try await client.quote.fetch(ticker: ticker)
        
        // Then
        #expect(quote.basicInfo.symbol == "AAPL")
        #expect((quote.marketData.regularMarketPrice ?? 0) > 0)
        #expect((quote.volumeInfo.regularMarketVolume ?? 0) > 0)
        #expect((quote.volumeInfo.marketCap ?? 0) > 0)
        #expect(!(quote.basicInfo.shortName ?? "").isEmpty)
    }
    
    @Test("TSLA 종목 시세 및 시간 데이터 유효성 검증")
    func testFetchQuoteWithValidSymbol_TSLA() async throws {
        // Given
        let client = YFClient()
        let ticker = YFTicker(symbol: "TSLA")
        
        // When
        let quote = try await client.quote.fetch(ticker: ticker)
        
        // Then
        #expect(quote.basicInfo.symbol == "TSLA")
        #expect((quote.marketData.regularMarketPrice ?? 0) > 0)
        
        // 시장 시간 데이터 유효성 검증 (과거 데이터일 수 있으므로 현재 시간과 비교하지 않음)
        if let marketTime = quote.metadata.regularMarketTime {
            let marketDate = Date(timeIntervalSince1970: TimeInterval(marketTime))
            #expect(marketDate > Date(timeIntervalSince1970: 0)) // 유효한 타임스탬프
        }
    }
    
    @Test("NVDA 종목 시간외 거래 데이터 확인")
    func testFetchQuoteWithExtendedHours_NVDA() async throws {
        // Given
        let client = YFClient()
        let ticker = YFTicker(symbol: "NVDA")
        
        // When
        let quote = try await client.quote.fetch(ticker: ticker)
        
        // Then
        #expect(quote.basicInfo.symbol == "NVDA")
        #expect((quote.marketData.regularMarketPrice ?? 0) > 0)
        
        // 시간외 거래 데이터 확인
        if let afterHoursPrice = quote.extendedHours.postMarketPrice {
            #expect(afterHoursPrice > 0)
            #expect(quote.extendedHours.postMarketTime != nil)
            #expect(quote.extendedHours.postMarketChangePercent != nil)
        }
        
        if let preMarketPrice = quote.extendedHours.preMarketPrice {
            #expect(preMarketPrice > 0)
            #expect(quote.extendedHours.preMarketTime != nil)
            #expect(quote.extendedHours.preMarketChangePercent != nil)
        }
    }
    
    @Test("MSFT 종목 서비스 통합 테스트")
    func testQuoteServiceIntegration_MSFT() async throws {
        // Given
        let client = YFClient(debugEnabled: true)
        let ticker = YFTicker(symbol: "MSFT")
        
        // When
        let quote = try await client.quote.fetch(ticker: ticker)
        
        // Then
        #expect(quote.basicInfo.symbol == "MSFT")
    }
    
    // MARK: - 무효한 심볼 테스트
    
    @Test("무효한 심볼에 대한 처리를 확인한다")
    func testFetchQuoteWithInvalidSymbol() async throws {
        // Given
        let client = YFClient()
        let service = YFQuoteService(client: client)
        let invalidTicker = YFTicker(symbol: "INVALIDTICKER9999")
        
        // When & Then
        do {
            let quote = try await service.fetch(ticker: invalidTicker)
            // 무효한 심볼도 성공할 수 있음 (Yahoo API 특성)
            // 하지만 실제 데이터는 없거나 최소한이어야 함
            let hasValidPrice = (quote.marketData.regularMarketPrice ?? 0) > 0
            let hasValidName = !(quote.basicInfo.shortName ?? "").isEmpty
            let hasValidData = hasValidPrice || hasValidName
            
            // 무효한 심볼은 유의미한 데이터가 없어야 함
            #expect(!hasValidData, "Invalid ticker should not return meaningful data")
        } catch {
            // 에러가 발생해도 정상적인 에러 처리 (API에 따라 다를 수 있음)
            #expect(error is YFError, "Should throw YFError for invalid symbols")
        }
    }
    
}