# SwiftYFinance CLI - JSON Samples

이 디렉토리는 SwiftYFinance CLI의 모든 명령어에 대한 AAPL 티커의 JSON 응답 샘플을 포함합니다.

## 파일 목록

### 1. `aapl-quote.json` (3.2KB)
```bash
swift run swiftyfinance quote AAPL --json
```
- **용도**: 실시간 주식 시세 정보
- **포함 데이터**:
  - 현재 가격, 고가, 저가, 거래량
  - 시가총액, P/E 비율, 배당 정보
  - 52주 최고/최저가
  - 시장 상태 및 거래소 정보

### 2. `aapl-history.json` (7.5KB)
```bash
swift run swiftyfinance history AAPL --period 1mo --json
```
- **용도**: 과거 가격 데이터 (1개월)
- **포함 데이터**:
  - 일별 OHLCV (시가, 고가, 저가, 종가, 거래량) 데이터
  - 메타데이터 (심볼, 통화, 시간대, 거래 기간)
  - 차트 렌더링을 위한 기본 정보

### 3. `aapl-search.json` (11KB)
```bash
swift run swiftyfinance search Apple --json
```
- **용도**: "Apple" 검색 결과
- **포함 데이터**:
  - 검색된 종목 목록
  - 관련 뉴스 기사
  - 썸네일 이미지 URL
  - 발행인 및 게시 시간 정보

### 4. `aapl-fundamentals.json` (561KB)
```bash
swift run swiftyfinance fundamentals AAPL --json
```
- **용도**: 기본 재무 정보 (통합 API)
- **포함 데이터**:
  - 연간/분기별 재무제표 데이터
  - 손익계산서, 대차대조표, 현금흐름표
  - 다양한 재무 비율 및 지표
  - 시계열 데이터 (여러 년도)

### 5. `aapl-news.json` (1.2KB)
```bash
swift run swiftyfinance news AAPL --json --count 3
```
- **용도**: 종목 관련 뉴스 기사
- **포함 데이터**:
  - 뉴스 기사 제목 및 링크
  - 발행 일시 및 출처
  - 뉴스 카테고리 분류
  - Yahoo Finance 뉴스 API 응답

## 사용법

이 샘플 파일들은 다음과 같은 용도로 활용할 수 있습니다:

1. **API 응답 구조 이해**: 각 엔드포인트의 JSON 구조 파악
2. **테스트 데이터**: 유닛 테스트 및 통합 테스트용 목 데이터
3. **문서화**: API 문서 작성 시 실제 응답 예시
4. **클라이언트 개발**: 프론트엔드 개발 시 타입 정의 참고

## 데이터 생성 시점

- 생성일: 2025년 8월 22일
- 마켓 데이터: 실시간 Yahoo Finance API 응답
- 참고: 실제 시장 데이터이므로 시간이 지나면 일부 값이 달라질 수 있습니다.

## CLI 명령어 전체 옵션

각 명령어의 전체 옵션을 확인하려면:

```bash
# Quote 명령어 옵션
swift run swiftyfinance quote --help

# History 명령어 옵션  
swift run swiftyfinance history --help

# Search 명령어 옵션
swift run swiftyfinance search --help

# Fundamentals 명령어 옵션
swift run swiftyfinance fundamentals --help

# News 명령어 옵션
swift run swiftyfinance news --help
```