# Command Line Interface (CLI)

SwiftYFinance의 강력한 명령줄 인터페이스

## Overview

SwiftYFinance CLI는 11개의 전문화된 명령어를 제공하여 터미널에서 직접 Yahoo Finance 데이터에 접근할 수 있게 해줍니다. 개발자, 트레이더, 데이터 분석가들이 스크립팅, 자동화, 빠른 데이터 조회에 활용할 수 있는 완전한 도구입니다.

## 설치 및 빌드

### 빌드 방법

```bash
# CLI 디렉토리로 이동
cd CLI

# 빌드
swift build -c release

# 실행 파일 생성 확인
ls .build/release/
# swiftyfinance 실행 파일이 생성됩니다
```

### 시스템 PATH에 추가 (선택사항)

```bash
# 실행 파일을 시스템 PATH에 복사
sudo cp .build/release/swiftyfinance /usr/local/bin/

# 어디서든 사용 가능
swiftyfinance --help
```

## 기본 사용법

### 명령어 구조

```bash
swiftyfinance <command> <arguments> [options]
```

### 도움말

```bash
# 전체 도움말
swiftyfinance --help

# 특정 명령어 도움말
swiftyfinance quote --help
swiftyfinance history --help
```

### 전역 옵션

모든 명령어에서 사용 가능한 공통 옵션들:

- `--json` - JSON 형식으로 원시 출력
- `--debug` - 디버그 정보 표시
- `--verbose` - 상세 출력

## 11개 전문 명령어

### 1. Quote Command - 실시간 시세 조회

**기본 사용법:**
```bash
swiftyfinance quote AAPL
```

**출력 예시:**
```
AAPL: $150.25 (+2.15, +1.45%) 
Vol: 65,234,567 | Cap: $2.4T | P/E: 25.3
Market: NASDAQ | Time: 16:00 EST
```

**JSON 출력:**
```bash
swiftyfinance quote AAPL --json
```

**JSON 출력 예시:**
```json
{
  "symbol": "AAPL",
  "regularMarketPrice": 150.25,
  "regularMarketChange": 2.15,
  "regularMarketChangePercent": 1.45,
  "regularMarketVolume": 65234567,
  "marketCap": 2400000000000,
  "trailingPE": 25.3,
  "fullExchangeName": "NASDAQ",
  "regularMarketTime": "2025-01-15T21:00:00Z"
}
```

**다중 종목 조회:**
```bash
swiftyfinance quote AAPL GOOGL MSFT
```

**디버그 모드:**
```bash
swiftyfinance quote AAPL --debug
```

### 2. QuoteSummary Command - 종합 시세 정보

**기본 사용법:**
```bash
swiftyfinance quotesummary AAPL
```

**모듈별 조회:**
```bash
swiftyfinance quotesummary AAPL --modules price,summaryDetail,defaultKeyStatistics
```

**출력 예시:**
```
AAPL - Apple Inc. (NASDAQ)
Current Price: $150.25 (+1.45%)
52 Week Range: $124.17 - $199.62
Market Cap: $2.4T
P/E Ratio: 25.3
Dividend Yield: 0.52%
Beta: 1.25
```

### 3. History Command - 과거 가격 데이터

**기본 사용법:**
```bash
swiftyfinance history AAPL
```

**기간 옵션:**
```bash
swiftyfinance history AAPL --period 1mo    # 1개월
swiftyfinance history AAPL --period 3mo    # 3개월
swiftyfinance history AAPL --period 1y     # 1년
swiftyfinance history AAPL --period 5y     # 5년
swiftyfinance history AAPL --period max    # 전체
```

**간격 옵션:**
```bash
swiftyfinance history AAPL --period 1mo --interval 1d    # 일별
swiftyfinance history AAPL --period 1d --interval 1m     # 분별
swiftyfinance history AAPL --period 1d --interval 5m     # 5분별
```

**출력 예시:**
```
AAPL Historical Data (1 Month, Daily)
Date        Open     High     Low      Close    Volume
2025-01-15  149.50   151.20   148.75   150.25   65,234,567
2025-01-14  148.90   150.10   147.80   149.45   58,765,432
2025-01-13  150.20   151.50   148.50   148.95   72,345,678
...
Total: 22 data points
```

**CSV 형식 출력:**
```bash
swiftyfinance history AAPL --format csv
```

### 4. Search Command - 종목 검색

**기본 사용법:**
```bash
swiftyfinance search Apple
```

**출력 예시:**
```
Search Results for "Apple":
1. AAPL - Apple Inc. (NASDAQ) - $150.25
2. AAPL.MX - Apple Inc. (BMV) - $150.25
3. APC.F - Apple Inc. (FRA) - €140.50

Found 3 results
```

