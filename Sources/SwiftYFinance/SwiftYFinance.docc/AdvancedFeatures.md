# Advanced Features

SwiftYFinance의 고급 기능들을 활용하는 방법

## Overview

SwiftYFinance는 기본적인 주식 시세 조회를 넘어서 옵션 거래, 기술적 분석, 뉴스 분석, 종목 스크리닝 등 다양한 고급 기능을 제공합니다. 이 가이드에서는 이러한 고급 기능들을 효과적으로 활용하는 방법을 설명합니다.

## Options Data

옵션 거래 데이터를 가져오고 분석하는 방법:

### Options Chain 조회

```swift
let ticker = YFTicker(symbol: "AAPL")
let optionsChain = try await client.fetchOptionsChain(ticker: ticker)

print("만료일: \(optionsChain.expirationDates.count)개")

for expirationDate in optionsChain.expirationDates.prefix(3) {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    print("만료일: \(formatter.string(from: expirationDate))")
    
    // 특정 만료일의 옵션 데이터
    let options = try await client.fetchOptions(
        ticker: ticker,
        expirationDate: expirationDate
    )
    
    print("  콜 옵션: \(options.calls.count)개")
    print("  풋 옵션: \(options.puts.count)개")
    
    // 가장 거래량이 많은 콜 옵션
    if let topCall = options.calls.max(by: { $0.volume < $1.volume }) {
        print("  최대 거래량 콜: \(topCall.strike) @ \(topCall.lastPrice)")
    }
}
```

### Greeks 분석

```swift
for call in options.calls.prefix(5) {
    print("\n행사가: $\(call.strike)")
    print("현재가: $\(call.lastPrice)")
    
    if let delta = call.delta {
        print("Delta: \(String(format: "%.4f", delta))")
    }
    if let gamma = call.gamma {
        print("Gamma: \(String(format: "%.6f", gamma))")
    }
    if let theta = call.theta {
        print("Theta: \(String(format: "%.4f", theta))")
    }
    if let vega = call.vega {
        print("Vega: \(String(format: "%.4f", vega))")
    }
}
```

## Technical Analysis

기술적 분석 지표를 계산하고 활용하는 방법:

### 이동평균선

```swift
let history = try await client.fetchHistory(
    ticker: ticker,
    period: .sixMonths,
    interval: .oneDay
)

let indicators = YFTechnicalIndicators(prices: history.prices)

// 단순 이동평균 (SMA)
let sma20 = indicators.simpleMovingAverage(period: 20)
let sma50 = indicators.simpleMovingAverage(period: 50)

print("SMA-20: \(String(format: "%.2f", sma20.last ?? 0))")
print("SMA-50: \(String(format: "%.2f", sma50.last ?? 0))")

// 지수 이동평균 (EMA)
let ema12 = indicators.exponentialMovingAverage(period: 12)
let ema26 = indicators.exponentialMovingAverage(period: 26)

print("EMA-12: \(String(format: "%.2f", ema12.last ?? 0))")
print("EMA-26: \(String(format: "%.2f", ema26.last ?? 0))")
```

### RSI (Relative Strength Index)

```swift
let rsi = indicators.relativeStrengthIndex(period: 14)
let currentRSI = rsi.last ?? 0

print("RSI (14): \(String(format: "%.2f", currentRSI))")

if currentRSI > 70 {
    print("⚠️ 과매수 구간")
} else if currentRSI < 30 {
    print("📈 과매도 구간")
} else {
    print("😐 중립 구간")
}
```

### MACD

```swift
let macdData = indicators.macd(fastPeriod: 12, slowPeriod: 26, signalPeriod: 9)

if let lastMACD = macdData.macd.last,
   let lastSignal = macdData.signal.last,
   let lastHistogram = macdData.histogram.last {
    
    print("MACD: \(String(format: "%.4f", lastMACD))")
    print("Signal: \(String(format: "%.4f", lastSignal))")
    print("Histogram: \(String(format: "%.4f", lastHistogram))")
    
    if lastMACD > lastSignal {
        print("📈 강세 신호")
    } else {
        print("📉 약세 신호")
    }
}
```

