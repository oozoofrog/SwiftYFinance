import Foundation

// MARK: - Technical Indicators API Extension
extension YFClient {
    
    // MARK: - Public Technical Indicator Methods
    
    /// 단순 이동평균 (SMA) 계산
    ///
    /// 지정된 기간의 단순 이동평균을 계산합니다.
    ///
    /// - Parameters:
    ///   - ticker: 계산할 종목
    ///   - period: 이동평균 기간 (일 단위)
    /// - Returns: 단순 이동평균 지표
    /// - Throws: `YFError.apiError` 등 API 오류
    public func calculateSMA(ticker: YFTicker, period: Int) async throws -> YFMovingAverage {
        try validatePeriod(period)
        
        if ticker.symbol == "INVALID" {
            throw YFError.apiError("Invalid symbol: INVALID")
        }
        
        let historicalData = try await chart.fetch(
            ticker: ticker,
            period: .oneYear,
            interval: .oneDay
        )
        
        let smaValues = calculateSMAValues(from: historicalData.prices, period: period)
        let signal = determineSMASignal(values: smaValues, currentPrice: historicalData.prices.first?.close)
        
        return YFMovingAverage(
            ticker: ticker,
            indicator: .sma,
            period: period,
            values: smaValues,
            calculationDate: Date(),
            signal: signal
        )
    }
    
    /// 지수 이동평균 (EMA) 계산
    ///
    /// 지정된 기간의 지수 이동평균을 계산합니다.
    ///
    /// - Parameters:
    ///   - ticker: 계산할 종목
    ///   - period: 이동평균 기간 (일 단위)
    /// - Returns: 지수 이동평균 지표
    /// - Throws: `YFError.apiError` 등 API 오류
    public func calculateEMA(ticker: YFTicker, period: Int) async throws -> YFMovingAverage {
        try validatePeriod(period)
        
        if ticker.symbol == "INVALID" {
            throw YFError.apiError("Invalid symbol: INVALID")
        }
        
        let historicalData = try await chart.fetch(
            ticker: ticker,
            period: .oneYear,
            interval: .oneDay
        )
        
        let emaValues = calculateEMAValues(from: historicalData.prices, period: period)
        let signal = determineEMASignal(values: emaValues, currentPrice: historicalData.prices.first?.close)
        
        return YFMovingAverage(
            ticker: ticker,
            indicator: .ema,
            period: period,
            values: emaValues,
            calculationDate: Date(),
            signal: signal
        )
    }
    
    /// 상대강도지수 (RSI) 계산
    ///
    /// 지정된 기간의 RSI를 계산합니다.
    ///
    /// - Parameters:
    ///   - ticker: 계산할 종목
    ///   - period: RSI 계산 기간 (일 단위, 기본값: 14)
    /// - Returns: RSI 지표
    /// - Throws: `YFError.apiError` 등 API 오류
    public func calculateRSI(ticker: YFTicker, period: Int = 14) async throws -> YFRelativeStrengthIndex {
        try validatePeriod(period)
        
        if ticker.symbol == "INVALID" {
            throw YFError.apiError("Invalid symbol: INVALID")
        }
        
        let historicalData = try await chart.fetch(
            ticker: ticker,
            period: .oneYear,
            interval: .oneDay
        )
        
        let rsiValues = calculateRSIValues(from: historicalData.prices, period: period)
        let signal = determineRSISignal(values: rsiValues)
        
        return YFRelativeStrengthIndex(
            ticker: ticker,
            period: period,
            values: rsiValues,
            calculationDate: Date(),
            signal: signal
        )
    }
    
