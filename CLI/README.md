# SwiftYFinance CLI

SwiftYFinance용 명령줄 인터페이스 도구입니다. Yahoo Finance API를 통해 주식 데이터를 조회하고 분석할 수 있습니다.

## 설치

```bash
cd CLI
swift build
```

## 사용법

### 기본 명령어

```bash
# 도움말 보기
swift run swiftyfinance --help

# 버전 확인
swift run swiftyfinance --version
```

### 1. 실시간 주식 시세 조회 (quote)

```bash
# 기본 사용법
swift run swiftyfinance quote AAPL

# 디버그 모드로 실행
swift run swiftyfinance quote TSLA --debug

# JSON 원본 응답 출력
swift run swiftyfinance quote AAPL --json
```

**출력 예시:**
```
📈 AAPL - Apple Inc.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Current Price:    $225.00
Change:           🔴 $-1.01 (-0.45%)
Previous Close:   $226.01

Open:             $226.28
High:             $226.52
Low:              $224.51
Volume:           12M
Market Cap:       $3.3T
```

### 2. 과거 데이터 조회 (history)

```bash
# 1개월간 데이터
swift run swiftyfinance history AAPL --period 1mo

# 1년간 데이터
swift run swiftyfinance history TSLA --period 1y

# JSON 원본 응답 출력
swift run swiftyfinance history AAPL --period 1mo --json

# 지원되는 기간: 1d, 5d, 1mo, 3mo, 6mo, 1y, 2y, 5y, 10y, max
```

**출력 예시:**
```
📈 AAPL - 1MO Historical Data
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Period:           Jul 23, 2025 to Aug 22, 2025
Total Days:       22

Performance Summary:
Starting Price:   $220.45
Ending Price:     $225.00
Total Return:     🟢 2.06%

Recent Prices:
Date         Open      High      Low       Close     Volume
───────────────────────────────────────────────────────────
08/18/25  $224.10  $225.45  $223.80  $224.95   8.5M
08/19/25  $225.00  $226.20  $224.50  $225.80   9.2M
```

### 3. 회사 검색 (search)

```bash
# 회사명으로 검색
swift run swiftyfinance search "Apple"

# 결과 개수 제한
swift run swiftyfinance search "Technology" --limit 5

# JSON 원본 응답 출력
swift run swiftyfinance search "Apple" --json
```

**출력 예시:**
```
🔎 Search Results for 'Apple'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Found 7 results (showing first 5):

Symbol    Type      Name
────────────────────────────────────────────────────────
AAPL      📈 EQUITY  Apple Inc.
APLE      📈 EQUITY  Apple Hospitality REIT, Inc.
```

### 4. 기업 펀더멘털 데이터 (fundamentals)

```bash
# 재무 데이터 조회
swift run swiftyfinance fundamentals AAPL

# JSON 원본 응답 출력
swift run swiftyfinance fundamentals AAPL --json
```

**출력 예시:**
```
💼 AAPL - Fundamental Data
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Available Data Metrics:
📈 Total Revenue (Annual): $394.3B
💰 Net Income (Annual): $99.8B
🏢 Total Assets (Annual): $364.0B
📊 Stockholder Equity (Annual): $74.1B
💵 Free Cash Flow (Annual): $84.7B
```

### 5. 종목 스크리닝 (screening)

```bash
# 당일 상승 종목 조회
swift run swiftyfinance screening day_gainers

# 결과 개수 제한
swift run swiftyfinance screening most_actives --limit 10

# JSON 원본 응답 출력
swift run swiftyfinance screening day_gainers --json
```

**사용 가능한 스크리너:**
- `day_gainers`: 당일 상승 종목
- `day_losers`: 당일 하락 종목
- `most_actives`: 거래량 높은 종목
- `aggressive_small_caps`: 공격적 소형주
- `growth_technology_stocks`: 성장 기술주
- `undervalued_growth_stocks`: 저평가 성장주
- `undervalued_large_caps`: 저평가 대형주
- `small_cap_gainers`: 소형주 상승 종목
- `most_shorted_stocks`: 공매도 비중 높은 종목

