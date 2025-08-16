# Options Trading

SwiftYFinance를 사용한 옵션 거래 데이터 분석

## Overview

옵션은 특정 자산을 미래의 정해진 날짜에 정해진 가격으로 사거나 팔 수 있는 권리를 거래하는 파생상품입니다. SwiftYFinance는 옵션 체인, Greeks, 변동성 등 옵션 거래에 필요한 모든 데이터를 제공합니다.

## Options Chain Analysis

### 기본 옵션 체인 조회

```swift
let ticker = YFTicker(symbol: "AAPL")
let optionsChain = try await client.fetchOptionsChain(ticker: ticker)

print("=== \(ticker.symbol) 옵션 체인 ===")
print("사용 가능한 만료일: \(optionsChain.expirationDates.count)개")

// 모든 만료일 출력
let formatter = DateFormatter()
formatter.dateStyle = .medium

for (index, expirationDate) in optionsChain.expirationDates.enumerated() {
    let daysToExpiry = Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day ?? 0
    print("\(index + 1). \(formatter.string(from: expirationDate)) (\(daysToExpiry)일 후)")
}
```

### 특정 만료일 옵션 분석

```swift
// 가장 가까운 만료일 선택
let nearestExpiry = optionsChain.expirationDates.first!
let options = try await client.fetchOptions(ticker: ticker, expirationDate: nearestExpiry)

let currentPrice = try await client.fetchQuote(ticker: ticker).regularMarketPrice

print("\n=== \(formatter.string(from: nearestExpiry)) 만료 옵션 ===")
print("기초자산 현재가: $\(String(format: "%.2f", currentPrice))")
print("콜 옵션: \(options.calls.count)개")
print("풋 옵션: \(options.puts.count)개")

// ATM(At The Money) 옵션 찾기
let atmStrike = options.calls.min(by: { abs($0.strike - currentPrice) < abs($1.strike - currentPrice) })?.strike ?? currentPrice

print("ATM 행사가: $\(String(format: "%.2f", atmStrike))")
```

### 옵션 Greeks 분석

```swift
// ATM 콜 옵션 Greeks 분석
if let atmCall = options.calls.first(where: { $0.strike == atmStrike }) {
    print("\n=== ATM 콜 옵션 Greeks ===")
    print("행사가: $\(String(format: "%.2f", atmCall.strike))")
    print("현재가: $\(String(format: "%.2f", atmCall.lastPrice))")
    print("내재변동성: \(String(format: "%.1f", (atmCall.impliedVolatility ?? 0) * 100))%")
    
    if let delta = atmCall.delta {
        print("Delta: \(String(format: "%.4f", delta))")
        print("  → 기초자산이 $1 오르면 옵션은 $\(String(format: "%.2f", delta)) 상승")
    }
    
    if let gamma = atmCall.gamma {
        print("Gamma: \(String(format: "%.6f", gamma))")
        print("  → 기초자산이 $1 오르면 Delta는 \(String(format: "%.6f", gamma)) 증가")
    }
    
    if let theta = atmCall.theta {
        print("Theta: \(String(format: "%.4f", theta))")
        print("  → 하루가 지나면 옵션은 $\(String(format: "%.2f", abs(theta))) 하락")
    }
    
    if let vega = atmCall.vega {
        print("Vega: \(String(format: "%.4f", vega))")
        print("  → 변동성이 1% 오르면 옵션은 $\(String(format: "%.2f", vega)) 상승")
    }
    
    if let rho = atmCall.rho {
        print("Rho: \(String(format: "%.4f", rho))")
        print("  → 금리가 1% 오르면 옵션은 $\(String(format: "%.2f", rho)) 상승")
    }
}
```

## Volatility Analysis

### 내재변동성 분석