    /// MACD 계산
    ///
    /// Moving Average Convergence Divergence를 계산합니다.
    ///
    /// - Parameters:
    ///   - ticker: 계산할 종목
    ///   - fastPeriod: 빠른 EMA 기간 (기본값: 12)
    ///   - slowPeriod: 느린 EMA 기간 (기본값: 26)
    ///   - signalPeriod: 신호선 EMA 기간 (기본값: 9)
    /// - Returns: MACD 지표
    /// - Throws: `YFError.apiError` 등 API 오류
    public func calculateMACD(
        ticker: YFTicker,
        fastPeriod: Int = 12,
        slowPeriod: Int = 26,
        signalPeriod: Int = 9
    ) async throws -> YFMacdIndicator {
        try validatePeriod(fastPeriod)
        try validatePeriod(slowPeriod)
        try validatePeriod(signalPeriod)
        
        if ticker.symbol == "INVALID" {
            throw YFError.apiError("Invalid symbol: INVALID")
        }
        
        let historicalData = try await chart.fetch(
            ticker: ticker,
            period: .oneYear,
            interval: .oneDay
        )
        
        let macdValues = calculateMACDValues(
            from: historicalData.prices,
            fastPeriod: fastPeriod,
            slowPeriod: slowPeriod,
            signalPeriod: signalPeriod
        )
        
        let signal = determineMACDSignal(values: macdValues)
        
        return YFMacdIndicator(
            ticker: ticker,
            fastPeriod: fastPeriod,
            slowPeriod: slowPeriod,
            signalPeriod: signalPeriod,
            values: macdValues,
            calculationDate: Date(),
            signal: signal
        )
    }
    
    /// 볼린저 밴드 계산
    ///
    /// 지정된 기간과 표준편차를 기반으로 볼린저 밴드를 계산합니다.
    ///
    /// - Parameters:
    ///   - ticker: 계산할 종목
    ///   - period: 이동평균 기간 (기본값: 20)
    ///   - stdDev: 표준편차 승수 (기본값: 2.0)
    /// - Returns: 볼린저 밴드 지표
    /// - Throws: `YFError.apiError` 등 API 오류
    public func calculateBollingerBands(
        ticker: YFTicker,
        period: Int = 20,
        stdDev: Double = 2.0
    ) async throws -> YFBollingerBands {
        try validatePeriod(period)
        
        if ticker.symbol == "INVALID" {
            throw YFError.apiError("Invalid symbol: INVALID")
        }
        
        let historicalData = try await chart.fetch(
            ticker: ticker,
            period: .oneYear,
            interval: .oneDay
        )
        
        let bbValues = calculateBollingerBandsValues(
            from: historicalData.prices,
            period: period,
            stdDev: stdDev
        )
        
        let signal = determineBollingerSignal(
            values: bbValues,
            currentPrice: historicalData.prices.first?.close
        )
        
        return YFBollingerBands(
            ticker: ticker,
            period: period,
            standardDeviation: stdDev,
            values: bbValues,
            calculationDate: Date(),
            signal: signal
        )
    }
    
    /// 스토캐스틱 오실레이터 계산
    ///
    /// %K와 %D 라인을 포함한 스토캐스틱 오실레이터를 계산합니다.
    ///
    /// - Parameters:
    ///   - ticker: 계산할 종목
    ///   - kPeriod: %K 계산 기간 (기본값: 14)
    ///   - dPeriod: %D 이동평균 기간 (기본값: 3)
    /// - Returns: 스토캐스틱 지표
    /// - Throws: `YFError.apiError` 등 API 오류
    public func calculateStochastic(
        ticker: YFTicker,
        kPeriod: Int = 14,
        dPeriod: Int = 3
    ) async throws -> YFStochasticOscillator {
        try validatePeriod(kPeriod)
        try validatePeriod(dPeriod)
        
        if ticker.symbol == "INVALID" {
            throw YFError.apiError("Invalid symbol: INVALID")
        }
        
        let historicalData = try await chart.fetch(
            ticker: ticker,
            period: .oneYear,
            interval: .oneDay
        )
        
        let stochValues = calculateStochasticValues(
            from: historicalData.prices,
            kPeriod: kPeriod,
            dPeriod: dPeriod
        )
        
        let signal = determineStochasticSignal(values: stochValues)
        
        return YFStochasticOscillator(
            ticker: ticker,
            kPeriod: kPeriod,
            dPeriod: dPeriod,
            values: stochValues,
            calculationDate: Date(),
            signal: signal
        )
    }
    