### 볼린저 밴드

```swift
let bollingerBands = indicators.bollingerBands(period: 20, standardDeviations: 2)

if let upper = bollingerBands.upper.last,
   let middle = bollingerBands.middle.last,
   let lower = bollingerBands.lower.last,
   let currentPrice = history.prices.last?.close {
    
    print("상단 밴드: $\(String(format: "%.2f", upper))")
    print("중간 밴드: $\(String(format: "%.2f", middle))")
    print("하단 밴드: $\(String(format: "%.2f", lower))")
    print("현재 가격: $\(String(format: "%.2f", currentPrice))")
    
    let position = (currentPrice - lower) / (upper - lower)
    print("밴드 내 위치: \(String(format: "%.1f", position * 100))%")
}
```

## News & Sentiment Analysis

뉴스 데이터와 감성 분석:

### 종목 뉴스 조회

```swift
let news = try await client.fetchNews(ticker: ticker, limit: 10)

print("최근 뉴스 \(news.articles.count)건:")

for article in news.articles.prefix(5) {
    print("\n제목: \(article.title)")
    print("출처: \(article.publisher)")
    
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    print("시간: \(formatter.string(from: article.publishTime))")
    
    if let sentiment = article.sentiment {
        let sentimentText = sentiment > 0.1 ? "긍정적" : sentiment < -0.1 ? "부정적" : "중립적"
        print("감성: \(sentimentText) (\(String(format: "%.2f", sentiment)))")
    }
    
    print("요약: \(article.summary)")
}
```

### 감성 분석 집계

```swift
let sentiments = news.articles.compactMap { $0.sentiment }
let averageSentiment = sentiments.reduce(0, +) / Double(sentiments.count)

print("\n전체 뉴스 감성 분석:")
print("분석된 기사: \(sentiments.count)건")
print("평균 감성: \(String(format: "%.3f", averageSentiment))")

let positiveCount = sentiments.filter { $0 > 0.1 }.count
let negativeCount = sentiments.filter { $0 < -0.1 }.count
let neutralCount = sentiments.count - positiveCount - negativeCount

print("긍정적: \(positiveCount)건 (\(String(format: "%.1f", Double(positiveCount) / Double(sentiments.count) * 100))%)")
print("부정적: \(negativeCount)건 (\(String(format: "%.1f", Double(negativeCount) / Double(sentiments.count) * 100))%)")
print("중립적: \(neutralCount)건 (\(String(format: "%.1f", Double(neutralCount) / Double(sentiments.count) * 100))%)")
```

## Stock Screening

특정 조건에 맞는 종목들을 찾는 방법:

### 기본 스크리닝

```swift
let screener = YFScreener()

// 대형주 + 높은 배당수익률 조건
let criteria = YFScreeningCriteria(
    marketCap: .large,
    dividendYield: .high,
    peRatio: .reasonable,
    sector: .technology
)

let results = try await screener.screen(criteria: criteria, limit: 20)

print("스크리닝 결과: \(results.stocks.count)개 종목")

for stock in results.stocks.prefix(10) {
    print("\n\(stock.symbol): \(stock.name)")
    print("시가총액: $\(stock.marketCap / 1_000_000_000)B")
    print("배당수익률: \(String(format: "%.2f", stock.dividendYield))%")
    print("P/E 비율: \(String(format: "%.1f", stock.peRatio))")
    print("섹터: \(stock.sector)")
}
```

### 고급 스크리닝