**결과 수 제한:**
```bash
swiftyfinance search Apple --limit 5
```

**뉴스 포함 검색:**
```bash
swiftyfinance search Apple --with-news
```

**JSON 출력:**
```bash
swiftyfinance search Apple --json
```

### 5. Fundamentals Command - 재무제표 데이터

**기본 사용법:**
```bash
swiftyfinance fundamentals AAPL
```

**출력 예시:**
```
AAPL Fundamentals

Annual Income Statement (Latest):
Revenue: $394.3B
Gross Profit: $169.1B
Operating Income: $114.3B
Net Income: $97.0B

Balance Sheet:
Total Assets: $352.8B
Total Debt: $123.9B
Shareholders Equity: $63.1B

Cash Flow:
Operating Cash Flow: $122.2B
Free Cash Flow: $99.8B
Capital Expenditures: $22.4B
```

**JSON 출력:**
```bash
swiftyfinance fundamentals AAPL --json
```

**특정 메트릭만 조회:**
```bash
swiftyfinance fundamentals AAPL --metrics TotalRevenue,NetIncome,TotalAssets
```

### 6. News Command - 종목 뉴스

**기본 사용법:**
```bash
swiftyfinance news AAPL
```

**출력 예시:**
```
AAPL News (Latest 5 articles):

1. Apple Reports Strong Q4 Earnings
   Publisher: Reuters | 2 hours ago
   Apple Inc. reported better-than-expected quarterly results...
   
2. iPhone 15 Sales Exceed Expectations
   Publisher: Bloomberg | 4 hours ago
   Apple's latest iPhone model is showing strong demand...

3. Apple Expands Services Revenue
   Publisher: WSJ | 6 hours ago
   The company's services division continues to grow...
```

**뉴스 수 제한:**
```bash
swiftyfinance news AAPL --limit 10
```

**JSON 출력:**
```bash
swiftyfinance news AAPL --json
```

### 7. Options Command - 옵션 거래 데이터

**기본 사용법:**
```bash
swiftyfinance options AAPL
```

**출력 예시:**
```
AAPL Options Chain

Expiration Dates Available:
- 2025-01-17 (2 days)
- 2025-01-24 (9 days)
- 2025-01-31 (16 days)
- 2025-02-21 (37 days)

Call Options (2025-01-17):
Strike  Last   Bid   Ask   Volume  Open Interest
145.00  7.25   7.20  7.30  1,234   5,678
150.00  3.50   3.45  3.55  2,345   8,901
155.00  1.25   1.20  1.30  1,567   3,456

Put Options (2025-01-17):
Strike  Last   Bid   Ask   Volume  Open Interest
145.00  1.75   1.70  1.80  987     4,321
150.00  3.25   3.20  3.30  1,543   6,789
155.00  6.50   6.45  6.55  876     2,345
```

**특정 만료일:**
```bash
swiftyfinance options AAPL --expiration 2025-01-17
```

**JSON 출력:**
```bash
swiftyfinance options AAPL --json
```

### 8. Screening Command - 종목 스크리닝

**기본 사용법:**
```bash
swiftyfinance screening --country US --sector Technology
```

**출력 예시:**
```
US Technology Stocks Screening Results:

1. AAPL - Apple Inc.
   Price: $150.25 | Cap: $2.4T | P/E: 25.3

2. GOOGL - Alphabet Inc.
   Price: $142.50 | Cap: $1.8T | P/E: 22.1

3. MSFT - Microsoft Corporation
   Price: $378.90 | Cap: $2.8T | P/E: 28.5

Found 50 results (showing top 10)
```

**고급 필터링:**
```bash
swiftyfinance screening --country US --sector Technology --min-market-cap 1000000000 --max-pe-ratio 30
```

**JSON 출력:**
```bash
swiftyfinance screening --country US --sector Technology --json
```

### 9. Domain Command - 섹터/산업 정보

**섹터 목록:**
```bash
swiftyfinance domain sectors
```

**출력 예시:**
```
Available Sectors:
- Technology
- Healthcare
- Financial Services
- Consumer Cyclical
- Industrials
- Communication Services
- Consumer Defensive
- Energy
- Real Estate
- Basic Materials
- Utilities
```

**특정 섹터의 산업 목록:**
```bash
swiftyfinance domain industries --sector Technology
```

**JSON 출력:**
```bash
swiftyfinance domain sectors --json
```

### 10. CustomScreener Command - 커스텀 스크리너

**기본 사용법:**
```bash
swiftyfinance customscreener --market-cap-min 10000000000 --pe-ratio-max 25
```