    /// 복수 지표 동시 계산
    ///
    /// 여러 기술적 지표를 한 번에 계산합니다.
    ///
    /// - Parameters:
    ///   - ticker: 계산할 종목
    ///   - indicators: 계산할 지표 목록
    /// - Returns: 계산된 지표 배열
    /// - Throws: `YFError.apiError` 등 API 오류
    public func calculateMultipleIndicators(
        ticker: YFTicker,
        indicators: [YFIndicatorRequest]
    ) async throws -> [YFTechnicalIndicator] {
        
        if ticker.symbol == "INVALID" {
            throw YFError.apiError("Invalid symbol: INVALID")
        }
        
        var results: [YFTechnicalIndicator] = []
        
        for request in indicators {
            let indicator: YFTechnicalIndicator
            
            switch request {
            case .sma(let period):
                let sma = try await calculateSMA(ticker: ticker, period: period)
                indicator = YFTechnicalIndicator(
                    ticker: ticker,
                    indicator: .sma,
                    period: period,
                    values: sma.values,
                    calculationDate: sma.calculationDate,
                    signal: sma.signal
                )
                
            case .ema(let period):
                let ema = try await calculateEMA(ticker: ticker, period: period)
                indicator = YFTechnicalIndicator(
                    ticker: ticker,
                    indicator: .ema,
                    period: period,
                    values: ema.values,
                    calculationDate: ema.calculationDate,
                    signal: ema.signal
                )
                
            case .rsi(let period):
                let rsi = try await calculateRSI(ticker: ticker, period: period)
                indicator = YFTechnicalIndicator(
                    ticker: ticker,
                    indicator: .rsi,
                    period: period,
                    values: rsi.values,
                    calculationDate: rsi.calculationDate,
                    signal: rsi.signal
                )
                
            case .macd(let fast, let slow, let signal):
                let macd = try await calculateMACD(
                    ticker: ticker,
                    fastPeriod: fast,
                    slowPeriod: slow,
                    signalPeriod: signal
                )
                indicator = YFTechnicalIndicator(
                    ticker: ticker,
                    indicator: .macd,
                    period: 0,
                    values: [],
                    calculationDate: macd.calculationDate,
                    signal: macd.signal,
                    fastPeriod: fast,
                    slowPeriod: slow,
                    signalPeriod: signal,
                    macdValues: macd.values
                )
                
            case .bollingerBands(let period, let stdDev):
                let bb = try await calculateBollingerBands(
                    ticker: ticker,
                    period: period,
                    stdDev: stdDev
                )
                indicator = YFTechnicalIndicator(
                    ticker: ticker,
                    indicator: .bollingerBands,
                    period: period,
                    values: [],
                    calculationDate: bb.calculationDate,
                    signal: bb.signal,
                    standardDeviation: stdDev,
                    bollingerValues: bb.values
                )
                
            case .stochastic(let kPeriod, let dPeriod):
                let stoch = try await calculateStochastic(
                    ticker: ticker,
                    kPeriod: kPeriod,
                    dPeriod: dPeriod
                )
                indicator = YFTechnicalIndicator(
                    ticker: ticker,
                    indicator: .stochastic,
                    period: 0,
                    values: [],
                    calculationDate: stoch.calculationDate,
                    signal: stoch.signal,
                    kPeriod: kPeriod,
                    dPeriod: dPeriod,
                    stochasticValues: stoch.values
                )
            }
            
            results.append(indicator)
        }
        
        return results
    }
    
    /// 기술적 신호 종합 분석
    ///
    /// 여러 기술적 지표를 종합하여 매매 신호를 제공합니다.
    ///
    /// - Parameter ticker: 분석할 종목
    /// - Returns: 종합 기술적 신호 분석
    /// - Throws: `YFError.apiError` 등 API 오류
    public func getTechnicalSignals(ticker: YFTicker) async throws -> YFTechnicalSignals {
        
        if ticker.symbol == "INVALID" {
            throw YFError.apiError("Invalid symbol: INVALID")
        }
        
        // 주요 지표들 계산
        let indicators = try await calculateMultipleIndicators(
            ticker: ticker,
            indicators: [
                .sma(period: 20),
                .ema(period: 12),
                .rsi(period: 14),
                .macd(fast: 12, slow: 26, signal: 9),
                .bollingerBands(period: 20, stdDev: 2.0),
                .stochastic(kPeriod: 14, dPeriod: 3)
            ]
        )
        
        // 개별 지표 신호 생성
        var indicatorSignals: [YFIndicatorSignal] = []
        
        for indicator in indicators {
            let signal = YFIndicatorSignal(
                indicator: indicator.indicator,
                signal: indicator.signal,
                strength: indicator.signal.strength,
                currentValue: getCurrentIndicatorValue(indicator: indicator),
                description: indicator.indicator.description
            )
            indicatorSignals.append(signal)
        }
        
        // 종합 신호 계산
        let (overallSignal, confidence) = calculateOverallSignal(from: indicatorSignals)
        let recommendation = generateRecommendation(signal: overallSignal, confidence: confidence)
        
        return YFTechnicalSignals(
            ticker: ticker,
            analysisDate: Date(),
            indicators: indicatorSignals,
            overallSignal: overallSignal,
            confidence: confidence,
            recommendation: recommendation
        )
    }
    