```swift
let callIVs = options.calls.compactMap { $0.impliedVolatility }
let putIVs = options.puts.compactMap { $0.impliedVolatility }

if !callIVs.isEmpty && !putIVs.isEmpty {
    let avgCallIV = callIVs.reduce(0, +) / Double(callIVs.count) * 100
    let avgPutIV = putIVs.reduce(0, +) / Double(putIVs.count) * 100
    
    print("\n=== 변동성 분석 ===")
    print("평균 콜 내재변동성: \(String(format: "%.1f", avgCallIV))%")
    print("평균 풋 내재변동성: \(String(format: "%.1f", avgPutIV))%")
    
    let skew = avgPutIV - avgCallIV
    print("변동성 스큐: \(String(format: "%.1f", skew))%")
    
    if skew > 2 {
        print("📉 풋 변동성이 높음 → 하락 리스크 우려")
    } else if skew < -2 {
        print("📈 콜 변동성이 높음 → 상승 기대감")
    } else {
        print("😐 변동성 스큐 정상 수준")
    }
}
```

### 변동성 스마일 분석

```swift
func analyzeVolatilitySmile(options: [YFOptionContract]) {
    let sortedOptions = options.sorted(by: { $0.strike < $1.strike })
    
    print("\n=== 변동성 스마일 ===")
    print("행사가\t\t내재변동성\t몬니니스")
    
    for option in sortedOptions {
        guard let iv = option.impliedVolatility else { continue }
        
        let moneyness = option.strike / currentPrice
        let ivPercent = iv * 100
        
        print("\(String(format: "%.0f", option.strike))\t\t\(String(format: "%.1f", ivPercent))%\t\t\(String(format: "%.3f", moneyness))")
    }
    
    // ITM, ATM, OTM 구분별 평균 IV
    let itmOptions = sortedOptions.filter { $0.strike < currentPrice }
    let atmOptions = sortedOptions.filter { abs($0.strike - currentPrice) <= 5 }
    let otmOptions = sortedOptions.filter { $0.strike > currentPrice }
    
    let itmAvgIV = itmOptions.compactMap { $0.impliedVolatility }.reduce(0, +) / Double(itmOptions.count) * 100
    let atmAvgIV = atmOptions.compactMap { $0.impliedVolatility }.reduce(0, +) / Double(atmOptions.count) * 100
    let otmAvgIV = otmOptions.compactMap { $0.impliedVolatility }.reduce(0, +) / Double(otmOptions.count) * 100
    
    print("\nITM 평균 IV: \(String(format: "%.1f", itmAvgIV))%")
    print("ATM 평균 IV: \(String(format: "%.1f", atmAvgIV))%")
    print("OTM 평균 IV: \(String(format: "%.1f", otmAvgIV))%")
}

analyzeVolatilitySmile(options: options.calls)
```

## Options Trading Strategies

### Long Call 분석

```swift
func analyzeLongCall(option: YFOptionContract, currentPrice: Double) -> String {
    let premium = option.lastPrice
    let breakeven = option.strike + premium
    let maxLoss = premium
    
    let timeToExpiry = Calendar.current.dateComponents([.day], from: Date(), to: nearestExpiry).day ?? 0
    
    var analysis = """
    
    === Long Call 전략 분석 ===
    행사가: $\(String(format: "%.2f", option.strike))
    프리미엄: $\(String(format: "%.2f", premium))
    손익분기점: $\(String(format: "%.2f", breakeven))
    최대손실: $\(String(format: "%.2f", maxLoss))
    만료까지: \(timeToExpiry)일
    """
    
    // 수익률 시나리오
    let scenarios = [0.95, 1.0, 1.05, 1.1, 1.15]
    analysis += "\n\n가격 시나리오별 손익:"
    
    for scenario in scenarios {
        let futurePrice = currentPrice * scenario
        let intrinsicValue = max(0, futurePrice - option.strike)
        let profit = intrinsicValue - premium
        let profitPercent = (profit / premium) * 100
        
        analysis += "\n$\(String(format: "%.2f", futurePrice)) → "
        analysis += "손익: $\(String(format: "%.2f", profit)) (\(String(format: "%.1f", profitPercent))%)"
    }
    
    // 델타 기반 확률 추정
    if let delta = option.delta {
        let probability = delta * 100
        analysis += "\n\nITM 확률 (Delta 기준): \(String(format: "%.1f", probability))%"
    }
    
    return analysis
}

// ATM 콜 옵션 분석
if let atmCall = options.calls.first(where: { abs($0.strike - currentPrice) <= 5 }) {
    print(analyzeLongCall(option: atmCall, currentPrice: currentPrice))
}
```

