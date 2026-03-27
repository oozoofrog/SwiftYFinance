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
YFClient (진입점, nonisolated struct)
├── YFSession (actor, 인증/쿠키/네트워크 관리)
├── YFServiceCore (nonisolated struct, 공통 요청/파싱 로직)
└── Services (YFService 프로토콜 준수, 모두 nonisolated struct)
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

- **Swift 6.2** / swift-tools-version: 6.2
- 모든 타입은 `Sendable` 준수 — struct 우선, actor는 상태 관리 필요 시만 사용
- **nonisolated 타입 정책**: 순수 데이터/유틸리티 struct에는 타입 수준 `nonisolated` 적용
  - 라이브러리 소비자의 어떤 actor isolation 컨텍스트에서도 안전하게 사용 가능
  - `nonisolated struct`는 Swift 6.2에서 Sendable 자동 충족 (단, public struct는 cross-module 사용 시 명시 필요)
- **@concurrent CPU-bound 함수 정책**: JSON 파싱, Protobuf 파싱 등 CPU-집약 함수에 `@concurrent` 적용
  - `@concurrent func`은 반드시 `async`여야 함
  - 호출부에 반드시 `await`를 추가해야 함
  - 라이브러리 소비자가 MainActor에서 호출해도 자동으로 concurrent thread pool에서 실행
- **defaultIsolation: MainActor 금지**: 이 라이브러리는 소비자 환경에 간섭하지 않아야 함
  - `defaultIsolation: MainActor`는 앱 타겟에만 적합하며, 라이브러리에서 사용하면
    소비자의 actor isolation 설계에 예기치 않은 영향을 줄 수 있음
  - 대신 필요한 타입에 개별 `nonisolated` 또는 actor를 명시적으로 적용
- 서비스 추가 시: `YFService` 프로토콜 준수 (nonisolated struct) + `YFClient`에 computed property 추가
- Yahoo Finance 인증: CSRF + crumb 토큰 방식 (YFSession이 관리)
- WebSocket 스트리밍: Protobuf(PricingData.proto) 기반
- 에러 처리: `YFError` enum 사용, WebSocket은 `YFWebSocketError`
- 테스트: Swift Testing 프레임워크 (`@Test`), `TestHelper`로 환경 격리
- 한국어 주석/문서