```swift
// 커스텀 필터링 조건
let advancedCriteria = YFScreeningCriteria(
    priceRange: 50...200,
    volumeMin: 1_000_000,
    rsiRange: 30...70,
    macdSignal: .bullish,
    revenueGrowth: .positive
)

let growthStocks = try await screener.screen(criteria: advancedCriteria)

for stock in growthStocks.stocks {
    // 추가 분석을 위해 상세 데이터 조회
    let ticker = YFTicker(symbol: stock.symbol)
    let quote = try await client.fetchQuote(ticker: ticker)
    let financials = try await client.fetchFinancials(ticker: ticker)
    
    print("\n=== \(stock.symbol) 분석 ===")
    print("현재가: $\(quote.regularMarketPrice)")
    print("52주 변동률: \(String(format: "%.1f", quote.fiftyTwoWeekChangePercent ?? 0))%")
    
    if let latestRevenue = financials.annualReports.first?.totalRevenue,
       let previousRevenue = financials.annualReports[safe: 1]?.totalRevenue {
        let revenueGrowth = (Double(latestRevenue - previousRevenue) / Double(previousRevenue)) * 100
        print("매출 성장률: \(String(format: "%.1f", revenueGrowth))%")
    }
    
    // Rate limiting
    try await Task.sleep(nanoseconds: 300_000_000) // 0.3초
}
```

## Real-time WebSocket Streaming

실시간 WebSocket 스트리밍으로 주식 데이터를 실시간으로 수신:

### 기본 WebSocket 연결

```swift
let manager = YFWebSocketManager()

// 연결 시작
try await manager.connect()

// 연결 상태 확인
let connectionState = await manager.connectionState
print("연결 상태: \(connectionState)")
```

### 실시간 데이터 스트리밍

```swift
// 심볼 구독
try await manager.subscribe(symbols: ["AAPL", "GOOGL", "MSFT"])

// 실시간 데이터 수신
for await priceUpdate in manager.priceStream {
    print("📈 \(priceUpdate.symbol): $\(priceUpdate.price)")
    print("변동: \(priceUpdate.changePercent)%")
    print("시간: \(priceUpdate.timestamp)")
}
```

### 구독 관리

```swift
// 추가 심볼 구독
try await manager.subscribe(symbols: ["TSLA", "NVDA"])

// 특정 심볼 구독 해제
try await manager.unsubscribe(symbols: ["GOOGL"])

// 현재 구독 목록 확인
let subscriptions = await manager.subscriptions
print("구독 중인 심볼: \(subscriptions)")

// 모든 구독 해제
try await manager.unsubscribeAll()
```

### 연결 품질 모니터링

```swift
// 연결 품질 메트릭 확인
let quality = await manager.connectionQuality
print("연결 성공률: \(String(format: "%.1f", quality.successRate * 100))%")
print("평균 지연시간: \(String(format: "%.0f", quality.averageLatency * 1000))ms")
print("메시지 수신률: \(String(format: "%.1f", quality.messageRate))개/분")

// 에러 로그 확인
let errorLog = await manager.errorLog
for entry in errorLog.prefix(5) {
    print("❌ \(entry.timestamp): \(entry.error.localizedDescription)")
}
```

### 자동 재연결 및 에러 처리

```swift
// 자동 재연결 설정 (기본적으로 활성화)
manager.enableAutoReconnect = true

// 연결 상태 변화 모니터링
Task {
    for await state in manager.connectionStateStream {
        switch state {
        case .connected:
            print("✅ WebSocket 연결됨")
        case .connecting:
            print("🔄 WebSocket 연결 중...")
        case .disconnected:
            print("⏸️ WebSocket 연결 해제됨")
        case .failed:
            print("❌ WebSocket 연결 실패")
        }
    }
}

// 수동 재연결
if await manager.connectionState == .failed {
    try await manager.reconnect()
}
```

### 동시성 안전성

SwiftYFinance WebSocket은 Swift의 최신 동시성 모델을 준수합니다:

