# 용어 가이드

## 핵심 용어
- **`ticker`**: YFTicker 인스턴스
- **`symbol`**: 문자열 형태의 심볼값
- **`fetch`**: API 호출을 통한 데이터 조회
- **`period`**: 데이터 조회 기간 (.oneYear, .oneMonth)
- **`quote`**: 가격과 부가 정보를 포함한 시세 데이터

## 문서화 스타일
- 단정적 톤: "데이터를 조회합니다"
- 실행 가능한 예시 코드 제공
- 매개변수와 반환값 명확히 설명

## 아키텍처 원칙
- **모델**: 순수한 데이터 구조 (API 호출 금지)
- **클라이언트**: 모든 API 호출은 YFClient를 통해

```swift
// ✅ 올바른 패턴
let client = YFClient()
let quote = try await client.fetchQuote(ticker: ticker)

// ❌ 잘못된 패턴  
let quote = try await YFTicker.fetchQuote() // 모델에 API 로직 금지
```