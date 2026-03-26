# SwiftYFinance — AI Agent Guide

## Project Overview

Swift library for Yahoo Finance API (port of Python yfinance).
- **Language**: Swift 6.1 (swift-tools-version: 6.1)
- **Package Manager**: Swift Package Manager
- **Platforms**: macOS 15+, iOS 18+, tvOS 18+, watchOS 11+
- **Dependency**: swift-protobuf 1.31.0+

## Build & Test

```bash
swift build        # Build library
swift test         # Run tests
cd CLI && swift build  # Build CLI (separate package)
```

## Architecture

- Entry point: `YFClient` (struct, Sendable)
- Session management: `YFSession` (actor — handles auth, cookies, network)
- Service base: `YFServiceCore` (struct — common request/parse logic)
- All services conform to `YFService` protocol
- Composition pattern: `YFClient` → `YFServiceCore` → individual services

## Key Patterns

- All types must be `Sendable`-conformant
- Prefer `struct` over `class`; use `actor` only for mutable shared state
- Error handling via `YFError` / `YFWebSocketError` enums
- Tests use Swift Testing framework (`@Test`), with `TestHelper` for isolation
- Korean comments and documentation

## Directory Structure

```
Sources/SwiftYFinance/
├── Core/           # API builders, cache, network, session
├── Services/       # 12 service implementations
├── Models/         # Data models (Business, Network, Primitives, etc.)
├── Protobuf/       # WebSocket streaming (PricingData.proto)
├── Helpers/        # Chart converter, date helper
├── Utils/          # Technical indicators extension
└── Resources/      # JSON config files
Tests/SwiftYFinanceTests/
├── Core/           # URL builder & WebSocket tests
├── Services/       # Service-level tests
├── Models/         # Model tests
├── Integration/    # Integration tests
└── Performance/    # Memory/performance tests
CLI/                # Separate SPM package for CLI tool
```