```swift
// ✅ 모든 상태 접근은 Thread-safe
let connectionState = await manager.connectionState
let subscriptions = await manager.subscriptions

// ✅ Actor 격리를 통한 안전한 상태 관리
try await manager.subscribe(symbols: ["AAPL"])
try await manager.unsubscribe(symbols: ["AAPL"])

// ✅ AsyncStream을 통한 안전한 데이터 스트리밍
for await update in manager.priceStream {
    // 메인 스레드나 어떤 스레드에서든 안전하게 처리
    await updateUI(with: update)
}
```

## Protobuf 지원

SwiftYFinance는 Yahoo Finance의 고성능 Protobuf 데이터 스트림을 지원합니다.

### Protobuf 개요

Yahoo Finance는 일부 실시간 데이터를 Protocol Buffers 형식으로 제공합니다. 이는 JSON보다 훨씬 효율적이고 빠른 데이터 전송을 가능하게 합니다.

### 지원되는 데이터 타입

```swift
// Protobuf로 제공되는 실시간 가격 데이터
struct PricingData {
    let id: String
    let price: Double
    let time: UInt64
    let currency: String
    let exchange: String
    
    // Protobuf 디코딩
    init(from protobufData: Data) throws {
        let pricingData = try Yfinance_PricingData(serializedBytes: protobufData)
        self.id = pricingData.id
        self.price = pricingData.price
        self.time = pricingData.time
        self.currency = pricingData.currency
        self.exchange = pricingData.exchange
    }
}
```

### 실시간 Protobuf 스트리밍

```swift
class YFProtobufStream {
    private let webSocket: YFWebSocketManager
    
    init() {
        self.webSocket = YFWebSocketManager()
    }
    
    func startProtobufStream(symbols: [String]) async throws {
        try await webSocket.connect()
        
        // Protobuf 스트림 구독
        try await webSocket.subscribeProtobuf(symbols: symbols)
        
        // 실시간 Protobuf 데이터 수신
        for await data in webSocket.protobufStream {
            do {
                let pricingData = try PricingData(from: data)
                print("Protobuf Data - \(pricingData.id): $\(pricingData.price)")
            } catch {
                print("Protobuf 디코딩 에러: \(error)")
            }
        }
    }
}

// 사용 예제
let protobufStream = YFProtobufStream()
try await protobufStream.startProtobufStream(symbols: ["AAPL", "GOOGL"])
```

### 성능 비교: JSON vs Protobuf

```swift
// 성능 벤치마크 예제
func benchmarkDataFormats() async {
    let symbols = ["AAPL", "GOOGL", "MSFT", "AMZN", "TSLA"]
    
    // JSON 방식 측정
    let jsonStartTime = Date()
    let jsonClient = YFClient()
    for symbol in symbols {
        let ticker = YFTicker(symbol: symbol)
        _ = try await jsonClient.fetchQuote(ticker: ticker)
    }
    let jsonDuration = Date().timeIntervalSince(jsonStartTime)
    
    // Protobuf 방식 측정
    let protobufStartTime = Date()
    let protobufStream = YFProtobufStream()
    try await protobufStream.startProtobufStream(symbols: symbols)
    let protobufDuration = Date().timeIntervalSince(protobufStartTime)
    
    print("JSON Duration: \(jsonDuration)s")
    print("Protobuf Duration: \(protobufDuration)s")
    print("Performance Improvement: \(String(format: "%.1f", jsonDuration / protobufDuration))x")
}
```

**일반적인 성능 향상:**
- **데이터 크기**: 30-50% 감소
- **파싱 속도**: 2-3배 향상
- **메모리 사용량**: 20-30% 감소
- **네트워크 대역폭**: 40-60% 절약

### Protobuf 스키마 정보

SwiftYFinance에서 사용하는 Protobuf 스키마:

```protobuf
// PricingData.proto
syntax = "proto3";

package yfinance;

message PricingData {
  string id = 1;
  double price = 2;
  uint64 time = 3;
  string currency = 4;
  string exchange = 5;
  double change = 6;
  double changePercent = 7;
  uint64 volume = 8;
  double dayHigh = 9;
  double dayLow = 10;
}

message QuoteBundle {
  repeated PricingData quotes = 1;
}
```

