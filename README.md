# swift-yf-tools

[![Swift](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%2015%2B-blue.svg)](https://developer.apple.com)
[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)](LICENSE.md)

Yahoo Finance API Swift 라이브러리 + CLI 도구 + MCP 서버.

| 구성 요소 | 이름 | 용도 |
|---|---|---|
| Swift 라이브러리 | `SwiftYFinance` | 앱/서버에서 Yahoo Finance 데이터 조회 |
| CLI / MCP 서버 | `swift-yf-tools` | 터미널 조회 + MCP 서버 내장 |

> [!IMPORTANT]
> 이 프로젝트는 Yahoo Finance의 **비공식 엔드포인트**를 사용합니다. Yahoo 측 응답 형식이나 접근 정책이 바뀌면 동작이 달라질 수 있습니다.

---

## 빠른 설치

### MCP 서버로 등록 (Agent 사용 권장)

```bash
# 1. 저장소 클론 및 빌드
git clone https://github.com/oozoofrog/swift-yf-tools.git
cd swift-yf-tools/CLI
swift build -c release --product swift-yf-tools

# 2. claude CLI로 MCP 등록 (원클릭)
claude mcp add swift-yf-tools -- "$(pwd)/.build/release/swift-yf-tools" mcp serve
```

### curl one-liner 설치

```bash
curl -fsSL https://raw.githubusercontent.com/oozoofrog/swift-yf-tools/main/install.sh | bash
```

설치 전에 동작을 미리 확인하려면:

```bash
curl -fsSL https://raw.githubusercontent.com/oozoofrog/swift-yf-tools/main/install.sh | bash -s -- --dry-run
```

---

## 설치

### 1. Swift Package Manager (라이브러리)

```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [.macOS(.v15), .iOS(.v18)],
    dependencies: [
        .package(url: "https://github.com/oozoofrog/swift-yf-tools.git", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "MyApp",
            dependencies: [
                .product(name: "SwiftYFinance", package: "swift-yf-tools")
            ]
        )
    ]
)
```

```swift
import SwiftYFinance
```

### 2. Xcode에서 추가

1. **File → Add Package Dependencies...**
2. URL: `https://github.com/oozoofrog/swift-yf-tools.git`
3. Product: **SwiftYFinance** 선택

### 3. Local Path 의존성

```swift
.package(path: "../swift-yf-tools")
```

### 4. CLI 수동 빌드

```bash
git clone https://github.com/oozoofrog/swift-yf-tools.git
cd swift-yf-tools/CLI
swift build -c release --product swift-yf-tools

# PATH에 추가 (선택)
ln -sf "$(pwd)/.build/release/swift-yf-tools" /usr/local/bin/swift-yf-tools
```

### 5. MCP 설치 — mcp install 명령

```bash
cd swift-yf-tools/CLI
swift build -c release --product swift-yf-tools

# Claude Desktop 자동 등록
.build/release/swift-yf-tools mcp install --client claude

# Cursor 프로젝트 설정 자동 등록
.build/release/swift-yf-tools mcp install --client cursor

# 현재 디렉토리 .mcp.json 생성
.build/release/swift-yf-tools mcp install --client local

# 설정 미리 보기 (파일 쓰기 없음)
.build/release/swift-yf-tools mcp install --client claude --dry-run
```

### 6. MCP 수동 설정 (JSON 직접 편집)

`~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "swift-yf-tools": {
      "command": "/절대경로/swift-yf-tools/CLI/.build/release/swift-yf-tools",
      "args": ["mcp", "serve"]
    }
  }
}
```

---

## Agent 설치 가이드

AI Agent가 이 저장소 링크를 보고 자동으로 설치할 때 참조하는 섹션입니다.

### 전제조건 확인

```bash
swift --version
# Swift 6.2 이상 필요
# 예: swift-driver version: 1.XX.XX Apple Swift version 6.2 ...

git --version
# git 2.x 이상
```

### 단계별 설치 명령

```bash
# Step 1: 저장소 클론
git clone https://github.com/oozoofrog/swift-yf-tools.git
cd swift-yf-tools

# Step 2: CLI 빌드 (CLI 디렉토리는 별도 SPM 패키지)
cd CLI
swift build -c release --product swift-yf-tools
# 예상 출력: Build complete!

# Step 3: 동작 확인
.build/release/swift-yf-tools --version
.build/release/swift-yf-tools --help

# Step 4: MCP 등록
# 방법 A — claude CLI 사용 (권장)
claude mcp add swift-yf-tools -- "$(pwd)/.build/release/swift-yf-tools" mcp serve

# 방법 B — 내장 mcp install 사용
.build/release/swift-yf-tools mcp install --client claude
```

### MCP tool 목록 (12개)

