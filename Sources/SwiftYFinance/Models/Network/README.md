# Network

Yahoo Finance API 응답 모델들을 API별로 체계적으로 관리합니다.

## 📁 구조

```
Network/
├── Quote/          # 실시간 시세 데이터
├── Chart/          # 차트 및 과거 데이터
├── Search/         # 종목 검색 결과
├── News/           # 뉴스 데이터
├── Options/        # 옵션 체인 데이터
├── Screening/      # 스크리너 결과
├── Domain/         # 도메인/섹터 데이터
└── Financials/     # 재무 데이터 응답
```

## 🎯 목적

Yahoo Finance API의 모든 엔드포인트별 응답 구조를 체계적으로 관리합니다.

## ✨ 특징

- **API 중심 구조**: 각 API별 독립적 관리
- **완전한 호환성**: Yahoo Finance API 필드 100% 매핑
- **확장 용이성**: 새 API 추가 시 하위 폴더만 생성
- **타입 안전성**: 모든 API 응답의 타입 보장

## 📖 사용 패턴

```swift
let client = YFClient()
let ticker = YFTicker(symbol: "AAPL")

// Quote API - 실시간 시세
let quote = try await client.quote.fetch(ticker: ticker)
print("현재가: $\(quote.regularMarketPrice ?? 0)")

// Chart API - 과거 데이터
let history = try await client.chart.fetch(ticker: ticker, period: .oneMonth)
print("데이터 포인트: \(history.prices.count)개")

// Search API - 종목 검색
let results = try await client.search.fetch(query: "Apple")
print("검색 결과: \(results.count)개")

// News API - 뉴스 데이터
let news = try await client.news.fetch(ticker: ticker)
print("뉴스 기사: \(news.count)개")
```

## 🔄 데이터 흐름

1. **API 호출**: 각 서비스에서 해당 엔드포인트 호출
2. **JSON 파싱**: Network 모델로 응답 파싱
3. **비즈니스 변환**: Business 모델로 도메인 데이터 변환
4. **클라이언트 반환**: 최종 결과 반환

각 하위 폴더는 독립적인 README.md를 포함하여 상세한 사용법을 제공합니다.