### 고급 Protobuf 기능

#### 배치 처리
```swift
// 여러 종목의 Protobuf 데이터를 배치로 처리
func processBatchProtobuf(data: Data) throws -> [PricingData] {
    let bundle = try Yfinance_QuoteBundle(serializedBytes: data)
    return bundle.quotes.map { protobufQuote in
        PricingData(from: protobufQuote)
    }
}
```

#### 압축 지원
```swift
// gzip 압축된 Protobuf 데이터 처리
func processCompressedProtobuf(compressedData: Data) throws -> PricingData {
    let decompressedData = try decompressGzip(compressedData)
    return try PricingData(from: decompressedData)
}
```

#### 스트림 유효성 검증
```swift
// Protobuf 데이터 무결성 검증
extension PricingData {
    var isValid: Bool {
        return !id.isEmpty &&
               price > 0 &&
               time > 0 &&
               !currency.isEmpty &&
               !exchange.isEmpty
    }
}
```

## 메트릭 시스템

SwiftYFinance는 포괄적인 메트릭 시스템을 제공하여 재무 분석을 위한 다양한 지표를 계산할 수 있습니다.

### 내장 메트릭 로더

```swift
// 사용 가능한 모든 메트릭 로드
let metricsLoader = YFMetricsLoader()
let availableMetrics = try await metricsLoader.loadAvailableMetrics()

print("사용 가능한 메트릭 수: \(availableMetrics.count)")

// 카테고리별 메트릭 분류
let incomeStatementMetrics = availableMetrics.filter { $0.category == "IncomeStatement" }
let balanceSheetMetrics = availableMetrics.filter { $0.category == "BalanceSheet" }
let cashFlowMetrics = availableMetrics.filter { $0.category == "CashFlow" }
let valuationMetrics = availableMetrics.filter { $0.category == "Valuation" }

print("손익계산서 메트릭: \(incomeStatementMetrics.count)개")
print("대차대조표 메트릭: \(balanceSheetMetrics.count)개")
print("현금흐름 메트릭: \(cashFlowMetrics.count)개")
print("밸류에이션 메트릭: \(valuationMetrics.count)개")
```

### FundamentalsMetrics.json 활용

SwiftYFinance는 500+ 개의 재무 메트릭 정의를 포함하는 `FundamentalsMetrics.json` 파일을 제공합니다:

```swift
// 메트릭 메타데이터 조회
struct MetricDefinition {
    let name: String
    let description: String
    let category: String
    let dataType: String
    let frequency: String // quarterly, annual, ttm
    let unit: String? // currency, percentage, ratio, count
}

// 특정 메트릭 정보 조회
func getMetricInfo(metricName: String) -> MetricDefinition? {
    return metricsLoader.getMetricDefinition(name: metricName)
}

// 예시
if let revenueMetric = getMetricInfo(metricName: "TotalRevenue") {
    print("메트릭명: \(revenueMetric.name)")
    print("설명: \(revenueMetric.description)")
    print("카테고리: \(revenueMetric.category)")
    print("데이터 타입: \(revenueMetric.dataType)")
    print("빈도: \(revenueMetric.frequency)")
    print("단위: \(revenueMetric.unit ?? "없음")")
}
```

### 동적 메트릭 조회

