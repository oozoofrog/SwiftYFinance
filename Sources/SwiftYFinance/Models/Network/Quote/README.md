# Quote Models

실시간 주식 시세 데이터를 위한 응답 모델들입니다.

## 📋 포함된 모델

- **`YFQuote`** - 종합 실시간 시세 데이터 (모듈형 설계)
- **`YFQuoteResponse`** - query1 API 응답 래퍼
- **`YFQuoteSummaryResponse`** - quoteSummary API 응답 래퍼

## 🎯 사용 용도

- 실시간 주가 정보 조회
- 시장 상태 및 거래량 확인
- 장전/장후 거래 데이터
- 기본적인 재무 지표 (PE, 시가총액 등)

## ✨ 핵심 기능

```swift
let quote = try await client.quote.fetch(ticker: ticker)

// 모듈형 접근
print("회사명: \(quote.basicInfo.longName ?? "")")
print("현재가: $\(quote.marketData.regularMarketPrice ?? 0)")
print("거래량: \(quote.volumeInfo.regularMarketVolume ?? 0)")

// 기존 호환 인터페이스
print("심볼: \(quote.symbol ?? "")")
print("등락률: \(quote.regularMarketChangePercent ?? 0)%")

// 시장 상태별 가격
let currentPrice = quote.currentPrice // 시장 상태에 따른 적절한 가격
let changePercent = quote.currentChangePercent
```