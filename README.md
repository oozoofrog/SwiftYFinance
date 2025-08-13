# SwiftYFinance

[![Swift](https://img.shields.io/badge/Swift-6.1-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2013%2B%20%7C%20iOS%2016%2B%20%7C%20tvOS%2016%2B%20%7C%20watchOS%209%2B-blue.svg)](https://developer.apple.com)
[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)](LICENSE.md)
[![Tests](https://img.shields.io/badge/Tests-78%20tests-brightgreen.svg)](https://github.com/yourusername/SwiftYFinance/actions)

SwiftYFinance is a comprehensive Swift port of the Python [yfinance](https://github.com/ranaroussi/yfinance) library with advanced browser impersonation capabilities. It provides seamless access to Yahoo Finance data through Chrome-level browser emulation, ensuring reliable API access and anti-detection features.

## 🚀 Key Features

### 🎯 Browser Impersonation (NEW!)
- **Chrome 136 Emulation**: Complete Chrome 136 browser fingerprint impersonation
- **Anti-Detection**: Advanced header rotation and User-Agent management
- **CSRF Authentication**: Yahoo Finance compatible authentication system
- **Rate Limiting Handling**: Intelligent request throttling and retry mechanisms

### 📊 Comprehensive Data Access
- **Historical Data**: OHLCV data with custom date ranges and intervals
- **Real-time Quotes**: Live price data and after-hours trading information
- **Financial Statements**: Income statements, balance sheets, cash flow statements
- **Earnings Data**: Quarterly and annual earnings with estimates
- **Fundamental Analysis**: Key financial ratios and company metrics

### 🏗️ Robust Architecture
- **Modular Design**: Clean separation of concerns with focused components
- **TDD-Driven**: 100% test coverage with Test-Driven Development
- **Error Resilience**: Comprehensive error handling and recovery
- **Performance Optimized**: Efficient HTTP/2 connections and caching

### 🔧 Developer Experience
- **Swift 6.1 Compatible**: Latest Swift language features
- **Async/Await**: Modern concurrency for all API calls
- **Protocol-Oriented**: Flexible and testable architecture
- **Documentation**: Comprehensive API documentation and examples

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

// Fetch financial data
let financials = try await client.fetchFinancials(ticker: ticker)
print("Annual revenue: \(financials.annualReports.first?.totalRevenue)")
```

### Advanced Features

```swift
// Fetch multiple data types concurrently
async let history = client.fetchHistory(ticker: ticker, period: .oneYear)
async let financials = client.fetchFinancials(ticker: ticker)
async let balanceSheet = client.fetchBalanceSheet(ticker: ticker)

let (priceData, financialData, balanceData) = try await (history, financials, balanceSheet)

// Custom date range with specific interval
let customHistory = try await client.fetchHistory(
    ticker: ticker,
    startDate: Date().addingTimeInterval(-86400 * 90), // 90 days ago
    endDate: Date(),
    interval: .oneDay
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

## 🧪 Development Principles

This project follows **TDD (Test-Driven Development)** and **Tidy First** principles:

- ✅ **Red → Green → Refactor** cycle
- ✅ **Separation of structural and behavioral changes**
- ✅ **Work on one test at a time**
- ✅ **Implement minimal code needed to pass tests**

## 📋 Development Progress

- **Phase 1-4**: ✅ **Complete** - Core architecture, models, network layer, API integration
- **Phase 4.5**: ✅ **Complete** - Chrome 136 browser impersonation ([curl_cffi](https://github.com/yifeikong/curl_cffi) port)
- **Phase 5**: ⏳ Advanced Features (Next)

### Current Status
- **✅ 78 tests** with comprehensive coverage
- **✅ Browser Impersonation** - Chrome 136 fingerprint emulation
- **✅ Complete API Coverage** - Historical data, quotes, financials, earnings
- **✅ Authentication System** - CSRF and basic authentication strategies
- **✅ Modular Architecture** - 20+ focused source files

### Recent Achievements (2025-08-13)
- **🎯 YFBrowserImpersonator**: Complete Chrome 136 browser emulation
- **🔧 File Organization**: Separated large files into focused components
- **🧪 TDD Coverage**: All features developed test-first
- **📚 Documentation**: Comprehensive API documentation and usage examples

## 🏗️ Project Structure

```
SwiftYFinance/
├── Sources/SwiftYFinance/
│   ├── Core/                        # Core infrastructure
│   │   ├── YFClient.swift           # Main client API (157 lines)
│   │   ├── YFSession.swift          # Network session (117 lines)
│   │   ├── YFSessionAuth.swift      # CSRF authentication (189 lines)
│   │   ├── YFSessionCookie.swift    # User-Agent rotation (19 lines)
│   │   ├── YFBrowserImpersonator.swift # Chrome 136 emulation (NEW!)
│   │   ├── YF*API.swift            # 7 specialized API endpoints
│   │   └── YFEnums.swift           # Core enumerations
│   ├── Models/                     # Data models
│   │   ├── YFTicker.swift          # Stock ticker
│   │   ├── YFPrice.swift           # Price data
│   │   ├── YFHistoricalData.swift  # Historical data
│   │   ├── YFQuote.swift           # Quote data  
│   │   ├── YFFinancials.swift      # Financial statements (4 files)
│   │   ├── YF*Models.swift         # Response models
│   │   └── YFError.swift           # Error definitions
│   └── Utils/                      # Utilities
│       ├── YFRequestBuilder.swift  # Request construction
│       ├── YFResponseParser.swift  # Response parsing
│       └── YFHTMLParser.swift      # HTML parsing
├── Tests/SwiftYFinanceTests/       # 78 comprehensive tests
│   ├── Core/                       # Core component tests
│   ├── Client/                     # API integration tests  
│   ├── Models/                     # Data model tests
│   └── Utils/                      # Utility tests
├── docs/plans/                     # Development documentation
└── yfinance-reference/             # Python yfinance reference
```

## 🧪 Running Tests

```bash
# Run all tests (78 tests)
swift test

# Run specific test suites
swift test --filter YFClientTests          # Main API tests
swift test --filter YFBrowserImpersonator  # Browser emulation tests
swift test --filter RealAPITests           # Live API integration tests

# Run performance-sensitive tests
swift test --filter FinancialDataTests     # Financial data parsing
swift test --filter QuoteSummaryTests      # Real-time quote tests

# Verbose output with timing
swift test --verbose
```

### Test Categories

- **Core Tests** (28 tests): Basic functionality and architecture
- **Client Tests** (15 tests): API integration and data fetching  
- **Model Tests** (18 tests): Data model validation and parsing
- **Utility Tests** (12 tests): Helper functions and parsing
- **Browser Tests** (5 tests): Chrome impersonation and anti-detection

## 🎯 Browser Impersonation Technology

SwiftYFinance includes advanced browser impersonation capabilities ported from Python's [curl_cffi](https://github.com/yifeikong/curl_cffi) library:

### Chrome 136 Fingerprint Emulation
- **Complete Header Matching**: User-Agent, Accept, Sec-CH-UA client hints
- **HTTP/2 Settings**: Chrome-identical network behavior
- **Cookie Management**: Browser-level session handling
- **Anti-Detection**: Header rotation and request timing

### Why Browser Impersonation?
Yahoo Finance implements sophisticated detection systems to identify automated requests. Our browser impersonation ensures:
- ✅ **Reliable Access**: Bypass anti-bot detection systems
- ✅ **Rate Limit Avoidance**: Appear as legitimate browser traffic  
- ✅ **Long-term Stability**: Reduced risk of API access blocking
- ✅ **Data Integrity**: Consistent access to all Yahoo Finance endpoints

```swift
// Automatic Chrome 136 impersonation - no configuration needed
let client = YFClient() 
let data = try await client.fetchHistory(ticker: YFTicker(symbol: "AAPL"))

// Manual browser configuration (advanced users)
let impersonator = YFBrowserImpersonator()
impersonator.rotateUserAgent() // Switch to different Chrome version
let session = impersonator.createConfiguredURLSession()
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

- [yfinance](https://github.com/ranaroussi/yfinance) - Original Python library inspiration
- [curl_cffi](https://github.com/yifeikong/curl_cffi) - Browser impersonation reference implementation
- [Yahoo Finance](https://finance.yahoo.com/) - Financial data provider
- Swift community - Language and ecosystem support
- TDD & Tidy First methodologies - Development principles

## 📞 Contact

For questions or suggestions about the project, please contact us through [issues](https://github.com/yourusername/SwiftYFinance/issues).

---

Start leveraging Yahoo Finance data in the Swift ecosystem with **SwiftYFinance**! 🚀📈