**출력 예시:**
```
📊 Stock Screening Results: day_gainers
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Symbol Company                     Price    Change%   Volume
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AAPL   Apple Inc.               $225.00      2.56%     5.2M
TSLA   Tesla, Inc.              $180.45      4.23%    12.8M
MSFT   Microsoft Corporation    $315.20      1.89%     8.4M

Found 3 stocks

📈 Summary:
   Average Price: $240.22
   Average Change: 2.89%
```

## 옵션

### 전역 옵션
- `--help, -h`: 도움말 표시
- `--version`: 버전 정보 표시

### 명령별 옵션

**quote**
- `--debug, -d`: 디버그 출력 활성화
- `--json, -j`: 원본 JSON 응답 출력

**history**
- `--period, -p`: 조회 기간 (기본값: 1mo)
- `--debug, -d`: 디버그 출력 활성화
- `--json, -j`: 원본 JSON 응답 출력

**search**
- `--limit, -l`: 최대 결과 개수 (기본값: 10)
- `--debug, -d`: 디버그 출력 활성화
- `--json, -j`: 원본 JSON 응답 출력

**fundamentals**
- `--debug, -d`: 디버그 출력 활성화
- `--json, -j`: 원본 JSON 응답 출력

**screening**
- `--limit, -l`: 최대 결과 개수 (기본값: 25, 최대: 250)
- `--debug, -d`: 디버그 출력 활성화
- `--json, -j`: 원본 JSON 응답 출력

## 지원되는 기간 옵션

| 기간 | 설명 |
|------|------|
| `1d` | 1일 |
| `5d` | 5일 |
| `1mo` | 1개월 |
| `3mo` | 3개월 |
| `6mo` | 6개월 |
| `1y` | 1년 |
| `2y` | 2년 |
| `5y` | 5년 |
| `10y` | 10년 |
| `max` | 전체 데이터 |

## JSON 원본 출력

모든 명령어에서 `--json` 옵션을 사용하여 Yahoo Finance API의 원본 JSON 응답을 받을 수 있습니다.

```bash
# 다양한 JSON 출력 예시
swift run swiftyfinance quote AAPL --json
swift run swiftyfinance search "Apple" --json
swift run swiftyfinance history TSLA --period 1mo --json
swift run swiftyfinance fundamentals MSFT --json
swift run swiftyfinance screening day_gainers --json
```

**JSON 출력 특징:**
- Yahoo Finance API의 **원본 응답**을 그대로 출력
- Swift 모델 파싱 없이 **순수 API 데이터** 제공
- Pretty-printed JSON 형식으로 **가독성 향상**
- 외부 도구나 스크립트에서 **파싱하기 용이**
- API 디버깅 및 데이터 분석에 **최적화**

## 에러 처리

CLI는 다음과 같은 에러 상황을 친화적으로 처리합니다:

```bash
❌ Failed to fetch quote
💡 Please check if the ticker symbol is valid.
```

**JSON 모드에서는 에러도 JSON 형식으로 출력됩니다:**
```json
{
  "error": true,
  "message": "Failed to fetch quote",
  "details": "Authentication failed after 2 attempts",
  "type": "YFError"
}
```

**지원하는 에러 유형:**
- 네트워크 연결 오류
- 잘못된 티커 심볼
- API 응답 오류
- 인증 문제

## 기술 스택

- **Swift 6.2**: 최신 Swift 언어 기능 활용
- **SwiftYFinance**: Yahoo Finance API 클라이언트
- **ArgumentParser**: 명령줄 인자 파싱
- **Protocol + Struct**: 현대적인 Swift 아키텍처

## 개발

### 빌드
```bash
swift build
```

### 릴리스 빌드
```bash
swift build -c release
```

### 테스트
```bash
# 기본 기능 테스트
swift run swiftyfinance quote AAPL
swift run swiftyfinance search "Apple" --limit 3
swift run swiftyfinance history TSLA --period 1mo
swift run swiftyfinance screening day_gainers --limit 5
```

## 라이선스

SwiftYFinance 프로젝트와 동일한 라이선스를 따릅니다.