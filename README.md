# SwiftYFinance

[![Swift](https://img.shields.io/badge/Swift-6.1-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2013%2B%20%7C%20iOS%2016%2B%20%7C%20tvOS%2016%2B%20%7C%20watchOS%209%2B-blue.svg)](https://developer.apple.com)
[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)](LICENSE.md)

A Swift port of the Python [yfinance](https://github.com/ranaroussi/yfinance) library for accessing Yahoo Finance data.

## Features

- **Real-time Stock Quotes** - Live price data and after-hours trading information
- **Historical Data** - OHLCV data with customizable date ranges and intervals
- **Financial Statements** - Income statements, balance sheets, cash flow statements
- **Options Trading** - Complete options chains with Greeks calculation
- **Technical Indicators** - SMA, EMA, RSI, MACD, Bollinger Bands, and more
- **News & Sentiment** - Real-time news feeds with sentiment analysis
- **Stock Screening** - Advanced filtering and screening capabilities
- **WebSocket Streaming** - Real-time price data streaming
- **Browser Impersonation** - Chrome 136 fingerprint emulation for reliable API access

## Requirements

- macOS 13.0+ / iOS 16.0+ / tvOS 16.0+ / watchOS 9.0+
- Swift 6.1+
- Xcode 15.0+

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/SwiftYFinance.git", from: "1.0.0")
]
```

### Xcode

1. File → Add Package Dependencies
2. Enter URL: `https://github.com/yourusername/SwiftYFinance.git`
3. Select version and Add Package

## Usage

### Quick Start

```swift
import SwiftYFinance

// Create client with Chrome 136 browser impersonation
let client = YFClient()

// Fetch historical data
let ticker = YFTicker(symbol: "AAPL")
let history = try await client.fetchHistory(ticker: ticker, period: .oneMonth)

// Get real-time quote
let quote = try await client.fetchQuote(ticker: ticker)
print("Current price: \(quote.price)")

// WebSocket real-time streaming (NEW!)
let stream = try await client.startRealTimeStreaming(symbols: ["AAPL", "TSLA"])
for await quote in stream {
    print("\(quote.symbol): $\(quote.price)")
}

// Fetch financial data
let financials = try await client.fetchFinancials(ticker: ticker)
print("Annual revenue: \(financials.annualReports.first?.totalRevenue)")
```

### Advanced Financial Analysis

```swift
// Options Trading Analysis
let optionsChain = try await client.fetchOptionsChain(ticker: ticker)
print("Call options: \(optionsChain.calls.count)")
print("Put options: \(optionsChain.puts.count)")

// Technical Indicators
let sma20 = try await client.calculateSMA(ticker: ticker, period: 20)
let rsi = try await client.calculateRSI(ticker: ticker, period: 14)
let signals = try await client.getTechnicalSignals(ticker: ticker)
print("Overall signal: \(signals.overallSignal)")

// News & Sentiment Analysis
let news = try await client.fetchNews(ticker: ticker, includeSentiment: true)
for article in news {
    print("\(article.title) - Sentiment: \(article.sentiment?.classification)")
}

// Advanced Stock Screening
let screener = YFScreener.equity()
    .marketCap(min: 1_000_000_000)
    .peRatio(max: 25)
    .sector(.technology)
    .sortBy(.marketCap, ascending: false)

let results = try await client.runScreener(screener)
print("Found \(results.count) matching stocks")
```

### Concurrent Data Fetching

```swift
// Fetch multiple data types concurrently
async let history = client.fetchHistory(ticker: ticker, period: .oneYear)
async let financials = client.fetchFinancials(ticker: ticker)
async let options = client.fetchOptionsChain(ticker: ticker)
async let news = client.fetchNews(ticker: ticker)

let (priceData, financialData, optionsData, newsData) = 
    try await (history, financials, options, news)

// Technical analysis with multiple indicators
let indicators = try await client.calculateMultipleIndicators(
    ticker: ticker,
    indicators: [
        .sma(period: 20),
        .ema(period: 12), 
        .rsi(period: 14),
        .macd(fast: 12, slow: 26, signal: 9),
        .bollingerBands(period: 20, stdDev: 2.0)
    ]
)
```

### Browser Impersonation Configuration

```swift
// Create session with custom browser settings
let session = YFSession()
session.rotateUserAgent() // Switch to different Chrome version

// Access browser impersonation directly
let impersonator = YFBrowserImpersonator()
let chromeHeaders = impersonator.getChrome136Headers()
let configuredSession = impersonator.createConfiguredURLSession()
```

## Command Line Interface

SwiftYFinance includes a CLI tool for quick data access and testing:

```bash
# Build and run CLI
cd CLI
swift build
swift run swiftyfinance --help

# Get real-time quote
swift run swiftyfinance quote AAPL

# Historical data
swift run swiftyfinance history AAPL --period 1mo

# Search for stocks
swift run swiftyfinance search Apple --limit 5

# Financial data
swift run swiftyfinance fundamentals AAPL
```

### Available Commands

| Command | Description | Options |
|---------|-------------|---------|
| `quote` | Real-time stock quotes | `--json`, `--debug` |
| `history` | Historical price data | `--period`, `--json`, `--debug` |
| `search` | Search stocks by name | `--limit`, `--json`, `--debug` |
| `fundamentals` | Financial statements | `--json`, `--debug` |
| `news` | Latest news articles | `--limit`, `--json`, `--debug` |
| `options` | Options chains | `--expiration`, `--json`, `--debug` |
| `screener` | Stock screening | `--type`, `--json`, `--debug` |
| `domain` | Domain listings | `--type`, `--json`, `--debug` |
| `custom-screener` | Custom filters | `--file`, `--json`, `--debug` |
| `stream` | WebSocket streaming | `--symbols`, `--debug` |
| `technicals` | Technical indicators | `--indicators`, `--json`, `--debug` |

## API Documentation

### Basic Usage

```swift
import SwiftYFinance

let client = YFClient()
let ticker = YFTicker(symbol: "AAPL")

// Fetch real-time quote
let quote = try await client.fetchQuote(ticker: ticker)
print("Price: \(quote.price)")

// Get historical data
let history = try await client.fetchHistory(ticker: ticker, period: .oneMonth)
for price in history.prices {
    print("\(price.date): \(price.close)")
}
```

### Advanced Features

For detailed API documentation and advanced usage examples, please refer to the [documentation](https://github.com/yourusername/SwiftYFinance/wiki).

## Testing

```bash
# Run all tests
swift test

# Run specific test suite
swift test --filter YFClientTests
```

## Contributing

Contributions are welcome! Please read our [Contributing Guidelines](CONTRIBUTING.md) before submitting a pull request.

## License

This project is distributed under the Apache License, Version 2.0. See the [LICENSE.md](LICENSE.md) file for details.

## Acknowledgments

- [yfinance](https://github.com/ranaroussi/yfinance) - Original Python library
- [Yahoo Finance](https://finance.yahoo.com/) - Data provider
