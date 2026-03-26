# SwiftYFinance

Yahoo Finance API의 Swift 라이브러리. Python yfinance 포팅.

## 빌드 / 테스트

```bash
# 라이브러리 빌드
swift build

# 테스트 실행
swift test

# CLI 빌드 (별도 패키지)
cd CLI && swift build
```

## 아키텍처

```
YFClient (진입점, struct)
├── YFSession (actor, 인증/쿠키/네트워크 관리)
├── YFServiceCore (struct, 공통 요청/파싱 로직)
└── Services (YFService 프로토콜 준수)
    ├── YFQuoteService      — 시세 조회
    ├── YFChartService      — 과거 가격 데이터
    ├── YFSearchService     — 종목 검색
    ├── YFNewsService       — 뉴스
    ├── YFOptionsService    — 옵션 체인
    ├── YFScreenerService   — 종목 스크리닝
    ├── YFQuoteSummaryService — 종합 기업 정보
    ├── YFDomainService     — 섹터/산업 도메인
    ├── YFCustomScreenerService — 맞춤 스크리닝
    └── YFFundamentalsTimeseriesService — 재무제표
```

## 핵심 규칙

- **Swift 6.1** / swift-tools-version: 6.1
- 모든 타입은 `Sendable` 준수 — struct 우선, actor는 상태 관리 필요 시만 사용
- 서비스 추가 시: `YFService` 프로토콜 준수 + `YFClient`에 computed property 추가
- Yahoo Finance 인증: CSRF + crumb 토큰 방식 (YFSession이 관리)
- WebSocket 스트리밍: Protobuf(PricingData.proto) 기반
- 에러 처리: `YFError` enum 사용, WebSocket은 `YFWebSocketError`
- 테스트: Swift Testing 프레임워크 (`@Test`), `TestHelper`로 환경 격리
- 한국어 주석/문서