```bash
# tool 목록 확인 (JSON-RPC)
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' \
  | .build/release/swift-yf-tools mcp serve
```

제공 tool: `quote`, `multi-quote`, `chart`, `search`, `news`, `options`, `screening`, `customScreener`, `quoteSummary`, `domain`, `fundamentals`, `websocket-snapshot`

---

## 빠른 시작

### 라이브러리 사용

```swift
import SwiftYFinance

let client = YFClient()
let ticker = YFTicker(symbol: "AAPL")

let quote = try await client.quote.fetch(ticker: ticker)
print("현재가:", quote.marketData.regularMarketPrice ?? 0)

let history = try await client.chart.fetch(
    ticker: ticker,
    period: .oneMonth,
    interval: .oneDay
)
print("최근 1개월 캔들 수:", history.prices.count)
```

### 병렬 호출

```swift
import SwiftYFinance

let client = YFClient()
let ticker = YFTicker(symbol: "MSFT")

async let quote = client.quote.fetch(ticker: ticker)
async let news = client.news.fetchNews(ticker: ticker, count: 5)
async let summary = client.quoteSummary.fetchEssential(ticker: ticker)

let (currentQuote, latestNews, essentialSummary) = try await (quote, news, summary)
```

### CLI 사용

```bash
swift-yf-tools quote AAPL TSLA
swift-yf-tools history AAPL --period 1mo --interval 1d
swift-yf-tools quotesummary AAPL --type essential
swift-yf-tools screening day_gainers --limit 10
swift-yf-tools websocket AAPL BTC-USD --duration 10
```

---

## 제공 기능

### 라이브러리 서비스

| 서비스 | 진입점 | 설명 |
|---|---|---|
| Quote | `client.quote` | 단일/복수 종목 실시간 시세 |
| Chart | `client.chart` | OHLCV 과거 가격 데이터 |
| Search | `client.search` | 종목 검색/자동완성 |
| Fundamentals Timeseries | `client.fundamentalsTimeseries` | 재무 시계열 데이터 |
| News | `client.news` | 종목 뉴스 |
| Options | `client.options` | 옵션 체인 |
| Screener | `client.screener` | 사전 정의 스크리닝 |
| Quote Summary | `client.quoteSummary` | 종합 기업 정보 |
| Domain | `client.domain` | 섹터/산업/시장 도메인 데이터 |
| Custom Screener | `client.customScreener` | 사용자 조건 스크리닝 |
| Technical Indicators | `YFClient` extension | SMA, EMA, RSI, MACD, Bollinger Bands |
| WebSocket | `YFWebSocketClient` | 실시간 스트리밍 |

### CLI 명령어

| 명령어 | 설명 |
|---|---|
| `quote` | 단일/복수 종목 시세 조회 |
| `quotesummary` | 종합 기업 정보 조회 |
| `history` | 과거 가격 데이터 조회 |
| `search` | 종목 검색 |
| `fundamentals` | 재무 시계열 데이터 조회 |
| `news` | 종목 뉴스 조회 |
| `options` | 옵션 체인 조회 |
| `screening` | 사전 정의 스크리닝 |
| `domain` | 섹터/산업/시장 도메인 조회 |
| `custom-screening` | 사용자 조건 스크리닝 |
| `websocket` | 실시간 스트리밍 |
| `mcp` | MCP 설정 설치 및 stdio 서버 실행 |

상세 사용법은 [USAGE.md](USAGE.md)를 참조하세요.

---

## 아키텍처 개요

```text
YFClient
  ├─ YFSession (actor)      — 인증/쿠키 관리
  ├─ YFServiceCore          — 공통 요청/파싱
  ├─ YFQuoteService
  ├─ YFChartService
  ├─ YFSearchService
  ├─ ...
  └─ YFWebSocketClient      — 실시간 스트리밍
```

- `Sendable` 우선, `struct` 우선, `actor` 최소화
- crumb / cookie 인증 + Chrome 헤더 브라우저 impersonation
- Swift Concurrency 기반 안전한 네트워크 호출

---

## 개발 및 테스트

```bash
# 루트 패키지 빌드/테스트
swift build
swift test

# CLI 패키지 빌드/테스트
cd CLI
swift build
swift test
```

---

## 추가 문서

- 상세 사용법 레퍼런스: [USAGE.md](USAGE.md)
- CLI 빠른 시작: [CLI/README.md](CLI/README.md)
- MCP 서버 참조: [CLI/README-MCP.md](CLI/README-MCP.md)
- JSON 샘플 설명: [json-samples/README.md](json-samples/README.md)

---

## 라이선스

이 프로젝트는 [Apache License 2.0](LICENSE.md)으로 배포됩니다.

## 감사의 말

- [yfinance](https://github.com/ranaroussi/yfinance)
- [Yahoo Finance](https://finance.yahoo.com/)