```swift
// 동적으로 원하는 메트릭들만 조회
let fundamentalsService = YFFundamentalsTimeseriesService()

// 핵심 재무 메트릭들
let coreMetrics = [
    "TotalRevenue",
    "NetIncome",
    "TotalAssets",
    "TotalDebt",
    "FreeCashFlow",
    "OperatingCashFlow",
    "BookValue",
    "DilutedEPS"
]

let ticker = YFTicker(symbol: "AAPL")
let timeseriesData = try await fundamentalsService.fetchTimeseries(
    ticker: ticker,
    metrics: coreMetrics
)

// 시계열 데이터 분석
for metric in coreMetrics {
    if let series = timeseriesData.timeseries[metric] {
        print("\n=== \(metric) ===")
        
        // 최근 4개 분기 데이터
        let recentData = series.suffix(4)
        for dataPoint in recentData {
            print("Q\(dataPoint.quarter) \(dataPoint.year): \(dataPoint.value)")
        }
        
        // 성장률 계산
        if let latest = series.last, let yearAgo = series.dropLast(4).last {
            let growthRate = ((latest.value - yearAgo.value) / yearAgo.value) * 100
            print("YoY 성장률: \(String(format: "%.1f", growthRate))%")
        }
    }
}
```

### 커스텀 메트릭 계산

```swift
// 사용자 정의 메트릭 계산 엔진
class CustomMetricsCalculator {
    let fundamentalsService = YFFundamentalsTimeseriesService()
    
    // ROE (Return on Equity) 계산
    func calculateROE(ticker: YFTicker) async throws -> Double? {
        let metrics = ["NetIncome", "ShareholdersEquity"]
        let data = try await fundamentalsService.fetchTimeseries(ticker: ticker, metrics: metrics)
        
        guard let netIncome = data.timeseries["NetIncome"]?.last?.value,
              let equity = data.timeseries["ShareholdersEquity"]?.last?.value,
              equity > 0 else { return nil }
        
        return (netIncome / equity) * 100
    }
    
    // 부채비율 계산
    func calculateDebtToEquity(ticker: YFTicker) async throws -> Double? {
        let metrics = ["TotalDebt", "ShareholdersEquity"]
        let data = try await fundamentalsService.fetchTimeseries(ticker: ticker, metrics: metrics)
        
        guard let debt = data.timeseries["TotalDebt"]?.last?.value,
              let equity = data.timeseries["ShareholdersEquity"]?.last?.value,
              equity > 0 else { return nil }
        
        return debt / equity
    }
    
    // 현금전환주기 계산 (Cash Conversion Cycle)
    func calculateCashConversionCycle(ticker: YFTicker) async throws -> Double? {
        let metrics = [
            "Inventory",
            "AccountsReceivable", 
            "AccountsPayable",
            "CostOfRevenue",
            "TotalRevenue"
        ]
        
        let data = try await fundamentalsService.fetchTimeseries(ticker: ticker, metrics: metrics)
        
        // DSO (Days Sales Outstanding) = (Accounts Receivable / Revenue) * 365
        // DIO (Days Inventory Outstanding) = (Inventory / COGS) * 365  
        // DPO (Days Payable Outstanding) = (Accounts Payable / COGS) * 365
        // CCC = DSO + DIO - DPO
        
        guard let receivables = data.timeseries["AccountsReceivable"]?.last?.value,
              let inventory = data.timeseries["Inventory"]?.last?.value,
              let payables = data.timeseries["AccountsPayable"]?.last?.value,
              let revenue = data.timeseries["TotalRevenue"]?.last?.value,
              let cogs = data.timeseries["CostOfRevenue"]?.last?.value,
              revenue > 0, cogs > 0 else { return nil }
        
        let dso = (receivables / revenue) * 365
        let dio = (inventory / cogs) * 365  
        let dpo = (payables / cogs) * 365
        
        return dso + dio - dpo
    }
}

// 사용 예제
let calculator = CustomMetricsCalculator()
let ticker = YFTicker(symbol: "AAPL")

async let roe = calculator.calculateROE(ticker: ticker)
async let debtRatio = calculator.calculateDebtToEquity(ticker: ticker)  
async let ccc = calculator.calculateCashConversionCycle(ticker: ticker)

let (roeValue, debtValue, cccValue) = try await (roe, debtRatio, ccc)

print("ROE: \(String(format: "%.2f", roeValue ?? 0))%")
print("부채비율: \(String(format: "%.2f", debtValue ?? 0))")
print("현금전환주기: \(String(format: "%.1f", cccValue ?? 0))일")
```