### Covered Call 분석

```swift
func analyzeCoveredCall(
    stockPrice: Double,
    callOption: YFOptionContract,
    sharesOwned: Int = 100
) -> String {
    
    let premium = callOption.lastPrice * Double(sharesOwned)
    let maxProfit = (callOption.strike - stockPrice) * Double(sharesOwned) + premium
    let maxLoss = stockPrice * Double(sharesOwned) - premium
    let breakeven = stockPrice - callOption.lastPrice
    
    var analysis = """
    
    === Covered Call 전략 분석 ===
    주식 보유: \(sharesOwned)주 @ $\(String(format: "%.2f", stockPrice))
    콜 매도: \(sharesOwned/100)계약 @ $\(String(format: "%.2f", callOption.lastPrice))
    행사가: $\(String(format: "%.2f", callOption.strike))
    
    프리미엄 수입: $\(String(format: "%.2f", premium))
    최대 수익: $\(String(format: "%.2f", maxProfit))
    손익분기점: $\(String(format: "%.2f", breakeven))
    """
    
    // 수익률 분석
    let returnOnStock = (maxProfit / (stockPrice * Double(sharesOwned))) * 100
    analysis += "\n주식 대비 수익률: \(String(format: "%.2f", returnOnStock))%"
    
    // 시나리오 분석
    let scenarios = [0.9, 0.95, 1.0, 1.05, 1.1]
    analysis += "\n\n가격 시나리오별 손익:"
    
    for scenario in scenarios {
        let futurePrice = stockPrice * scenario
        let stockPnL = (futurePrice - stockPrice) * Double(sharesOwned)
        
        let callPnL: Double
        if futurePrice > callOption.strike {
            // 콜 옵션 행사됨
            callPnL = premium - (futurePrice - callOption.strike) * Double(sharesOwned)
        } else {
            // 콜 옵션 만료
            callPnL = premium
        }
        
        let totalPnL = stockPnL + callPnL
        
        analysis += "\n$\(String(format: "%.2f", futurePrice)) → "
        analysis += "총손익: $\(String(format: "%.2f", totalPnL))"
    }
    
    return analysis
}

// OTM 콜 옵션으로 커버드 콜 분석
if let otmCall = options.calls.first(where: { $0.strike > currentPrice + 5 }) {
    print(analyzeCoveredCall(stockPrice: currentPrice, callOption: otmCall))
}
```

### Iron Condor 분석