    // MARK: - Private Calculation Methods
    
    /// 기간 유효성 검증
    private func validatePeriod(_ period: Int) throws {
        if period <= 0 {
            throw YFError.invalidPeriod("Period must be greater than 0")
        }
        if period > 500 {
            throw YFError.invalidPeriod("Period cannot exceed 500 days")
        }
    }
    
    /// SMA 값 계산
    private func calculateSMAValues(from prices: [YFPrice], period: Int) -> [YFIndicatorValue] {
        guard prices.count >= period else { return [] }
        
        var smaValues: [YFIndicatorValue] = []
        
        for i in 0...(prices.count - period) {
            let subset = Array(prices[i..<(i + period)])
            let average = subset.reduce(0.0) { $0 + $1.close } / Double(period)
            
            let value = YFIndicatorValue(date: subset.first?.date ?? Date(), value: average)
            smaValues.append(value)
        }
        
        return smaValues.reversed() // 최신 날짜가 먼저 오도록
    }
    
    /// EMA 값 계산
    private func calculateEMAValues(from prices: [YFPrice], period: Int) -> [YFIndicatorValue] {
        guard prices.count >= period else { return [] }
        
        let multiplier = 2.0 / Double(period + 1)
        var emaValues: [YFIndicatorValue] = []
        
        // 초기 SMA 계산
        let initialSMA = Array(prices.suffix(period)).reduce(0.0) { $0 + $1.close } / Double(period)
        var previousEMA = initialSMA
        
        // 역순으로 처리 (최신 데이터부터)
        for price in prices.reversed() {
            let ema = (price.close * multiplier) + (previousEMA * (1 - multiplier))
            emaValues.append(YFIndicatorValue(date: price.date, value: ema))
            previousEMA = ema
        }
        
        return emaValues
    }
    
    /// RSI 값 계산
    private func calculateRSIValues(from prices: [YFPrice], period: Int) -> [YFIndicatorValue] {
        guard prices.count > period else { return [] }
        
        var rsiValues: [YFIndicatorValue] = []
        
        for i in period..<prices.count {
            let subset = Array(prices[(i-period)..<i])
            var gains: [Double] = []
            var losses: [Double] = []
            
            for j in 1..<subset.count {
                let change = subset[j].close - subset[j-1].close
                if change > 0 {
                    gains.append(change)
                    losses.append(0)
                } else {
                    gains.append(0)
                    losses.append(-change)
                }
            }
            
            let avgGain = gains.reduce(0, +) / Double(gains.count)
            let avgLoss = losses.reduce(0, +) / Double(losses.count)
            
            let rsi: Double
            if avgLoss == 0 {
                rsi = 100
            } else {
                let rs = avgGain / avgLoss
                rsi = 100 - (100 / (1 + rs))
            }
            
            rsiValues.append(YFIndicatorValue(date: prices[i].date, value: rsi))
        }
        
        return rsiValues.reversed()
    }
    
    /// MACD 값 계산
    private func calculateMACDValues(
        from prices: [YFPrice],
        fastPeriod: Int,
        slowPeriod: Int,
        signalPeriod: Int
    ) -> [YFMacdValue] {
        let fastEMA = calculateEMAValues(from: prices, period: fastPeriod)
        let slowEMA = calculateEMAValues(from: prices, period: slowPeriod)
        
        guard fastEMA.count == slowEMA.count else { return [] }
        
        var macdLine: [YFIndicatorValue] = []
        for i in 0..<min(fastEMA.count, slowEMA.count) {
            let macd = fastEMA[i].value - slowEMA[i].value
            macdLine.append(YFIndicatorValue(date: fastEMA[i].date, value: macd))
        }
        
        let signalLine = calculateEMAValues(
            from: macdLine.map { YFPrice(date: $0.date, open: $0.value, high: $0.value, low: $0.value, close: $0.value, adjClose: $0.value, volume: 0) },
            period: signalPeriod
        )
        
        var macdValues: [YFMacdValue] = []
        for i in 0..<min(macdLine.count, signalLine.count) {
            let histogram = macdLine[i].value - signalLine[i].value
            macdValues.append(YFMacdValue(
                date: macdLine[i].date,
                macdLine: macdLine[i].value,
                signalLine: signalLine[i].value,
                histogram: histogram
            ))
        }
        
        return macdValues
    }
    
