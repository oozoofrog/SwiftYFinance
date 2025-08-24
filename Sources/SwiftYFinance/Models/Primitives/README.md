# Primitives

기본적이고 재사용 가능한 핵심 데이터 타입들을 정의합니다.

## 📋 포함된 모델

### Core Types
- **`YFTicker`** - 주식 심볼 관리 (자동 정규화, 대문자 변환)
- **`YFPrice`** - OHLCV 가격 데이터 구조
- **`YFError`** - 에러 타입 및 메시지 정의
- **`YFQuoteType`** - 종목 유형 (주식, ETF, 지수 등)

## 🎯 목적

다른 모든 모델에서 참조되는 기본 빌딩 블록을 제공합니다.

## ✨ 특징

- **타입 안전성**: Swift 강타입 시스템 활용
- **Sendable 준수**: 동시성 환경에서 안전한 데이터 전송
- **검증 로직**: 자동 데이터 정규화 및 유효성 검사
- **재사용성**: 프로젝트 전반에서 공통 사용

## 📖 사용 예시

```swift
// 티커 생성 및 정규화
let ticker = YFTicker(symbol: "  aapl  ")
print(ticker.symbol) // "AAPL"

// 가격 데이터
let price = YFPrice(
    open: 150.0,
    high: 152.5,
    low: 149.8,
    close: 151.2,
    volume: 45_000_000
)

// 종목 유형 확인
if quoteType == .equity {
    print("주식 종목입니다")
}
```