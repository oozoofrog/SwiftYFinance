# SwiftYFinance Models

SwiftYFinance의 모든 데이터 모델들을 용도별로 체계적으로 관리합니다.

## 📂 구조 개요

```
Models/
├── Primitives/         # 기본 타입들 (4개)
├── Configuration/      # API 설정 (3개) 
├── Streaming/          # 실시간 데이터 (1개)
├── Screener/           # 스크리너 쿼리 (1개)
├── Business/           # 비즈니스 로직 (6개)
└── Network/            # API 응답 모델 (12개)
    ├── Quote/          # 실시간 시세
    ├── Chart/          # 과거 데이터
    ├── Search/         # 검색 결과
    ├── News/           # 뉴스 데이터
    ├── Options/        # 옵션 체인
    ├── Screening/      # 스크리너 결과
    ├── Domain/         # 도메인/섹터
    └── Financials/     # 재무 데이터
```

## 🎯 설계 원칙

### **용도별 분류**
각 폴더는 명확한 목적과 책임을 가지고 있습니다.

### **의존성 방향**
```
Primitives → Configuration → Business → Network
     ↑              ↑            ↑
 기본 타입      API 설정    비즈니스 로직
```

### **확장성**
새로운 API나 기능 추가 시 해당 카테고리에 쉽게 추가할 수 있습니다.

## 📋 카테고리별 상세

| 카테고리 | 목적 | 대표 모델 | 특징 |
|---------|------|-----------|------|
| **Primitives** | 기본 데이터 타입 | YFTicker, YFPrice | 재사용성, 타입 안전성 |
| **Configuration** | API 설정 | YFDomain, YFSearchQuery | enum 기반, 설정 집중화 |
| **Streaming** | 실시간 데이터 | YFLiveStreamMessage | WebSocket, 동시성 |
| **Screener** | 복잡 쿼리 | YFScreenerQuery | 논리 연산, 조건 조합 |
| **Business** | 도메인 모델 | YFFinancials | 비즈니스 로직, 분석 중심 |
| **Network** | API 응답 | YFQuote, YFNews | API별 구조화, 완전 호환성 |

## ✨ 핵심 특징

### **타입 안전성**
- 모든 모델이 Swift 강타입 시스템 활용
- 컴파일 타임 오류 검출
- Optional을 통한 안전한 nil 처리

### **동시성 지원**
- 모든 모델이 `Sendable` 준수  
- 멀티스레딩 환경에서 안전한 데이터 전송
- async/await와 완벽 호환

### **API 호환성**
- Python yfinance와 100% 필드 호환
- Yahoo Finance API 원시 응답 완전 지원
- 기존 코드와의 하위 호환성

### **개발자 경험**
- 직관적인 폴더 구조
- 각 폴더별 상세한 README 제공
- 실용적인 사용 예시 포함

## 📖 빠른 시작

```swift
import SwiftYFinance

// 클라이언트 생성
let client = YFClient()
let ticker = YFTicker(symbol: "AAPL")

// 실시간 시세 (Network/Quote)
let quote = try await client.quote.fetch(ticker: ticker)

// 과거 데이터 (Network/Chart)  
let history = try await client.chart.fetch(ticker: ticker, period: .oneMonth)

// 재무 데이터 (Business)
let financials = try await client.fetchFinancials(ticker: ticker)

// 뉴스 데이터 (Network/News)
let news = try await client.news.fetch(ticker: ticker)

// 실시간 스트리밍 (Streaming)
for await message in try await client.startRealTimeStreaming(symbols: ["AAPL"]) {
    print("실시간 가격: \(message.price ?? 0)")
}
```

## 🔍 모델 탐색

각 하위 폴더의 README.md에서 상세한 사용법과 예시를 확인할 수 있습니다:

- [Primitives/README.md](Primitives/README.md) - 기본 타입 사용법
- [Configuration/README.md](Configuration/README.md) - API 설정 방법
- [Business/README.md](Business/README.md) - 비즈니스 분석 예시
- [Network/README.md](Network/README.md) - API별 응답 구조

**명확하고 직관적인 모델 구조로 효율적인 금융 데이터 처리를 지원합니다!** 📈