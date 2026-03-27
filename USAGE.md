# swift-yf-tools 사용법 레퍼런스

Yahoo Finance API CLI 도구 및 MCP 서버의 상세 사용법 문서입니다.

- 설치 방법: [README.md](README.md)
- MCP 서버 참조: [CLI/README-MCP.md](CLI/README-MCP.md)

---

## 목차

1. [CLI 명령어 레퍼런스](#cli-명령어-레퍼런스)
2. [MCP tool 목록](#mcp-tool-목록)
3. [라이브러리 코드 예제](#라이브러리-코드-예제)
4. [고급 사용법](#고급-사용법)

---

## CLI 명령어 레퍼런스

### 빌드 후 실행

```bash
cd CLI
swift build -c release --product swift-yf-tools
.build/release/swift-yf-tools <명령어> [옵션]
```

PATH에 등록한 경우:

```bash
swift-yf-tools <명령어> [옵션]
```

### 전역 옵션

| 옵션 | 설명 |
|---|---|
| `--help, -h` | 도움말 출력 |
| `--version` | 버전 정보 출력 |
| `--json, -j` | Yahoo Finance 원본 JSON 응답 출력 |
| `--debug, -d` | 디버그 정보 출력 |

---

### 1. quote — 실시간 시세 조회

단일 또는 복수 종목의 실시간 시세를 조회합니다.

```bash
# 단일 종목
swift-yf-tools quote AAPL

# 복수 종목
swift-yf-tools quote AAPL TSLA MSFT

# JSON 응답 출력
swift-yf-tools quote AAPL --json
```

**출력 예시:**

```
AAPL - Apple Inc.
Current Price:    $225.00
Change:           -$1.01 (-0.45%)
Previous Close:   $226.01
Volume:           12M
Market Cap:       $3.3T
```

---

### 2. history — 과거 가격 데이터

종목의 OHLCV 과거 가격 데이터를 조회합니다.

```bash
swift-yf-tools history AAPL --period 1mo
swift-yf-tools history AAPL --period 1y --interval 1wk
swift-yf-tools history AAPL --period 5d --json
```

**기간 옵션 (`--period`):**

| 값 | 설명 |
|---|---|
| `1d` | 1일 |
| `5d` | 5일 |
| `1mo` | 1개월 |
| `3mo` | 3개월 |
| `6mo` | 6개월 |
| `1y` | 1년 |
| `2y` | 2년 |
| `5y` | 5년 |
| `10y` | 10년 |
| `max` | 전체 |

**간격 옵션 (`--interval`):** `1m`, `5m`, `15m`, `1h`, `1d`, `1wk`, `1mo`

---

### 3. search — 종목 검색

회사명 또는 키워드로 종목을 검색합니다.

```bash
swift-yf-tools search "Apple"
swift-yf-tools search "Technology" --limit 5
swift-yf-tools search "Apple" --json
```

**옵션:**
- `--limit, -l` — 최대 결과 수 (기본값: 10)

---

### 4. news — 뉴스 조회

종목 관련 뉴스를 조회합니다.

```bash
swift-yf-tools news AAPL
swift-yf-tools news AAPL --json
```

---

### 5. options — 옵션 체인 조회

종목의 옵션 체인 데이터를 조회합니다.

```bash
swift-yf-tools options AAPL
swift-yf-tools options AAPL --expiration 2025-09-20
swift-yf-tools options AAPL --json
```

**옵션:**
- `--expiration, -e` — 특정 만료일 (YYYY-MM-DD)

---

### 6. screening — 사전 정의 스크리닝

Yahoo Finance의 사전 정의 스크리너를 실행합니다.

```bash
swift-yf-tools screening day_gainers
swift-yf-tools screening most_actives --limit 10
swift-yf-tools screening day_gainers --json
```

**사용 가능한 스크리너:**

| 값 | 설명 |
|---|---|
| `day_gainers` | 당일 상승 종목 |
| `day_losers` | 당일 하락 종목 |
| `most_actives` | 거래량 상위 종목 |
| `aggressive_small_caps` | 공격적 소형주 |
| `growth_technology_stocks` | 성장 기술주 |
| `undervalued_growth_stocks` | 저평가 성장주 |
| `undervalued_large_caps` | 저평가 대형주 |
| `small_cap_gainers` | 소형주 상승 종목 |
| `most_shorted_stocks` | 공매도 비중 높은 종목 |

**옵션:**
- `--limit, -l` — 최대 결과 수 (기본값: 25, 최대: 250)

---

### 7. fundamentals — 재무 시계열 데이터

종목의 재무제표 시계열 데이터를 조회합니다.

```bash
swift-yf-tools fundamentals AAPL
swift-yf-tools fundamentals AAPL --json
```

---

### 8. websocket — 실시간 스트리밍

Yahoo Finance WebSocket을 통해 실시간 가격을 스트리밍합니다.

```bash
# 단일 종목 (기본 30초)
swift-yf-tools websocket AAPL

# 복수 종목, 60초
swift-yf-tools websocket AAPL TSLA MSFT --duration 60

# 암호화폐
swift-yf-tools websocket BTC-USD ETH-USD

# JSON 스트림
swift-yf-tools websocket AAPL TSLA --json --duration 15
```

**옵션:**
- `--duration, -t` — 스트리밍 지속 시간(초, 기본값: 30)

---

### 9. domain — 섹터/산업/시장 도메인

Yahoo Finance 도메인 데이터를 조회합니다.

```bash
swift-yf-tools domain --type sector
swift-yf-tools domain --type industry
swift-yf-tools domain --type market
swift-yf-tools domain --type sector --json
```

**옵션:**
- `--type, -t` — 도메인 타입: `sector`, `industry`, `market`

---

### 10. custom-screening — 사용자 조건 스크리닝

시가총액, P/E 비율 등 사용자 조건으로 종목을 스크리닝합니다.

```bash
swift-yf-tools custom-screening --market-cap "1B:10B"
swift-yf-tools custom-screening --pe-ratio "10:20"
swift-yf-tools custom-screening --market-cap "5B:50B" --pe-ratio "15:25"
swift-yf-tools custom-screening --market-cap "100B:1T" --json
```

**옵션:**
- `--market-cap` — 시가총액 범위 (예: `"1B:10B"`, `"500M:5B"`)
- `--pe-ratio` — P/E 비율 범위 (예: `"10:20"`)

---

### 11. quotesummary — 종합 기업 정보

종목의 종합 기업 정보를 조회합니다.

```bash
swift-yf-tools quotesummary AAPL --type essential
swift-yf-tools quotesummary AAPL --type comprehensive
swift-yf-tools quotesummary AAPL --type financials --quarterly
swift-yf-tools quotesummary AAPL --type analyst --json
```

**타입 옵션 (`--type`):**

| 값 | 설명 |
|---|---|
| `essential` | 핵심 정보 (기본값) |
| `comprehensive` | 종합 분석 데이터 |
| `company` | 기업 프로필 |
| `price` | 가격/시장 데이터 |
| `financials` | 재무제표 |
| `earnings` | 실적 데이터 |
| `ownership` | 소유권 정보 |
| `analyst` | 애널리스트 추천 |

---

### 12. mcp — MCP 설정 설치 및 서버 실행

MCP 설정 파일을 자동으로 생성하거나 stdio MCP 서버로 실행합니다.

```bash
# Claude Desktop 자동 설치
swift-yf-tools mcp install --client claude

# Cursor 프로젝트 설정 자동 설치
swift-yf-tools mcp install --client cursor

# .mcp.json 생성
swift-yf-tools mcp install --client local

# 설정 미리 보기 (파일 쓰기 없음)
swift-yf-tools mcp install --client claude --dry-run

# MCP stdio 서버로 실행
swift-yf-tools mcp serve
```

---

## MCP tool 목록

swift-yf-tools MCP 서버는 12개의 tool을 제공합니다.
JSON-RPC 2.0 over stdio 방식으로 동작합니다.

### tool 목록 확인

```bash
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' \
  | swift-yf-tools mcp serve
```

### 1. quote — 단일 종목 시세

| 파라미터 | 타입 | 필수 | 설명 |
|---|---|---|---|
| symbol | string | 필수 | 종목 심볼 (예: AAPL) |

```bash
echo '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"quote","arguments":{"symbol":"AAPL"}}}' \
  | swift-yf-tools mcp serve
```

### 2. multi-quote — 복수 종목 시세

| 파라미터 | 타입 | 필수 | 설명 |
|---|---|---|---|
| symbols | string[] | 필수 | 종목 심볼 배열 |

### 3. chart — 과거 가격 데이터

| 파라미터 | 타입 | 필수 | 설명 |
|---|---|---|---|
| symbol | string | 필수 | 종목 심볼 |
| period | string | 선택 | 조회 기간 (기본값: 1mo) |
| interval | string | 선택 | 봉 단위 (기본값: 1d) |

### 4. search — 종목 검색

| 파라미터 | 타입 | 필수 | 설명 |
|---|---|---|---|
| query | string | 필수 | 검색 키워드 |
| limit | integer | 선택 | 최대 결과 수 (기본값: 10) |

### 5. news — 뉴스 조회

| 파라미터 | 타입 | 필수 | 설명 |
|---|---|---|---|
| query | string | 필수 | 종목 심볼 또는 키워드 |
| count | integer | 선택 | 뉴스 수 (기본값: 10) |

### 6. options — 옵션 체인

| 파라미터 | 타입 | 필수 | 설명 |
|---|---|---|---|
| symbol | string | 필수 | 종목 심볼 |

### 7. screening — 사전 정의 스크리너

| 파라미터 | 타입 | 필수 | 설명 |
|---|---|---|---|
| screener | string | 선택 | 스크리너 유형 (기본값: dayGainers) |
| limit | integer | 선택 | 최대 결과 수 (기본값: 25) |

### 8. customScreener — 맞춤 스크리닝

| 파라미터 | 타입 | 필수 | 설명 |
|---|---|---|---|
| minMarketCap | number | 선택 | 최소 시가총액 (USD) |
| maxMarketCap | number | 선택 | 최대 시가총액 (USD) |
| minPERatio | number | 선택 | 최소 PER |
| maxPERatio | number | 선택 | 최대 PER |
| limit | integer | 선택 | 최대 결과 수 (기본값: 25) |

### 9. quoteSummary — 종합 기업 정보

| 파라미터 | 타입 | 필수 | 설명 |
|---|---|---|---|
| symbol | string | 필수 | 종목 심볼 |
| type | string | 선택 | 조회 유형 (기본값: essential) |

### 10. domain — 섹터/산업/마켓

| 파라미터 | 타입 | 필수 | 설명 |
|---|---|---|---|
| domainType | string | 선택 | sector, market, industry (기본값: sector) |
| value | string | 선택 | 섹터명 또는 마켓명 |

### 11. fundamentals — 재무제표 시계열

| 파라미터 | 타입 | 필수 | 설명 |
|---|---|---|---|
| symbol | string | 필수 | 종목 심볼 |

### 12. websocket-snapshot — 실시간 스냅샷

| 파라미터 | 타입 | 필수 | 설명 |
|---|---|---|---|
| symbols | string[] | 필수 | 구독할 종목 심볼 배열 |
| timeout_seconds | integer | 선택 | 타임아웃(초, 기본값: 10) |

---

## 라이브러리 코드 예제

### 기본 시세 조회

```swift
import SwiftYFinance

let client = YFClient()
let ticker = YFTicker(symbol: "AAPL")

let quote = try await client.quote.fetch(ticker: ticker)
print("현재가:", quote.marketData.regularMarketPrice ?? 0)
```

### 과거 데이터 조회

```swift
import SwiftYFinance

let client = YFClient()
let ticker = YFTicker(symbol: "AAPL")

let history = try await client.chart.fetch(
    ticker: ticker,
    period: .oneMonth,
    interval: .oneDay
)
print("최근 1개월 캔들 수:", history.prices.count)
```

### 병렬 복수 서비스 호출

```swift
import SwiftYFinance

let client = YFClient()
let ticker = YFTicker(symbol: "MSFT")

async let quote = client.quote.fetch(ticker: ticker)
async let news = client.news.fetchNews(ticker: ticker, count: 5)
async let summary = client.quoteSummary.fetchEssential(ticker: ticker)

let (currentQuote, latestNews, essentialSummary) = try await (quote, news, summary)
```

### WebSocket 실시간 스트리밍

```swift
import SwiftYFinance

let webSocket = YFWebSocketClient()
let (messages, _) = await webSocket.streams()

try await webSocket.connect()
try await webSocket.subscribe(["AAPL", "TSLA"])

for await message in messages {
    print(message.symbol ?? "?", message.price ?? 0)
    break
}

await webSocket.disconnect()
```

---

## 고급 사용법

### 스크립팅 — 포트폴리오 모니터링

```bash
#!/bin/bash
SYMBOLS=("AAPL" "GOOGL" "MSFT" "AMZN" "TSLA")

echo "Portfolio Status - $(date)"
echo "================================"

for symbol in "${SYMBOLS[@]}"; do
    result=$(swift-yf-tools quote "$symbol" --json)
    price=$(echo "$result" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('regularMarketPrice','N/A'))")
    printf "%-6s: %s\n" "$symbol" "$price"
done
```

### Python 통합

```python
import subprocess
import json

def get_quote(symbol: str) -> dict:
    result = subprocess.run(
        ["swift-yf-tools", "quote", symbol, "--json"],
        capture_output=True, text=True
    )
    return json.loads(result.stdout)

quote = get_quote("AAPL")
print(f"AAPL: ${quote['regularMarketPrice']}")
```

### Cron 자동화

```bash
# 매일 오전 9시 포트폴리오 리포트 저장
0 9 * * * /usr/local/bin/swift-yf-tools quote AAPL GOOGL MSFT --json > /tmp/daily_portfolio.json
```

### MCP JSON-RPC 직접 테스트

```bash
# tools/list 확인
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' \
  | .build/release/swift-yf-tools mcp serve

# quote tool 호출
echo '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"quote","arguments":{"symbol":"AAPL"}}}' \
  | .build/release/swift-yf-tools mcp serve

# chart tool 호출 (3개월 주봉)
echo '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"chart","arguments":{"symbol":"AAPL","period":"3mo","interval":"1wk"}}}' \
  | .build/release/swift-yf-tools mcp serve

# customScreener tool 호출
echo '{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"customScreener","arguments":{"minMarketCap":100000000000,"maxPERatio":25,"limit":5}}}' \
  | .build/release/swift-yf-tools mcp serve
```

### 로그 레벨 설정

```bash
# 환경 변수로 로그 레벨 조정
export SWIFTYFINANCE_LOG_LEVEL=DEBUG
swift-yf-tools quote AAPL
```

---

## 문제 해결

### 빌드 실패

```bash
# Swift 버전 확인 (6.2 이상 필요)
swift --version

# 클린 빌드
swift package clean
swift build -c release
```

### 네트워크 오류

```bash
# 디버그 모드로 상세 정보 확인
swift-yf-tools quote AAPL --debug

# 네트워크 연결 테스트
curl -I https://finance.yahoo.com
```

### Rate Limiting

```bash
# 요청 간격 조정
for symbol in AAPL GOOGL MSFT; do
    swift-yf-tools quote "$symbol"
    sleep 1
done
```