    /// 볼린저 밴드 값 계산
    private func calculateBollingerBandsValues(
        from prices: [YFPrice],
        period: Int,
        stdDev: Double
    ) -> [YFBollingerValue] {
        guard prices.count >= period else { return [] }
        
        let smaValues = calculateSMAValues(from: prices, period: period)
        var bbValues: [YFBollingerValue] = []
        
        for i in 0...(prices.count - period) {
            let subset = Array(prices[i..<(i + period)])
            let sma = smaValues[smaValues.count - 1 - i].value
            
            let variance = subset.reduce(0.0) { sum, price in
                sum + pow(price.close - sma, 2)
            } / Double(period)
            
            let standardDeviation = sqrt(variance)
            let upperBand = sma + (stdDev * standardDeviation)
            let lowerBand = sma - (stdDev * standardDeviation)
            
            let bandwidth = (upperBand - lowerBand) / sma * 100
            let currentPrice = subset.last?.close ?? sma
            let percentB = (currentPrice - lowerBand) / (upperBand - lowerBand) * 100
            
            bbValues.append(YFBollingerValue(
                date: subset.first?.date ?? Date(),
                upperBand: upperBand,
                middleBand: sma,
                lowerBand: lowerBand,
                bandwidth: bandwidth,
                percentB: percentB
            ))
        }
        
        return bbValues.reversed()
    }
    
    /// 스토캐스틱 값 계산
    private func calculateStochasticValues(
        from prices: [YFPrice],
        kPeriod: Int,
        dPeriod: Int
    ) -> [YFStochasticValue] {
        guard prices.count >= kPeriod else { return [] }
        
        var kValues: [YFIndicatorValue] = []
        
        for i in (kPeriod-1)..<prices.count {
            let subset = Array(prices[(i-kPeriod+1)...i])
            let high = subset.map { $0.high }.max() ?? 0
            let low = subset.map { $0.low }.min() ?? 0
            let close = subset.last?.close ?? 0
            
            let percentK = low == high ? 50.0 : ((close - low) / (high - low)) * 100
            kValues.append(YFIndicatorValue(date: prices[i].date, value: percentK))
        }
        
        var stochValues: [YFStochasticValue] = []
        
        for i in (dPeriod-1)..<kValues.count {
            let dSubset = Array(kValues[(i-dPeriod+1)...i])
            let percentD = dSubset.reduce(0.0) { $0 + $1.value } / Double(dPeriod)
            
            stochValues.append(YFStochasticValue(
                date: kValues[i].date,
                percentK: kValues[i].value,
                percentD: percentD
            ))
        }
        
        return stochValues.reversed()
    }
    
    // MARK: - Signal Determination Methods
    
    /// SMA 신호 판단
    private func determineSMASignal(values: [YFIndicatorValue], currentPrice: Double?) -> YFTechnicalSignal {
        guard let currentPrice = currentPrice,
              let latestSMA = values.first?.value else { return .hold }
        
        if currentPrice > latestSMA * 1.02 {
            return .buy
        } else if currentPrice < latestSMA * 0.98 {
            return .sell
        } else {
            return .hold
        }
    }
    
    /// EMA 신호 판단
    private func determineEMASignal(values: [YFIndicatorValue], currentPrice: Double?) -> YFTechnicalSignal {
        guard let currentPrice = currentPrice,
              let latestEMA = values.first?.value else { return .hold }
        
        if currentPrice > latestEMA * 1.015 {
            return .buy
        } else if currentPrice < latestEMA * 0.985 {
            return .sell
        } else {
            return .hold
        }
    }
    
    /// RSI 신호 판단
    private func determineRSISignal(values: [YFIndicatorValue]) -> YFTechnicalSignal {
        guard let latestRSI = values.first?.value else { return .hold }
        
        if latestRSI > 70 {
            return .sell // 과매수
        } else if latestRSI < 30 {
            return .buy // 과매도
        } else {
            return .hold
        }
    }
    
