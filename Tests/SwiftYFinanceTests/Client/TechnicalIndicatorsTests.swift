import Testing
import Foundation
@testable import SwiftYFinance

struct TechnicalIndicatorsTests {
    @Test
    func testSimpleMovingAverage() async throws {
        let client = YFClient()
        let ticker = try YFTicker(symbol: "AAPL")
        
        // 20일 단순이동평균 계산
        let sma = try await client.calculateSMA(ticker: ticker, period: 20)
        
        #expect(sma.ticker.symbol == "AAPL")
        #expect(sma.period == 20)
        #expect(sma.values.count > 0)
        #expect(sma.indicator == .sma)
        
        // 이동평균 값 검증
        for value in sma.values {
            #expect(value.value > 0) // 양수여야 함
            #expect(value.date < Date()) // 과거 날짜
        }
        
        // 최신 값이 첫 번째여야 함 (내림차순 정렬)
        if sma.values.count >= 2 {
            #expect(sma.values[0].date > sma.values[1].date)
        }
    }
    
    @Test
    func testExponentialMovingAverage() async throws {
        let client = YFClient()
        let ticker = try YFTicker(symbol: "MSFT")
        
        // 12일 지수이동평균 계산
        let ema = try await client.calculateEMA(ticker: ticker, period: 12)
        
        #expect(ema.ticker.symbol == "MSFT")
        #expect(ema.period == 12)
        #expect(ema.values.count > 0)
        #expect(ema.indicator == .ema)
        
        // EMA는 SMA보다 최근 가격에 더 민감해야 함
        let sma = try await client.calculateSMA(ticker: ticker, period: 12)
        
        // 최근 값들 비교 (EMA가 더 반응적이어야 함)
        if !ema.values.isEmpty && !sma.values.isEmpty {
            let emaRecent = ema.values[0].value
            let smaRecent = sma.values[0].value
            
            // 둘 다 양수여야 함
            #expect(emaRecent > 0)
            #expect(smaRecent > 0)
        }
    }
    
    @Test
    func testRSICalculation() async throws {
        let client = YFClient()
        let ticker = try YFTicker(symbol: "GOOGL")
        
        // 14일 RSI 계산
        let rsi = try await client.calculateRSI(ticker: ticker, period: 14)
        
        #expect(rsi.ticker.symbol == "GOOGL")
        #expect(rsi.period == 14)
        #expect(rsi.values.count > 0)
        #expect(rsi.indicator == .rsi)
        
        // RSI 값 범위 검증 (0-100)
        for value in rsi.values {
            #expect(value.value >= 0)
            #expect(value.value <= 100)
            #expect(value.date < Date())
        }
        
        // RSI 신호 검증
        let latestRSI = rsi.values.first!.value
        if latestRSI > 70 {
            #expect(rsi.signal == .sell) // 과매수
        } else if latestRSI < 30 {
            #expect(rsi.signal == .buy) // 과매도
        } else {
            #expect(rsi.signal == .hold) // 중립
        }
    }
    
    @Test
    func testMACDCalculation() async throws {
        let client = YFClient()
        let ticker = try YFTicker(symbol: "AMZN")
        
        // MACD 계산 (12, 26, 9)
        let macd = try await client.calculateMACD(ticker: ticker, fastPeriod: 12, slowPeriod: 26, signalPeriod: 9)
        
        #expect(macd.ticker.symbol == "AMZN")
        #expect(macd.fastPeriod == 12)
        #expect(macd.slowPeriod == 26)
        #expect(macd.signalPeriod == 9)
        #expect(macd.values.count > 0)
        #expect(macd.indicator == .macd)
        
        // MACD 구성요소 검증
        for value in macd.values {
            #expect(value.date < Date())
            // MACD 라인은 양수/음수 모두 가능
            // Signal 라인도 양수/음수 모두 가능
            // Histogram = MACD - Signal
            let expectedHistogram = value.macdLine - value.signalLine
            #expect(abs(value.histogram - expectedHistogram) < 0.01) // 부동소수점 오차 허용
        }
        
        // MACD 신호 검증
        let latestMACD = macd.values.first!
        if latestMACD.macdLine > latestMACD.signalLine {
            #expect(macd.signal == .buy || macd.signal == .hold)
        } else {
            #expect(macd.signal == .sell || macd.signal == .hold)
        }
    }
    
