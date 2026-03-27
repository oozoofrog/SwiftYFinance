# SwiftYFinance MCP 서버

Yahoo Finance 데이터를 [MCP(Model Context Protocol)](https://modelcontextprotocol.io/) 클라이언트에 직접 제공하는 stdio 기반 서버입니다.
Claude Desktop, Cursor 등 MCP 클라이언트와 연동하여 AI 어시스턴트가 Yahoo Finance 데이터에 직접 접근할 수 있습니다.

## 특징

- **JSON-RPC 2.0 over stdio** — 외부 MCP SDK 없이 순수 Swift로 구현
- **12개 Yahoo Finance 서비스** 모두 MCP tool로 노출
- **Swift 6.2** 기반 — 완전한 동시성 안전성 보장
- **macOS 15+** 지원

## 빌드 방법

```bash
# CLI 디렉토리로 이동
cd CLI

# MCP 서버 빌드
swift build --target swift-yf-tools

# 빌드된 바이너리 경로
.build/debug/swift-yf-tools   # 디버그
.build/release/swift-yf-tools # 릴리즈 (swift build -c release)
```

## Claude Desktop 설정

`~/Library/Application Support/Claude/claude_desktop_config.json` 파일을 생성하거나 수정합니다:

```json
{
  "mcpServers": {
    "swiftyfinance": {
      "command": "/절대경로/SwiftYFinance/CLI/.build/debug/swift-yf-tools",
      "args": []
    }
  }
}
```

예시 (홈 디렉토리 기준):

```json
{
  "mcpServers": {
    "swiftyfinance": {
      "command": "/Users/사용자이름/develop/SwiftYFinance/CLI/.build/release/swift-yf-tools",
      "args": []
    }
  }
}
```

설정 후 Claude Desktop을 재시작하면 Yahoo Finance 데이터 조회 tool을 사용할 수 있습니다.

## Cursor 설정

`.cursor/mcp.json` 파일을 프로젝트 루트 또는 `~/.cursor/mcp.json`에 생성합니다:

```json
{
  "mcpServers": {
    "swiftyfinance": {
      "command": "/절대경로/SwiftYFinance/CLI/.build/debug/swift-yf-tools",
      "args": []
    }
  }
}
```

Cursor MCP 설정은 **Settings > MCP** 메뉴에서도 추가할 수 있습니다.

## 사용 가능한 Tool 목록 (12개)

### 1. quote — 단일 종목 시세 조회

Yahoo Finance에서 단일 종목의 실시간 시세를 조회합니다.

| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| symbol | string | 필수 | 종목 심볼 (예: AAPL, TSLA, BTC-USD) |

**예시 질문**: "AAPL 현재 주가 알려줘"

---

### 2. multi-quote — 복수 종목 시세 조회

여러 종목의 실시간 시세를 한 번에 조회합니다.

| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| symbols | string[] | 필수 | 종목 심볼 배열 (예: ["AAPL", "TSLA", "MSFT"]) |

**예시 질문**: "AAPL, TSLA, MSFT 동시에 조회해줘"

---

### 3. chart — 과거 가격 데이터

종목의 과거 가격 데이터(OHLCV)를 조회합니다.

| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| symbol | string | 필수 | 종목 심볼 |
| period | string | 선택 | 조회 기간: 1d, 5d, 1mo, 3mo, 6mo, 1y, 2y, 5y, 10y, max (기본값: 1mo) |
| interval | string | 선택 | 봉 단위: 1m, 2m, 5m, 15m, 30m, 60m, 90m, 1h, 1d, 5d, 1wk, 1mo, 3mo (기본값: 1d) |

**예시 질문**: "AAPL 최근 3개월 일봉 데이터 보여줘"

---

### 4. search — 종목 검색

회사명 또는 키워드로 Yahoo Finance 종목을 검색합니다.

| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| query | string | 필수 | 검색 키워드 (예: Apple, Tesla) |
| limit | integer | 선택 | 최대 결과 수 (기본값: 10) |

**예시 질문**: "Apple 관련 종목 검색해줘"

---

### 5. news — 뉴스 조회

종목 또는 키워드 관련 Yahoo Finance 뉴스를 조회합니다.

| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| query | string | 필수 | 종목 심볼 또는 키워드 |
| count | integer | 선택 | 가져올 뉴스 수 (기본값: 10) |

**예시 질문**: "AAPL 관련 최신 뉴스 5개 보여줘"

---

### 6. options — 옵션 체인 조회

종목의 옵션 체인 데이터를 조회합니다.

| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| symbol | string | 필수 | 종목 심볼 (예: AAPL) |

**예시 질문**: "AAPL 옵션 체인 조회해줘"

---

### 7. screening — 사전 정의 스크리너

Yahoo Finance의 사전 정의 스크리너를 실행합니다.

| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| screener | string | 선택 | 스크리너 유형 (아래 목록 참조, 기본값: dayGainers) |
| limit | integer | 선택 | 최대 결과 수 (기본값: 25) |

**screener 유형 목록**:
- `dayGainers` — 일일 상승 종목
- `dayLosers` — 일일 하락 종목
- `mostActives` — 거래량 상위 종목
- `aggressiveSmallCaps` — 공격적 소형주
- `growthTechnologyStocks` — 성장 기술주
- `undervaluedGrowthStocks` — 저평가 성장주
- `undervaluedLargeCaps` — 저평가 대형주
- `smallCapGainers` — 소형주 상승 종목
- `mostShortedStocks` — 공매도 상위 종목

**예시 질문**: "오늘 가장 많이 오른 종목들 보여줘"

---

### 8. customScreener — 맞춤 스크리닝

사용자 정의 조건으로 종목을 스크리닝합니다.

| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| minMarketCap | number | 선택 | 최소 시가총액 (USD) |
| maxMarketCap | number | 선택 | 최대 시가총액 (USD) |
| minPERatio | number | 선택 | 최소 PER |
| maxPERatio | number | 선택 | 최대 PER |
| limit | integer | 선택 | 최대 결과 수 (기본값: 25) |

**예시 질문**: "PER 10~20 사이 종목 찾아줘"

---

### 9. quoteSummary — 종합 기업 정보

종목의 종합 기업 정보를 조회합니다.

| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| symbol | string | 필수 | 종목 심볼 |
| type | string | 선택 | 조회 유형 (아래 목록, 기본값: essential) |

**type 유형 목록**:
- `essential` — 핵심 정보 (기본값)
- `comprehensive` — 종합 분석 데이터
- `company` — 기업 프로필
- `price` — 가격/시장 데이터
- `financials` — 재무제표
- `earnings` — 실적 데이터
- `ownership` — 소유권 정보
- `analyst` — 애널리스트 추천

**예시 질문**: "AAPL 애널리스트 의견 보여줘"

---

### 10. domain — 섹터/산업/마켓 도메인

Yahoo Finance 섹터/산업/마켓 도메인 데이터를 조회합니다.

| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| domainType | string | 선택 | 도메인 유형: sector, market, industry (기본값: sector) |
| value | string | 선택 | 섹터명 또는 마켓명 (기본값: technology) |

**섹터 목록**: technology, healthcare, financialServices, consumerDefensive, consumerCyclical, industrials, communicationServices, energy, utilities, realEstate, basicMaterials

**예시 질문**: "기술 섹터 주요 종목 보여줘"

---

### 11. fundamentals — 재무제표 시계열

종목의 재무제표 시계열 데이터를 조회합니다.

| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| symbol | string | 필수 | 종목 심볼 |

**예시 질문**: "AAPL 과거 재무제표 데이터 보여줘"

---

### 12. websocket-snapshot — WebSocket 실시간 스냅샷

Yahoo Finance WebSocket을 통해 실시간 가격을 1회 수신합니다.
장기 스트리밍 대신 MCP 호환 방식의 1회성 스냅샷으로 제공합니다.

| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| symbols | string[] | 필수 | 구독할 종목 심볼 배열 |
| timeout_seconds | integer | 선택 | 타임아웃(초), 기본값: 10 |

**예시 질문**: "AAPL 실시간 스냅샷 가져와줘"

---

## 직접 테스트 방법

```bash
# tools/list — tool 목록 확인
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' \
  | .build/debug/swift-yf-tools

# quote tool 호출
echo '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"quote","arguments":{"symbol":"AAPL"}}}' \
  | .build/debug/swift-yf-tools

# search tool 호출
echo '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"search","arguments":{"query":"Apple"}}}' \
  | .build/debug/swift-yf-tools
```

## 주의사항

- Yahoo Finance API는 인터넷 연결이 필요합니다.
- Rate limiting이 적용될 수 있으므로 과도한 호출을 피하세요.
- WebSocket 스냅샷은 시장이 열려 있을 때만 실시간 데이터를 반환합니다.
- MCP 서버는 macOS 15+ 환경에서 실행됩니다.