### 산업 벤치마킹

```swift
// 동종 업계 기업들과 메트릭 비교
func benchmarkAgainstPeers(ticker: YFTicker, peers: [String]) async throws {
    let calculator = CustomMetricsCalculator()
    
    print("=== 산업 벤치마킹 ===")
    print("대상 기업: \(ticker.symbol)")
    print("비교 기업: \(peers.joined(separator: ", "))")
    print("")
    
    // 목표 기업 메트릭
    let targetROE = try await calculator.calculateROE(ticker: ticker)
    let targetDebtRatio = try await calculator.calculateDebtToEquity(ticker: ticker)
    
    print("\(ticker.symbol) 지표:")
    print("  ROE: \(String(format: "%.2f", targetROE ?? 0))%")
    print("  부채비율: \(String(format: "%.2f", targetDebtRatio ?? 0))")
    print("")
    
    // 동종 업계 기업 메트릭
    print("경쟁사 비교:")
    
    for peerSymbol in peers {
        let peerTicker = YFTicker(symbol: peerSymbol)
        
        async let peerROE = calculator.calculateROE(ticker: peerTicker)
        async let peerDebtRatio = calculator.calculateDebtToEquity(ticker: peerTicker)
        
        let (roe, debt) = try await (peerROE, peerDebtRatio)
        
        print("  \(peerSymbol):")
        print("    ROE: \(String(format: "%.2f", roe ?? 0))%")
        print("    부채비율: \(String(format: "%.2f", debt ?? 0))")
    }
}

// 사용 예제: AAPL을 다른 Big Tech과 비교
let appleTicker = YFTicker(symbol: "AAPL")
let techPeers = ["GOOGL", "MSFT", "AMZN", "META"]

try await benchmarkAgainstPeers(ticker: appleTicker, peers: techPeers)
```

### 메트릭 변화 추세 분석

```swift
// 시간에 따른 메트릭 변화 분석
func analyzeTrends(ticker: YFTicker, metric: String, periods: Int = 12) async throws {
    let fundamentalsService = YFFundamentalsTimeseriesService()
    let data = try await fundamentalsService.fetchTimeseries(ticker: ticker, metrics: [metric])
    
    guard let timeseries = data.timeseries[metric] else {
        print("메트릭 '\(metric)' 데이터를 찾을 수 없습니다.")
        return
    }
    
    // 최근 N개 분기 데이터 추출
    let recentData = Array(timeseries.suffix(periods))
    
    print("=== \(ticker.symbol) \(metric) 추세 분석 ===")
    print("분석 기간: 최근 \(recentData.count)개 분기")
    print("")
    
    // 분기별 데이터 출력
    for (index, dataPoint) in recentData.enumerated() {
        let prevValue = index > 0 ? recentData[index - 1].value : dataPoint.value
        let change = index > 0 ? ((dataPoint.value - prevValue) / prevValue) * 100 : 0
        let changeStr = change != 0 ? " (\(change >= 0 ? "+" : "")\(String(format: "%.1f", change))%)" : ""
        
        print("Q\(dataPoint.quarter) \(dataPoint.year): \(formatValue(dataPoint.value, metric: metric))\(changeStr)")
    }
    
    // 전체 성장률 계산
    if recentData.count >= 2 {
        let firstValue = recentData.first!.value
        let lastValue = recentData.last!.value
        let totalGrowth = ((lastValue - firstValue) / firstValue) * 100
        
        print("")
        print("총 성장률: \(String(format: "%.1f", totalGrowth))%")
        print("연평균 성장률: \(String(format: "%.1f", totalGrowth / Double(recentData.count - 1) * 4))%")
    }
    
    // 변동성 계산 (표준편차)
    let values = recentData.map { $0.value }
    let mean = values.reduce(0, +) / Double(values.count)
    let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
    let standardDeviation = sqrt(variance)
    let coefficientOfVariation = (standardDeviation / mean) * 100
    
    print("변동성 (변동계수): \(String(format: "%.1f", coefficientOfVariation))%")
}

// 값 포맷팅 유틸리티
func formatValue(_ value: Double, metric: String) -> String {
    let metricsLoader = YFMetricsLoader()
    let definition = metricsLoader.getMetricDefinition(name: metric)
    
    switch definition?.unit {
    case "currency":
        if abs(value) >= 1_000_000_000 {
            return "$\(String(format: "%.1f", value / 1_000_000_000))B"
        } else if abs(value) >= 1_000_000 {
            return "$\(String(format: "%.1f", value / 1_000_000))M"
        } else {
            return "$\(String(format: "%.0f", value))"
        }
    case "percentage":
        return "\(String(format: "%.2f", value))%"
    case "ratio":
        return String(format: "%.2f", value)
    default:
        return String(format: "%.0f", value)
    }
}

// 사용 예제
let ticker = YFTicker(symbol: "AAPL")
try await analyzeTrends(ticker: ticker, metric: "TotalRevenue", periods: 16) // 4년간 분기 데이터
```