**출력 예시:**
```
Custom Screening Results:
Criteria: Market Cap > $10B, P/E < 25

1. AAPL - Apple Inc.
   Cap: $2.4T | P/E: 25.3 | Sector: Technology

2. JNJ - Johnson & Johnson
   Cap: $445.2B | P/E: 15.8 | Sector: Healthcare

3. PG - Procter & Gamble
   Cap: $356.7B | P/E: 24.1 | Sector: Consumer Defensive

Found 25 matching stocks
```

**복잡한 조건:**
```bash
swiftyfinance customscreener \
  --market-cap-min 1000000000 \
  --market-cap-max 100000000000 \
  --pe-ratio-max 20 \
  --dividend-yield-min 2.0 \
  --sector "Financial Services"
```

### 11. WebSocket Command - 실시간 스트리밍

**기본 사용법:**
```bash
swiftyfinance websocket AAPL GOOGL MSFT
```

**출력 예시:**
```
Starting real-time streaming for: AAPL, GOOGL, MSFT
Press Ctrl+C to stop

[16:30:15] AAPL: $150.25 (+0.05)
[16:30:16] GOOGL: $142.51 (+0.01)
[16:30:17] MSFT: $378.95 (+0.05)
[16:30:18] AAPL: $150.27 (+0.02)
...
```

**JSON 스트림:**
```bash
swiftyfinance websocket AAPL --json
```

**출력을 파일로 저장:**
```bash
swiftyfinance websocket AAPL GOOGL > realtime_data.log
```

## JSON 샘플 파일 활용

CLI는 `json-samples/` 디렉토리의 실제 API 응답 샘플을 참조할 수 있습니다:

### 사용 가능한 샘플 파일들

```bash
# 프로젝트 루트의 json-samples/ 디렉토리
ls json-samples/

# 출력:
# quote-aapl.json (3.2KB) - 실시간 시세 샘플
# history-aapl.json (7.5KB) - 1개월 차트 데이터 샘플
# search-aapl.json (11KB) - 검색 결과 샘플 (뉴스 포함)
# fundamentals-aapl.json (561KB) - 완전한 재무제표 샘플
# options-aapl.json (45KB) - 옵션 체인 데이터 샘플
# news-aapl.json (28KB) - 뉴스 데이터 샘플
# screening-results.json (156KB) - 스크리닝 결과 샘플
```

### 샘플 데이터로 개발/테스트

**오프라인 모드 (개발용):**
```bash
# 실제 API 대신 샘플 데이터 사용
swiftyfinance quote AAPL --offline --sample json-samples/quote-aapl.json
```

**샘플 데이터 검증:**
```bash
# 샘플 파일의 구조 확인
swiftyfinance validate-sample json-samples/quote-aapl.json
```

**샘플에서 스키마 생성:**
```bash
# JSON 스키마 추출 (개발자용)
swiftyfinance extract-schema json-samples/quote-aapl.json
```

## 고급 사용법

### 스크립트 작성

**Bash 스크립트 예제:**
```bash
#!/bin/bash

# 포트폴리오 모니터링 스크립트
SYMBOLS=("AAPL" "GOOGL" "MSFT" "AMZN" "TSLA")

echo "Portfolio Status - $(date)"
echo "================================"

for symbol in "${SYMBOLS[@]}"; do
    result=$(swiftyfinance quote $symbol --json)
    price=$(echo $result | jq -r '.regularMarketPrice')
    change=$(echo $result | jq -r '.regularMarketChangePercent')
    
    printf "%-6s: $%-8.2f (%+.2f%%)\n" $symbol $price $change
done
```

**Python 통합:**
```python
#!/usr/bin/env python3
import subprocess
import json

def get_quote(symbol):
    result = subprocess.run(
        ['swiftyfinance', 'quote', symbol, '--json'],
        capture_output=True, text=True
    )
    return json.loads(result.stdout)

# 사용 예제
quote = get_quote('AAPL')
print(f"AAPL: ${quote['regularMarketPrice']}")
```

### 자동화 및 모니터링

**Cron 작업 예제:**
```bash
# 매일 오전 9시에 포트폴리오 리포트 생성
0 9 * * * /usr/local/bin/swiftyfinance quote AAPL GOOGL MSFT --json > /tmp/daily_portfolio.json

# 매분 실시간 데이터 수집
* * * * * /usr/local/bin/swiftyfinance quote AAPL >> /var/log/aapl_prices.log
```

**시스템 모니터링:**
```bash
# 특정 가격 조건 모니터링
while true; do
    price=$(swiftyfinance quote AAPL --json | jq -r '.regularMarketPrice')
    if (( $(echo "$price > 160" | bc -l) )); then
        echo "AAPL hit $160! Current: $price" | mail -s "Price Alert" user@example.com
    fi
    sleep 300  # 5분마다 체크
done
```

