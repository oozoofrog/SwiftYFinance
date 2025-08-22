import Testing
import Foundation
@testable import SwiftYFinance

/// YFOptionsService의 TDD 기반 테스트
@Suite("YFOptionsService Tests")
struct YFOptionsServiceTests {
    
    let client = YFClient(debugEnabled: true)
    let testTicker = YFTicker(symbol: "AAPL")
    
    /// 기본 옵션 체인 조회 기능
    @Test("단일 종목 옵션 체인 조회 - 기본 기능")
    func testFetchOptionsChain_WithValidSymbol_ReturnsOptionsData() async throws {
        // Given: 유효한 종목 심볼
        let ticker = testTicker
        
        // When: 옵션 서비스를 통해 옵션 체인 조회
        let options = try await client.options.fetchOptionsChain(for: ticker)
        
        // Then: 옵션 체인 데이터가 반환되어야 함
        #expect(options.underlyingSymbol == "AAPL", "기본 심볼이 AAPL이어야 합니다")
        #expect(!(options.expirationDates ?? []).isEmpty, "만기일 데이터가 있어야 합니다")
        #expect(!(options.strikes ?? []).isEmpty, "행사가격 데이터가 있어야 합니다")
        
        // 옵션 데이터 검증
        #expect(!(options.options ?? []).isEmpty, "옵션 데이터가 있어야 합니다")
        
        let firstOption = try #require(options.options?.first)
        
        // Call 옵션 검증
        if let calls = firstOption.calls, !calls.isEmpty {
            let firstCall = calls.first!
            #expect(!(firstCall.contractSymbol ?? "").isEmpty, "콜 옵션 계약 심볼이 있어야 합니다")
            #expect((firstCall.strike ?? 0) > 0, "콜 옵션 행사가격은 양수여야 합니다")
        }
        
        // Put 옵션 검증
        if let puts = firstOption.puts, !puts.isEmpty {
            let firstPut = puts.first!
            #expect(!(firstPut.contractSymbol ?? "").isEmpty, "풋 옵션 계약 심볼이 있어야 합니다")
            #expect((firstPut.strike ?? 0) > 0, "풋 옵션 행사가격은 양수여야 합니다")
        }
    }
    
    /// 특정 만기일 옵션 체인 조회
    @Test("특정 만기일 옵션 체인 조회")
    func testFetchOptionsChain_WithSpecificExpiration() async throws {
        // Given: 먼저 전체 옵션 체인을 조회하여 만기일 확인
        let ticker = testTicker
        let allOptions = try await client.options.fetchOptionsChain(for: ticker)
        
        let firstExpiration = try #require(allOptions.expirationDates?.first, "만기일이 없습니다")
        let firstExpirationDate = Date(timeIntervalSince1970: TimeInterval(firstExpiration))
        
        // When: 특정 만기일의 옵션 체인 조회
        let specificOptions = try await client.options.fetchOptionsChain(for: ticker, expiration: firstExpirationDate)
        
        // Then: 해당 만기일의 옵션만 반환되어야 함
        #expect(specificOptions.underlyingSymbol == "AAPL")
        #expect(!(specificOptions.options ?? []).isEmpty)
        
        // 모든 옵션이 지정한 만기일 근처여야 함
        for optionData in specificOptions.options ?? [] {
            if let expiration = optionData.expirationDate {
                let expirationDate = Date(timeIntervalSince1970: TimeInterval(expiration))
                let timeDiff = abs(expirationDate.timeIntervalSince(firstExpirationDate))
                #expect(timeDiff < 86400 * 7, "만기일이 지정한 날짜 근처여야 합니다") // 1주일 이내
            }
        }
    }
    
    /// 유효하지 않은 심볼 처리
    @Test("유효하지 않은 심볼 처리")
    func testFetchOptionsChain_WithInvalidSymbol_ThrowsError() async throws {
        // Given: 유효하지 않은 종목 심볼
        let invalidTicker = YFTicker(symbol: "INVALID_SYMBOL_XYZ")
        
        // When/Then: 에러가 발생해야 함
        await #expect(throws: Error.self) {
            _ = try await client.options.fetchOptionsChain(for: invalidTicker)
        }
    }
}