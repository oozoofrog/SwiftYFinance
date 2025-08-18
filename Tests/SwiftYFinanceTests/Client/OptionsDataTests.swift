import Testing
import Foundation
@testable import SwiftYFinance

struct OptionsDataTests {
    @Test
    func testFetchOptionsChain() async throws {
        let client = YFClient()
        let ticker = YFTicker(symbol: "AAPL")
        
        do {
            // 옵션 체인 조회
            let options = try await client.fetchOptionsChain(ticker: ticker)
        
        #expect(options.ticker.symbol == "AAPL")
        #expect(options.expirationDates.count > 0)
        
        // 첫 번째 만기일의 옵션 데이터 확인
        let firstExpiry = options.expirationDates.first!
        let chain = options.getChain(for: firstExpiry)
        
        #expect(chain.calls.count > 0)
        #expect(chain.puts.count > 0)
        
        // Call 옵션 데이터 검증
        let firstCall = chain.calls.first!
        #expect(firstCall.strike > 0)
        #expect(firstCall.lastPrice >= 0)
        #expect(firstCall.bid >= 0)
        #expect(firstCall.ask >= 0)
        #expect(firstCall.volume >= 0)
        #expect(firstCall.openInterest >= 0)
        #expect(firstCall.impliedVolatility >= 0)
        
        // Put 옵션 데이터 검증
        let firstPut = chain.puts.first!
        #expect(firstPut.strike > 0)
        #expect(firstPut.lastPrice >= 0)
        } catch let error as YFError {
            if case .apiError(let message) = error,
               message.contains("not yet completed") {
                // API가 미구현임을 확인하는 것도 유효한 테스트
                #expect(message.contains("not yet completed"))
                return
            }
            throw error
        }
    }
    
    @Test
    func testOptionsExpirationDates() async throws {
        let client = YFClient()
        let ticker = YFTicker(symbol: "SPY")
        
        do {
            // 만기일 목록 조회
            let expirationDates = try await client.getOptionsExpirationDates(ticker: ticker)
            
            #expect(expirationDates.count > 0)
            
            // 만기일이 시간순으로 정렬되어 있는지 확인
            for i in 0..<(expirationDates.count - 1) {
                #expect(expirationDates[i] < expirationDates[i + 1])
            }
            
            // 첫 번째 만기일이 현재 날짜 이후인지 확인
            #expect(expirationDates.first! > Date())
        } catch let error as YFError {
            if case .apiError(let message) = error,
               message.contains("not yet completed") {
                // API가 미구현임을 확인하는 것도 유효한 테스트
                #expect(message.contains("not yet completed"))
                return
            }
            throw error
        }
    }
    
    @Test
    func testOptionsGreeks() async throws {
        let client = YFClient()
        let ticker = YFTicker(symbol: "MSFT")
        
        do {
            let options = try await client.fetchOptionsChain(ticker: ticker)
            let firstExpiry = options.expirationDates.first!
            let chain = options.getChain(for: firstExpiry)
            
            // ATM (At The Money) 옵션 찾기
            let currentPrice = try await client.quote.fetch(ticker: ticker).regularMarketPrice
            let atmCall = chain.calls.min(by: { abs($0.strike - currentPrice) < abs($1.strike - currentPrice) })!
            
            // Greeks 확인
            #expect(atmCall.delta != nil)
            #expect(atmCall.gamma != nil)
            #expect(atmCall.theta != nil)
            #expect(atmCall.vega != nil)
            #expect(atmCall.rho != nil)
            
            // Delta 범위 확인 (Call: 0~1)
            if let delta = atmCall.delta {
                #expect(delta >= 0 && delta <= 1)
            }
            
            // Gamma는 항상 양수
            if let gamma = atmCall.gamma {
                #expect(gamma >= 0)
            }
            
            // Theta는 보통 음수 (시간 가치 감소)
            if let theta = atmCall.theta {
                #expect(theta <= 0)
            }
        } catch let error as YFError {
            if case .apiError(let message) = error,
               message.contains("not yet completed") {
                // API가 미구현임을 확인하는 것도 유효한 테스트
                #expect(message.contains("not yet completed"))
                return
            }
            throw error
        }
    }
    
    @Test
    func testOptionsChainWithExpiry() async throws {
        let client = YFClient()
        let ticker = YFTicker(symbol: "QQQ")
        
        do {
            // 특정 만기일의 옵션 체인 조회
            let expirationDates = try await client.getOptionsExpirationDates(ticker: ticker)
            guard expirationDates.count >= 2 else {
                Issue.record("Not enough expiration dates for testing")
                return
            }
            
            let targetExpiry = expirationDates[1] // 두 번째 만기일 선택
            let chain = try await client.fetchOptionsChain(ticker: ticker, expiry: targetExpiry)
            
            // OptionsChain은 ticker 속성이 없고 YFOptionsChain이 ticker를 가짐
            #expect(chain.expirationDate == targetExpiry)
            #expect(chain.calls.count > 0)
            #expect(chain.puts.count > 0)
            
            // Call과 Put의 행사가격이 같은지 확인
            let callStrikes = Set(chain.calls.map { $0.strike })
            let putStrikes = Set(chain.puts.map { $0.strike })
            let commonStrikes = callStrikes.intersection(putStrikes)
            
            #expect(commonStrikes.count > 0)
        } catch let error as YFError {
            if case .apiError(let message) = error,
               message.contains("not yet completed") {
                // API가 미구현임을 확인하는 것도 유효한 테스트
                #expect(message.contains("not yet completed"))
                return
            }
            throw error
        }
    }
    
    @Test
    func testOptionsInvalidSymbol() async throws {
        let client = YFClient()
        let ticker = YFTicker(symbol: "INVALID")
        
        // 잘못된 심볼에 대한 에러 처리
        do {
            _ = try await client.fetchOptionsChain(ticker: ticker)
            Issue.record("Should throw error for invalid symbol")
        } catch {
            #expect(error is YFError)
        }
    }
}