```swift
func analyzeIronCondor(
    lowerPutStrike: Double,
    higherPutStrike: Double,
    lowerCallStrike: Double,
    higherCallStrike: Double,
    options: YFOptionsData
) -> String {
    
    // 필요한 옵션들 찾기
    guard let shortPut = options.puts.first(where: { $0.strike == higherPutStrike }),
          let longPut = options.puts.first(where: { $0.strike == lowerPutStrike }),
          let shortCall = options.calls.first(where: { $0.strike == lowerCallStrike }),
          let longCall = options.calls.first(where: { $0.strike == higherCallStrike }) else {
        return "필요한 옵션을 찾을 수 없습니다."
    }
    
    // 프리미엄 계산 (매도 옵션에서 받는 프리미엄 - 매수 옵션에 지불하는 프리미엄)
    let netCredit = shortPut.lastPrice + shortCall.lastPrice - longPut.lastPrice - longCall.lastPrice
    let maxProfit = netCredit * 100 // 1계약 기준
    let maxLoss = ((higherPutStrike - lowerPutStrike) - netCredit) * 100
    
    let lowerBreakeven = higherPutStrike - netCredit
    let upperBreakeven = lowerCallStrike + netCredit
    
    var analysis = """
    
    === Iron Condor 전략 분석 ===
    풋 스프레드: $\(String(format: "%.0f", lowerPutStrike))/$\(String(format: "%.0f", higherPutStrike))
    콜 스프레드: $\(String(format: "%.0f", lowerCallStrike))/$\(String(format: "%.0f", higherCallStrike))
    
    순 크레딧: $\(String(format: "%.2f", netCredit))
    최대 수익: $\(String(format: "%.2f", maxProfit))
    최대 손실: $\(String(format: "%.2f", maxLoss))
    
    손익분기점: $\(String(format: "%.2f", lowerBreakeven)) ~ $\(String(format: "%.2f", upperBreakeven))
    수익 구간 폭: $\(String(format: "%.2f", upperBreakeven - lowerBreakeven))
    """
    
    // 현재 가격 대비 분석
    let priceRange = upperBreakeven - lowerBreakeven
    let profitZonePercent = (priceRange / currentPrice) * 100
    
    analysis += "\n현재가 기준 수익구간: ±\(String(format: "%.1f", profitZonePercent/2))%"
    
    // 성공 확률 추정 (단순화된 계산)
    if currentPrice >= lowerBreakeven && currentPrice <= upperBreakeven {
        analysis += "\n현재 수익 구간 내 위치 ✅"
    } else {
        analysis += "\n현재 수익 구간 밖 위치 ⚠️"
    }
    
    return analysis
}

// 대표적인 Iron Condor 구성
let ironCondorAnalysis = analyzeIronCondor(
    lowerPutStrike: currentPrice - 20,
    higherPutStrike: currentPrice - 10,
    lowerCallStrike: currentPrice + 10,
    higherCallStrike: currentPrice + 20,
    options: options
)

print(ironCondorAnalysis)
```

## Options Screening

### 고변동성 옵션 찾기

```swift
func findHighIVOptions(options: [YFOptionContract], threshold: Double = 0.5) -> [YFOptionContract] {
    return options.filter { option in
        guard let iv = option.impliedVolatility else { return false }
        return iv > threshold
    }.sorted { $0.impliedVolatility! > $1.impliedVolatility! }
}

let highIVCalls = findHighIVOptions(options: options.calls, threshold: 0.4)
let highIVPuts = findHighIVOptions(options: options.puts, threshold: 0.4)

print("\n=== 고변동성 옵션 Top 5 ===")
print("콜 옵션:")
for (index, option) in highIVCalls.prefix(5).enumerated() {
    let iv = (option.impliedVolatility ?? 0) * 100
    print("\(index + 1). $\(String(format: "%.0f", option.strike)) - IV: \(String(format: "%.1f", iv))%")
}

print("\n풋 옵션:")
for (index, option) in highIVPuts.prefix(5).enumerated() {
    let iv = (option.impliedVolatility ?? 0) * 100
    print("\(index + 1). $\(String(format: "%.0f", option.strike)) - IV: \(String(format: "%.1f", iv))%")
}
```

### 거래량 기반 옵션 스크리닝

```swift
func findLiquidOptions(options: [YFOptionContract], minVolume: Int = 100) -> [YFOptionContract] {
    return options.filter { $0.volume >= minVolume }
                 .sorted { $0.volume > $1.volume }
}

let liquidCalls = findLiquidOptions(options: options.calls, minVolume: 50)

print("\n=== 거래량 상위 옵션 ===")
for (index, option) in liquidCalls.prefix(10).enumerated() {
    print("\(index + 1). $\(String(format: "%.0f", option.strike)) - 거래량: \(option.volume), 호가스프레드: \(String(format: "%.2f", option.ask - option.bid))")
}
```

