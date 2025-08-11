# SwiftYFinance

[![Swift](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2013%2B%20%7C%20iOS%2016%2B%20%7C%20tvOS%2016%2B%20%7C%20watchOS%209%2B-blue.svg)](https://developer.apple.com)
[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)](LICENSE.md)

SwiftYFinance is a Swift port of the Python [yfinance](https://github.com/ranaroussi/yfinance) library. It's a Swift library that makes it easy to fetch and analyze stock market data through the Yahoo Finance API.

## 🚀 Key Features

### 📊 Core Data Models
- **YFTicker**: Stock symbol and basic information management
- **YFPrice**: Price data modeling and comparison operations
- **YFHistoricalData**: Historical data and date range processing
- **YFSession**: Network session and request management

### 🔌 API Integration
- **Price History**: Daily/weekly/custom period price data
- **Quote Data**: Real-time quotes and after-hours trading information
- **Fundamental Data**: Financial statements, balance sheets, cash flow statements, earnings data

### 🌐 Advanced Features
- **Multiple Tickers**: Concurrent processing of multiple stocks
- **WebSocket**: Real-time data streaming
- **Search & Lookup**: Keyword search and ISIN lookup
- **Screener**: Stock/fund filtering and screening

### 🛠️ Utilities
- **Cache**: Data caching and expiration management
- **Date Utilities**: Date parsing and timezone handling
- **Error Handling**: Network, parsing, and validation error handling

## 📱 Supported Platforms

- **macOS** 13.0+
- **iOS** 16.0+
- **tvOS** 16.0+
- **watchOS** 9.0+

## 🛠️ Installation

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

## 📖 Usage

### Basic Usage

```swift
import SwiftYFinance

// Create Ticker
let ticker = YFTicker(symbol: "AAPL")

// Fetch price data
let price = YFPrice(open: 150.0, high: 155.0, low: 148.0, close: 152.0, volume: 1000000)

// Historical data
let historicalData = YFHistoricalData(
    symbol: "AAPL",
    startDate: Date(),
    endDate: Date().addingTimeInterval(86400 * 30),
    prices: [price]
)
```

### Network Session

```swift
let session = YFSession()
// Configure proxy, add headers, etc.
```

## 🧪 Development Principles

This project follows **TDD (Test-Driven Development)** and **Tidy First** principles:

- ✅ **Red → Green → Refactor** cycle
- ✅ **Separation of structural and behavioral changes**
- ✅ **Work on one test at a time**
- ✅ **Implement minimal code needed to pass tests**

## 📋 Development Progress

- **Phase 1**: ✅ Basic Structure Setup
- **Phase 2**: ✅ Core Data Models
- **Phase 3**: 🔄 Network Layer (In Progress)
- **Phase 4**: ⏳ API Integration
- **Phase 5**: ⏳ Advanced Features
- **Phase 6**: ⏳ WebSocket
- **Phase 7**: ⏳ Domain Models
- **Phase 8**: ⏳ Screener
- **Phase 9**: ⏳ Utilities
- **Phase 10**: ⏳ Performance & Optimization

**Overall Progress**: 13/88 tests completed (14.8%)

## 🏗️ Project Structure

```
SwiftYFinance/
├── Sources/
│   └── SwiftYFinance/
│       ├── SwiftYFinance.swift      # Main library entry point
│       ├── YFTicker.swift           # Stock symbol management
│       ├── YFPrice.swift            # Price data model
│       ├── YFHistoricalData.swift   # Historical data
│       ├── YFSession.swift          # Network session
│       └── YFError.swift            # Error type definitions
├── Tests/
│   └── SwiftYFinanceTests/
│       ├── YFTickerTests.swift      # Ticker tests
│       ├── YFPriceTests.swift       # Price tests
│       ├── YFHistoricalDataTests.swift # Historical data tests
│       └── YFSessionTests.swift     # Session tests
└── Package.swift                    # Swift Package configuration
```

## 🧪 Running Tests

```bash
# Run all tests
swift test

# Run specific tests
swift test --filter YFTickerTests

# Verbose test output
swift test --verbose
```

## 🤝 Contributing

1. Report bugs or request features through issues
2. Fork and create a feature branch
3. Write tests following TDD principles
4. Implement code and ensure tests pass
5. Create a Pull Request

### Development Guidelines

- **Follow TDD cycle**: Red → Green → Refactor
- **Minimal code principle**: Write only the code needed to pass tests
- **Separate structural and behavioral changes**: Apply Tidy First principles
- **Meaningful test names**: Clearly express the purpose of tests

## 📄 License

This project is distributed under the Apache License, Version 2.0. See the [LICENSE.md](LICENSE.md) file for details.

## 🙏 Acknowledgments

- [yfinance](https://github.com/ranaroussi/yfinance) - Original Python library
- [Yahoo Finance](https://finance.yahoo.com/) - Data provider
- Swift community - Language and tool support

## 📞 Contact

For questions or suggestions about the project, please contact us through [issues](https://github.com/yourusername/SwiftYFinance/issues).

---

Start leveraging Yahoo Finance data in the Swift ecosystem with **SwiftYFinance**! 🚀📈