### CI/CD 통합

**GitHub Actions 예제:**
```yaml
name: Market Data Collection
on:
  schedule:
    - cron: '0 */4 * * *'  # 4시간마다

jobs:
  collect-data:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Swift
      uses: swift-actions/setup-swift@v1
      
    - name: Build CLI
      run: |
        cd CLI
        swift build -c release
        
    - name: Collect Market Data
      run: |
        ./CLI/.build/release/swiftyfinance quote AAPL GOOGL MSFT --json > data/market_$(date +%Y%m%d_%H%M).json
        
    - name: Commit Data
      run: |
        git add data/
        git commit -m "Auto: Market data $(date)"
        git push
```

## 성능 및 최적화

### 배치 처리

**대량 종목 조회:**
```bash
# 100개 종목을 10개씩 배치 처리
cat symbols_list.txt | xargs -n 10 swiftyfinance quote --json
```

**병렬 처리:**
```bash
# GNU parallel 사용
parallel -j 4 swiftyfinance quote {} --json ::: AAPL GOOGL MSFT AMZN TSLA NVDA
```

### 캐싱 전략

**임시 캐시 디렉토리:**
```bash
# 결과를 임시 파일로 캐싱
CACHE_DIR=/tmp/swiftyfinance_cache
mkdir -p $CACHE_DIR

if [ -f "$CACHE_DIR/AAPL_$(date +%Y%m%d_%H).json" ]; then
    cat "$CACHE_DIR/AAPL_$(date +%Y%m%d_%H).json"
else
    swiftyfinance quote AAPL --json | tee "$CACHE_DIR/AAPL_$(date +%Y%m%d_%H).json"
fi
```

## 문제 해결

### 일반적인 문제들

**1. 빌드 실패:**
```bash
# Swift 버전 확인
swift --version
# Swift 6.1 이상 필요

# 클린 빌드
swift package clean
swift build
```

**2. 네트워크 에러:**
```bash
# 디버그 모드로 상세 정보 확인
swiftyfinance quote AAPL --debug

# 네트워크 연결 테스트
curl -I https://finance.yahoo.com
```

**3. Rate Limiting:**
```bash
# 요청 간격 조정
for symbol in AAPL GOOGL MSFT; do
    swiftyfinance quote $symbol
    sleep 1  # 1초 대기
done
```

**4. JSON 파싱 에러:**
```bash
# JSON 출력을 jq로 검증
swiftyfinance quote AAPL --json | jq '.'

# 파일로 저장 후 검증
swiftyfinance quote AAPL --json > quote.json
jq '.' quote.json
```

### 로그 및 디버깅

**로그 레벨 설정:**
```bash
# 환경 변수로 로그 레벨 조정
export SWIFTYFINANCE_LOG_LEVEL=DEBUG
swiftyfinance quote AAPL
```

**네트워크 요청 추적:**
```bash
# HTTP 요청/응답 상세 정보
swiftyfinance quote AAPL --debug --verbose
```

## 확장 및 커스터마이징

### 커스텀 명령어 추가

CLI 소스코드(`CLI/Sources/SwiftYFinanceCLI/`)를 수정하여 새로운 명령어를 추가할 수 있습니다:

```swift
struct MyCustomCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "mycustom",
        abstract: "My custom command"
    )
    
    @Argument(help: "Symbol to analyze")
    var symbol: String
    
    mutating func run() async throws {
        // 커스텀 로직 구현
        print("Custom analysis for \(symbol)")
    }
}

// SwiftYFinanceCLI.swift의 subcommands에 추가
subcommands: [
    // ... 기존 명령어들
    MyCustomCommand.self
]
```

### 출력 포맷 커스터마이징

**CSV 출력 추가:**
```swift
extension QuoteCommand {
    func outputCSV(_ quotes: [YFQuote]) {
        print("Symbol,Price,Change,ChangePercent,Volume")
        for quote in quotes {
            print("\(quote.symbol),\(quote.regularMarketPrice),\(quote.regularMarketChange),\(quote.regularMarketChangePercent),\(quote.regularMarketVolume ?? 0)")
        }
    }
}
```

## Next Steps

CLI 도구를 익혔다면 다음을 확인해보세요:

- <doc:GettingStarted> - Swift 라이브러리 통합
- <doc:Architecture> - CLI 내부 구조 이해
- <doc:AdvancedFeatures> - 고급 기능 활용
- <doc:BestPractices> - 자동화 및 모니터링 모범 사례