### 메모리 효율성

```swift
// 대량 심볼 구독 시 배치 처리
let allSymbols = ["AAPL", "GOOGL", "MSFT", "TSLA", "NVDA", /* ... 100개 이상 */]

for batch in allSymbols.chunked(into: 20) {
    try await manager.subscribe(symbols: Set(batch))
    
    // 배치 간 잠시 대기로 서버 부하 방지
    try await Task.sleep(nanoseconds: 500_000_000) // 0.5초
}

// 불필요한 구독 정리
let activeSymbols = await getActivePortfolioSymbols()
let currentSubscriptions = await manager.subscriptions
let unnecessarySubscriptions = currentSubscriptions.subtracting(activeSymbols)

if !unnecessarySubscriptions.isEmpty {
    try await manager.unsubscribe(symbols: unnecessarySubscriptions)
}
```

## Performance Monitoring

고급 기능 사용 시 성능 모니터링:

### API 호출 추적

```swift
class APICallTracker {
    private var callCount = 0
    private var startTime = Date()
    
    func trackCall() {
        callCount += 1
        
        if callCount % 10 == 0 {
            let duration = Date().timeIntervalSince(startTime)
            let rate = Double(callCount) / duration
            print("📊 API 호출: \(callCount)회, 속도: \(String(format: "%.2f", rate))회/초")
        }
    }
    
    func reset() {
        callCount = 0
        startTime = Date()
    }
}

let tracker = APICallTracker()

// 사용 예제
for symbol in symbols {
    tracker.trackCall()
    let quote = try await client.fetchQuote(ticker: ticker)
    // 처리...
}
```

### 메모리 사용량 최적화

```swift
// 대량 데이터 처리 시 메모리 효율적인 방법
func processLargeDataset(symbols: [String]) async {
    for chunk in symbols.chunked(into: 50) { // 50개씩 배치 처리
        var chunkData: [YFQuote] = []
        
        for symbol in chunk {
            do {
                let ticker = YFTicker(symbol: symbol)
                let quote = try await client.fetchQuote(ticker: ticker)
                chunkData.append(quote)
                
            } catch {
                print("❌ \(symbol) 실패: \(error)")
            }
        }
        
        // 배치 데이터 처리
        processChunk(chunkData)
        
        // 메모리 정리
        chunkData.removeAll()
        
        // 다음 배치 전 대기
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1초
    }
}
```

## Next Steps

고급 기능을 익혔다면 다음을 확인해보세요:

- <doc:BestPractices> - 성능 최적화 및 모범 사례
- <doc:TechnicalAnalysis> - 기술적 분석 심화 가이드
- <doc:OptionsTrading> - 옵션 거래 전략
- <doc:ErrorHandling> - 고급 에러 처리 패턴