# Technical Analysis

SwiftYFinance를 사용한 기술적 분석 심화 가이드

## Overview

기술적 분석은 과거 가격과 거래량 데이터를 바탕으로 주식의 미래 방향을 예측하는 분석 방법입니다. SwiftYFinance는 다양한 기술적 지표를 제공하여 체계적인 분석을 할 수 있도록 도와줍니다.

## Moving Averages (이동평균)

### Simple Moving Average (SMA)

단순 이동평균은 가장 기본적인 추세 지표입니다:

```swift
let history = try await client.fetchHistory(
    ticker: ticker,
    period: .oneYear,
    interval: .oneDay
)

let indicators = YFTechnicalIndicators(prices: history.prices)

// 다양한 기간의 SMA
let sma5 = indicators.simpleMovingAverage(period: 5)
let sma20 = indicators.simpleMovingAverage(period: 20)
let sma50 = indicators.simpleMovingAverage(period: 50)
let sma200 = indicators.simpleMovingAverage(period: 200)

// 현재 이동평균들
if let current5 = sma5.last,
   let current20 = sma20.last,
   let current50 = sma50.last,
   let current200 = sma200.last {
    
    print("=== 이동평균 분석 ===")
    print("SMA-5:   $\(String(format: "%.2f", current5))")
    print("SMA-20:  $\(String(format: "%.2f", current20))")
    print("SMA-50:  $\(String(format: "%.2f", current50))")
    print("SMA-200: $\(String(format: "%.2f", current200))")
    
    // 골든크로스/데드크로스 분석
    if current20 > current50 && current50 > current200 {
        print("📈 강력한 상승 추세 (모든 단기 MA가 장기 MA 위)")
    } else if current20 < current50 && current50 < current200 {
        print("📉 강력한 하락 추세 (모든 단기 MA가 장기 MA 아래)")
    }
}
```

### Golden Cross & Death Cross 감지

```swift
func detectCrossover(shortMA: [Double], longMA: [Double]) -> String? {
    guard shortMA.count >= 2 && longMA.count >= 2 else { return nil }
    
    let currentShort = shortMA.last!
    let currentLong = longMA.last!
    let previousShort = shortMA[shortMA.count - 2]
    let previousLong = longMA[longMA.count - 2]
    
    if previousShort <= previousLong && currentShort > currentLong {
        return "🌟 골든크로스 발생! (단기 MA가 장기 MA를 상향 돌파)"
    } else if previousShort >= previousLong && currentShort < currentLong {
        return "💀 데드크로스 발생! (단기 MA가 장기 MA를 하향 돌파)"
    }
    
    return nil
}

if let crossover = detectCrossover(shortMA: sma20, longMA: sma50) {
    print(crossover)
}
```

### Exponential Moving Average (EMA)

지수 이동평균은 최근 가격에 더 큰 가중치를 부여합니다:

```swift
let ema12 = indicators.exponentialMovingAverage(period: 12)
let ema26 = indicators.exponentialMovingAverage(period: 26)

// EMA vs SMA 비교
let sma12 = indicators.simpleMovingAverage(period: 12)

if let emaValue = ema12.last,
   let smaValue = sma12.last {
    
    print("\n=== EMA vs SMA (12일) ===")
    print("EMA-12: $\(String(format: "%.2f", emaValue))")
    print("SMA-12: $\(String(format: "%.2f", smaValue))")
    print("차이: $\(String(format: "%.2f", emaValue - smaValue))")
    
    if emaValue > smaValue {
        print("💡 EMA가 높음 → 최근 상승 모멘텀")
    } else {
        print("💡 EMA가 낮음 → 최근 하락 모멘텀")
    }
}
```

## Momentum Indicators (모멘텀 지표)

### RSI (Relative Strength Index)

RSI는 과매수/과매도 상태를 판단하는 지표입니다:

```swift
let rsi14 = indicators.relativeStrengthIndex(period: 14)
let currentRSI = rsi14.last ?? 0

print("\n=== RSI 분석 ===")
print("RSI (14): \(String(format: "%.2f", currentRSI))")

switch currentRSI {
case 80...:
    print("🔴 극도 과매수 (80+)")
case 70..<80:
    print("🟠 과매수 구간 (70-80)")
case 30..<70:
    print("🟢 정상 구간 (30-70)")
case 20..<30:
    print("🟡 과매도 구간 (20-30)")
default:
    print("🔵 극도 과매도 (20 미만)")
}

// RSI 다이버전스 분석
func analyzeRSIDivergence(prices: [YFPrice], rsi: [Double]) -> String? {
    guard prices.count >= 20 && rsi.count >= 20 else { return nil }
    
    let recentPrices = Array(prices.suffix(10))
    let recentRSI = Array(rsi.suffix(10))
    
    let priceHigh = recentPrices.max(by: { $0.high < $1.high })?.high ?? 0
    let priceLow = recentPrices.min(by: { $0.low < $1.low })?.low ?? 0
    let rsiHigh = recentRSI.max() ?? 0
    let rsiLow = recentRSI.min() ?? 0
    
    // 단순화된 다이버전스 체크 (실제로는 더 정교한 로직 필요)
    if priceHigh > prices[prices.count - 20].high && rsiHigh < rsi[rsi.count - 20] {
        return "📉 약세 다이버전스: 가격은 신고점, RSI는 하락"
    } else if priceLow < prices[prices.count - 20].low && rsiLow > rsi[rsi.count - 20] {
        return "📈 강세 다이버전스: 가격은 신저점, RSI는 상승"
    }
    
    return nil
}

if let divergence = analyzeRSIDivergence(prices: history.prices, rsi: rsi14) {
    print(divergence)
}
```

### MACD (Moving Average Convergence Divergence)

MACD는 추세와 모멘텀을 동시에 분석합니다:

```swift
let macdData = indicators.macd(fastPeriod: 12, slowPeriod: 26, signalPeriod: 9)

if let macdLine = macdData.macd.last,
   let signalLine = macdData.signal.last,
   let histogram = macdData.histogram.last {
    
    print("\n=== MACD 분석 ===")
    print("MACD Line: \(String(format: "%.4f", macdLine))")
    print("Signal Line: \(String(format: "%.4f", signalLine))")
    print("Histogram: \(String(format: "%.4f", histogram))")
    
    // MACD 시그널 분석
    if macdLine > signalLine && histogram > 0 {
        print("📈 강세 시그널 (MACD > Signal, Histogram > 0)")
    } else if macdLine < signalLine && histogram < 0 {
        print("📉 약세 시그널 (MACD < Signal, Histogram < 0)")
    }
    
    // MACD 제로선 분석
    if macdLine > 0 {
        print("💪 제로선 위 → 장기 상승 추세")
    } else {
        print("😔 제로선 아래 → 장기 하락 추세")
    }
}

// MACD 히스토그램 변화율
if macdData.histogram.count >= 2 {
    let currentHist = macdData.histogram.last!
    let previousHist = macdData.histogram[macdData.histogram.count - 2]
    let histogramChange = currentHist - previousHist
    
    print("히스토그램 변화: \(String(format: "%.4f", histogramChange))")
    
    if histogramChange > 0 {
        print("📊 모멘텀 증가 중")
    } else {
        print("📊 모멘텀 감소 중")
    }
}
```

## Volatility Indicators (변동성 지표)

### Bollinger Bands

볼린저 밴드는 가격의 변동성을 측정합니다:

```swift
let bollingerBands = indicators.bollingerBands(period: 20, standardDeviations: 2)

if let upperBand = bollingerBands.upper.last,
   let middleBand = bollingerBands.middle.last,
   let lowerBand = bollingerBands.lower.last,
   let currentPrice = history.prices.last?.close {
    
    print("\n=== 볼린저 밴드 분석 ===")
    print("상단 밴드: $\(String(format: "%.2f", upperBand))")
    print("중간 밴드: $\(String(format: "%.2f", middleBand))")  
    print("하단 밴드: $\(String(format: "%.2f", lowerBand))")
    print("현재 가격: $\(String(format: "%.2f", currentPrice))")
    
    // 밴드폭 계산
    let bandWidth = (upperBand - lowerBand) / middleBand * 100
    print("밴드폭: \(String(format: "%.2f", bandWidth))%")
    
    // %B 계산 (밴드 내 위치)
    let percentB = (currentPrice - lowerBand) / (upperBand - lowerBand) * 100
    print("%B: \(String(format: "%.1f", percentB))%")
    
    // 볼린저 밴드 시그널
    switch percentB {
    case 80...:
        print("🔴 과매수 구간 (%B > 80)")
    case ...20:
        print("🔵 과매도 구간 (%B < 20)")
    case 50...80:
        print("🟠 상단 접근 중")
    case 20...50:
        print("🟡 하단 접근 중")
    default:
        print("🟢 정상 구간")
    }
    
    // 밴드 돌파 분석
    if currentPrice > upperBand {
        print("⚡ 상단 밴드 돌파 → 강한 상승 모멘텀")
    } else if currentPrice < lowerBand {
        print("⚡ 하단 밴드 돌파 → 강한 하락 모멘텀")
    }
}

// 볼린저 밴드 스퀴즈 감지
func detectBollingerSqueeze(bandWidth: [Double]) -> Bool {
    guard bandWidth.count >= 20 else { return false }
    
    let recent20 = Array(bandWidth.suffix(20))
    let currentWidth = recent20.last!
    let averageWidth = recent20.reduce(0, +) / Double(recent20.count)
    
    return currentWidth < averageWidth * 0.8 // 평균의 80% 미만이면 스퀴즈
}
```

### Average True Range (ATR)

ATR은 가격 변동성을 측정합니다:

```swift
let atr = indicators.averageTrueRange(period: 14)

if let currentATR = atr.last,
   let currentPrice = history.prices.last?.close {
    
    print("\n=== ATR 분석 ===")
    print("ATR (14): $\(String(format: "%.2f", currentATR))")
    
    let atrPercent = (currentATR / currentPrice) * 100
    print("ATR %: \(String(format: "%.2f", atrPercent))%")
    
    // 변동성 수준 평가
    switch atrPercent {
    case 4...:
        print("🌪️ 극도로 높은 변동성")
    case 2.5..<4:
        print("📈 높은 변동성")
    case 1.5..<2.5:
        print("📊 보통 변동성")
    case 1..<1.5:
        print("😴 낮은 변동성")
    default:
        print("💤 매우 낮은 변동성")
    }
    
    // ATR 기반 손절/익절 레벨 계산
    let stopLoss = currentPrice - (currentATR * 2)
    let takeProfit = currentPrice + (currentATR * 3)
    
    print("제안 손절가: $\(String(format: "%.2f", stopLoss)) (-\(String(format: "%.1f", (currentATR * 2 / currentPrice) * 100))%)")
    print("제안 익절가: $\(String(format: "%.2f", takeProfit)) (+\(String(format: "%.1f", (currentATR * 3 / currentPrice) * 100))%)")
}
```

## Volume Analysis (거래량 분석)

### Volume Moving Average

```swift
let volumeMA = indicators.volumeMovingAverage(period: 20)

if let currentVolume = history.prices.last?.volume,
   let averageVolume = volumeMA.last {
    
    print("\n=== 거래량 분석 ===")
    print("현재 거래량: \(currentVolume.formatted())")
    print("평균 거래량: \(Int(averageVolume).formatted())")
    
    let volumeRatio = Double(currentVolume) / averageVolume
    print("거래량 비율: \(String(format: "%.1fx", volumeRatio))")
    
    switch volumeRatio {
    case 2...:
        print("🚀 폭증한 거래량 (2배 이상)")
    case 1.5..<2:
        print("📈 증가한 거래량 (1.5-2배)")
    case 1.2..<1.5:
        print("📊 다소 증가한 거래량")
    case 0.5..<1.2:
        print("😐 정상 거래량")
    default:
        print("💤 저조한 거래량")
    }
}
```

### On-Balance Volume (OBV)