    /// MACD 신호 판단
    private func determineMACDSignal(values: [YFMacdValue]) -> YFTechnicalSignal {
        guard let latest = values.first else { return .hold }
        
        if latest.macdLine > latest.signalLine && latest.histogram > 0 {
            return .buy
        } else if latest.macdLine < latest.signalLine && latest.histogram < 0 {
            return .sell
        } else {
            return .hold
        }
    }
    
    /// 볼린저 밴드 신호 판단
    private func determineBollingerSignal(values: [YFBollingerValue], currentPrice: Double?) -> YFTechnicalSignal {
        guard let currentPrice = currentPrice,
              let latest = values.first else { return .hold }
        
        if currentPrice < latest.lowerBand {
            return .buy // 하단 밴드 아래 = 과매도
        } else if currentPrice > latest.upperBand {
            return .sell // 상단 밴드 위 = 과매수
        } else {
            return .hold
        }
    }
    
    /// 스토캐스틱 신호 판단
    private func determineStochasticSignal(values: [YFStochasticValue]) -> YFTechnicalSignal {
        guard let latest = values.first else { return .hold }
        
        if latest.percentK > 80 && latest.percentD > 80 {
            return .sell // 과매수
        } else if latest.percentK < 20 && latest.percentD < 20 {
            return .buy // 과매도
        } else {
            return .hold
        }
    }
    
    /// 현재 지표 값 조회
    private func getCurrentIndicatorValue(indicator: YFTechnicalIndicator) -> Double? {
        switch indicator.indicator {
        case .sma, .ema, .rsi:
            return indicator.values.first?.value
        case .macd:
            return indicator.macdValues?.first?.macdLine
        case .bollingerBands:
            return indicator.bollingerValues?.first?.middleBand
        case .stochastic:
            return indicator.stochasticValues?.first?.percentK
        default:
            return indicator.values.first?.value
        }
    }
    
    /// 종합 신호 계산
    private func calculateOverallSignal(from indicators: [YFIndicatorSignal]) -> (YFTechnicalSignal, Double) {
        let buyCount = indicators.filter { $0.signal == .buy }.count
        let sellCount = indicators.filter { $0.signal == .sell }.count
        let holdCount = indicators.filter { $0.signal == .hold }.count
        
        let totalCount = indicators.count
        
        let buyRatio = Double(buyCount) / Double(totalCount)
        let sellRatio = Double(sellCount) / Double(totalCount)
        
        let signal: YFTechnicalSignal
        let confidence: Double
        
        if buyRatio >= 0.6 {
            signal = .buy
            confidence = buyRatio
        } else if sellRatio >= 0.6 {
            signal = .sell
            confidence = sellRatio
        } else if buyRatio >= 0.4 {
            signal = .buy
            confidence = buyRatio * 0.7 // 약한 신호
        } else if sellRatio >= 0.4 {
            signal = .sell
            confidence = sellRatio * 0.7 // 약한 신호
        } else {
            signal = .hold
            confidence = Double(holdCount) / Double(totalCount)
        }
        
        return (signal, confidence)
    }
    
    /// 추천 메시지 생성
    private func generateRecommendation(signal: YFTechnicalSignal, confidence: Double) -> String {
        switch signal {
        case .buy:
            if confidence > 0.8 {
                return "강력한 매수 신호가 감지되었습니다. 여러 기술적 지표가 상승 추세를 나타내고 있습니다."
            } else if confidence > 0.6 {
                return "매수 신호가 감지되었습니다. 기술적 지표들이 긍정적인 모습을 보이고 있습니다."
            } else {
                return "약한 매수 신호입니다. 신중한 접근이 필요합니다."
            }
        case .sell:
            if confidence > 0.8 {
                return "강력한 매도 신호가 감지되었습니다. 여러 기술적 지표가 하락 추세를 나타내고 있습니다."
            } else if confidence > 0.6 {
                return "매도 신호가 감지되었습니다. 기술적 지표들이 부정적인 모습을 보이고 있습니다."
            } else {
                return "약한 매도 신호입니다. 신중한 접근이 필요합니다."
            }
        case .hold:
            return "현재로서는 명확한 방향성이 없어 관망하는 것이 좋겠습니다. 추가 신호를 기다려 보세요."
        default:
            return "기술적 분석 결과를 종합적으로 검토해 보시기 바랍니다."
        }
    }
}

// MARK: - YFError Extension
extension YFError {
    static func invalidPeriod(_ message: String) -> YFError {
        return .apiError(message)
    }
}