    @Test
    func testBollingerBands() async throws {
        let client = YFClient()
        let ticker = try YFTicker(symbol: "TSLA")
        
        // 볼린저 밴드 계산 (20일, 2 표준편차)
        let bb = try await client.calculateBollingerBands(ticker: ticker, period: 20, stdDev: 2.0)
        
        #expect(bb.ticker.symbol == "TSLA")
        #expect(bb.period == 20)
        #expect(bb.standardDeviation == 2.0)
        #expect(bb.values.count > 0)
        #expect(bb.indicator == .bollingerBands)
        
        // 볼린저 밴드 구조 검증
        for value in bb.values {
            #expect(value.date < Date())
            #expect(value.upperBand > value.middleBand) // 상단 > 중간
            #expect(value.middleBand > value.lowerBand) // 중간 > 하단
            #expect(value.upperBand > 0 && value.middleBand > 0 && value.lowerBand > 0) // 모두 양수
        }
        
        // 현재 가격과 밴드 비교 (신호 생성)
        // 실제 구현에서는 현재 가격을 가져와서 비교해야 함
    }
    
    @Test
    func testStochasticOscillator() async throws {
        let client = YFClient()
        let ticker = try YFTicker(symbol: "META")
        
        // 스토캐스틱 계산 (14일 %K, 3일 %D)
        let stoch = try await client.calculateStochastic(ticker: ticker, kPeriod: 14, dPeriod: 3)
        
        #expect(stoch.ticker.symbol == "META")
        #expect(stoch.kPeriod == 14)
        #expect(stoch.dPeriod == 3)
        #expect(stoch.values.count > 0)
        #expect(stoch.indicator == .stochastic)
        
        // 스토캐스틱 값 범위 검증 (0-100)
        for value in stoch.values {
            #expect(value.date < Date())
            #expect(value.percentK >= 0 && value.percentK <= 100)
            #expect(value.percentD >= 0 && value.percentD <= 100)
        }
        
        // 스토캐스틱 신호 검증
        let latest = stoch.values.first!
        if latest.percentK > 80 && latest.percentD > 80 {
            #expect(stoch.signal == .sell) // 과매수
        } else if latest.percentK < 20 && latest.percentD < 20 {
            #expect(stoch.signal == .buy) // 과매도
        } else {
            #expect(stoch.signal == .hold) // 중립
        }
    }
    
    @Test
    func testMultipleIndicators() async throws {
        let client = YFClient()
        let ticker = try YFTicker(symbol: "NVDA")
        
        // 여러 지표를 한 번에 계산
        let indicators = try await client.calculateMultipleIndicators(
            ticker: ticker,
            indicators: [
                .sma(period: 20),
                .ema(period: 12),
                .rsi(period: 14),
                .macd(fast: 12, slow: 26, signal: 9)
            ]
        )
        
        #expect(indicators.count == 4)
        
        // 각 지표 검증
        for indicator in indicators {
            #expect(indicator.ticker.symbol == "NVDA")
            
            switch indicator.indicator {
            case .sma:
                #expect(indicator.period == 20)
                #expect(indicator.values.count > 0)
            case .ema:
                #expect(indicator.period == 12)
                #expect(indicator.values.count > 0)
            case .rsi:
                #expect(indicator.period == 14)
                #expect(indicator.values.count > 0)
            case .macd:
                // MACD는 macdValues를 사용
                #expect(indicator.macdValues?.count ?? 0 > 0)
            default:
                break
            }
        }
    }
    
    @Test
    func testTechnicalSignals() async throws {
        let client = YFClient()
        let ticker = try YFTicker(symbol: "AAPL")
        
        // 기술적 신호 분석
        let signals = try await client.getTechnicalSignals(ticker: ticker)
        
        #expect(signals.ticker.symbol == "AAPL")
        #expect(signals.indicators.count > 0)
        
        // 종합 신호 확인
        #expect([.buy, .sell, .hold].contains(signals.overallSignal))
        
        // 각 지표별 신호 확인
        for indicatorSignal in signals.indicators {
            #expect([.buy, .sell, .hold].contains(indicatorSignal.signal))
            #expect(indicatorSignal.strength >= 0.0 && indicatorSignal.strength <= 1.0)
        }
        
        // 신뢰도 확인
        #expect(signals.confidence >= 0.0 && signals.confidence <= 1.0)
    }
    
    @Test
    func testInvalidTickerIndicators() async throws {
        let client = YFClient()
        let ticker = try YFTicker(symbol: "INVALID")
        
        // 잘못된 티커에 대한 지표 계산
        do {
            _ = try await client.calculateSMA(ticker: ticker, period: 20)
            Issue.record("Should throw error for invalid symbol")
        } catch {
            #expect(error is YFError)
        }
    }
    
    @Test
    func testIndicatorPeriodValidation() async throws {
        let client = YFClient()
        let ticker = try YFTicker(symbol: "AAPL")
        
        // 잘못된 기간으로 지표 계산
        do {
            _ = try await client.calculateSMA(ticker: ticker, period: 0) // 0은 유효하지 않음
            Issue.record("Should throw error for invalid period")
        } catch {
            #expect(error is YFError)
        }
        
        do {
            _ = try await client.calculateSMA(ticker: ticker, period: 1000) // 너무 큰 값
            Issue.record("Should throw error for too large period")
        } catch {
            #expect(error is YFError)
        }
    }
}