## Risk Management

### 포지션 사이징

```swift
func calculatePositionSize(
    accountValue: Double,
    riskPercentage: Double,
    optionPrice: Double,
    maxLossPerContract: Double
) -> Int {
    
    let maxRiskAmount = accountValue * (riskPercentage / 100)
    let maxContracts = Int(maxRiskAmount / maxLossPerContract)
    
    print("\n=== 포지션 사이징 ===")
    print("계좌 금액: $\(String(format: "%.0f", accountValue))")
    print("리스크 한도: \(String(format: "%.1f", riskPercentage))% ($\(String(format: "%.0f", maxRiskAmount)))")
    print("옵션 가격: $\(String(format: "%.2f", optionPrice))")
    print("계약당 최대손실: $\(String(format: "%.2f", maxLossPerContract))")
    print("권장 계약 수: \(maxContracts)개")
    print("총 투자금액: $\(String(format: "%.2f", Double(maxContracts) * optionPrice * 100))")
    
    return maxContracts
}

// 예시: 10만 달러 계좌에서 2% 리스크
let recommendedContracts = calculatePositionSize(
    accountValue: 100_000,
    riskPercentage: 2,
    optionPrice: atmCall?.lastPrice ?? 0,
    maxLossPerContract: (atmCall?.lastPrice ?? 0) * 100
)
```

### Greeks 기반 포트폴리오 리스크

```swift
func calculatePortfolioGreeks(positions: [(option: YFOptionContract, quantity: Int)]) -> (totalDelta: Double, totalGamma: Double, totalTheta: Double, totalVega: Double) {
    
    var totalDelta: Double = 0
    var totalGamma: Double = 0
    var totalTheta: Double = 0
    var totalVega: Double = 0
    
    for position in positions {
        let multiplier = Double(position.quantity) * 100 // 1계약 = 100주
        
        totalDelta += (position.option.delta ?? 0) * multiplier
        totalGamma += (position.option.gamma ?? 0) * multiplier
        totalTheta += (position.option.theta ?? 0) * multiplier
        totalVega += (position.option.vega ?? 0) * multiplier
    }
    
    return (totalDelta, totalGamma, totalTheta, totalVega)
}

// 예시 포트폴리오
let portfolioPositions: [(option: YFOptionContract, quantity: Int)] = [
    (atmCall!, 5),  // 5계약 매수
    // 추가 포지션들...
]

let portfolioGreeks = calculatePortfolioGreeks(positions: portfolioPositions)

print("\n=== 포트폴리오 Greeks ===")
print("Total Delta: \(String(format: "%.2f", portfolioGreeks.totalDelta))")
print("Total Gamma: \(String(format: "%.4f", portfolioGreeks.totalGamma))")
print("Total Theta: \(String(format: "%.2f", portfolioGreeks.totalTheta))")
print("Total Vega: \(String(format: "%.2f", portfolioGreeks.totalVega))")

print("\n리스크 분석:")
print("• 기초자산 $1 변동 시 포트폴리오 변화: $\(String(format: "%.2f", portfolioGreeks.totalDelta))")
print("• 하루 시간가치 손실: $\(String(format: "%.2f", abs(portfolioGreeks.totalTheta)))")
print("• 변동성 1% 변화 시 포트폴리오 변화: $\(String(format: "%.2f", portfolioGreeks.totalVega))")
```

## Next Steps

옵션 거래를 더 깊이 있게 활용하려면:

- <doc:AdvancedFeatures> - 추가 옵션 분석 도구들
- <doc:TechnicalAnalysis> - 기술적 분석과 옵션 조합
- <doc:BestPractices> - 옵션 백테스팅 및 리스크 관리
- <doc:ErrorHandling> - 포트폴리오 리스크 관리 심화