```swift
let obv = indicators.onBalanceVolume()

if obv.count >= 20 {
    let currentOBV = obv.last!
    let previousOBV = obv[obv.count - 2]
    let obvChange = currentOBV - previousOBV
    
    print("\n=== OBV 분석 ===")
    print("현재 OBV: \(Int(currentOBV).formatted())")
    print("OBV 변화: \(Int(obvChange).formatted())")
    
    if obvChange > 0 {
        print("💪 매수 압력 우세")
    } else if obvChange < 0 {
        print("💔 매도 압력 우세")
    } else {
        print("⚖️ 균형 상태")
    }
    
    // OBV 추세 분석 (최근 5일)
    let recentOBV = Array(obv.suffix(5))
    let obvTrend = recentOBV.last! - recentOBV.first!
    
    if obvTrend > 0 {
        print("📈 OBV 상승 추세 → 매수 관심 증가")
    } else {
        print("📉 OBV 하락 추세 → 매도 관심 증가")
    }
}
```

## Comprehensive Analysis (종합 분석)

여러 지표를 조합한 종합 분석:

```swift
func comprehensiveAnalysis(
    prices: [YFPrice],
    sma20: [Double],
    sma50: [Double],
    rsi: [Double],
    macdData: MACDData,
    bollingerBands: BollingerBandsData
) -> String {
    
    guard let currentPrice = prices.last?.close,
           let currentSMA20 = sma20.last,
           let currentSMA50 = sma50.last,
           let currentRSI = rsi.last,
           let macdLine = macdData.macd.last,
           let signalLine = macdData.signal.last,
           let upperBand = bollingerBands.upper.last,
           let lowerBand = bollingerBands.lower.last else {
        return "데이터 부족"
    }
    
    var signals: [String] = []
    var score = 0
    
    // 추세 분석
    if currentPrice > currentSMA20 && currentSMA20 > currentSMA50 {
        signals.append("✅ 상승 추세 (가격 > SMA20 > SMA50)")
        score += 2
    } else if currentPrice < currentSMA20 && currentSMA20 < currentSMA50 {
        signals.append("❌ 하락 추세 (가격 < SMA20 < SMA50)")
        score -= 2
    }
    
    // RSI 분석
    if currentRSI > 70 {
        signals.append("⚠️ RSI 과매수 (\(String(format: "%.1f", currentRSI)))")
        score -= 1
    } else if currentRSI < 30 {
        signals.append("💎 RSI 과매도 (\(String(format: "%.1f", currentRSI)))")
        score += 1
    }
    
    // MACD 분석
    if macdLine > signalLine {
        signals.append("📈 MACD 강세")
        score += 1
    } else {
        signals.append("📉 MACD 약세")
        score -= 1
    }
    
    // 볼린저 밴드 분석
    if currentPrice > upperBand {
        signals.append("🔥 볼린저 상단 돌파")
        score += 1
    } else if currentPrice < lowerBand {
        signals.append("❄️ 볼린저 하단 돌파")
        score -= 1
    }
    
    // 종합 판단
    let recommendation: String
    switch score {
    case 4...:
        recommendation = "🚀 강한 매수 신호"
    case 2..<4:
        recommendation = "📈 매수 신호"
    case -1..<2:
        recommendation = "😐 중립"
    case -3..<(-1):
        recommendation = "📉 매도 신호"
    default:
        recommendation = "💥 강한 매도 신호"
    }
    
    let analysis = """
    
    === 종합 기술적 분석 ===
    점수: \(score)/6
    \(recommendation)
    
    상세 시그널:
    \(signals.joined(separator: "\n"))
    """
    
    return analysis
}

// 종합 분석 실행
let analysis = comprehensiveAnalysis(
    prices: history.prices,
    sma20: sma20,
    sma50: sma50,
    rsi: rsi14,
    macdData: macdData,
    bollingerBands: bollingerBands
)

print(analysis)
```

## Next Steps

기술적 분석을 더 깊이 있게 활용하려면:

- <doc:AdvancedFeatures> - 고급 분석 도구들
- <doc:OptionsTrading> - 옵션을 활용한 기술적 분석
- <doc:BestPractices> - 백테스팅 및 리스크 관리
- <doc:PerformanceOptimization> - 대량 데이터 분석 최적화