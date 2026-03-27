---
globs: Sources/SwiftYFinance/Core/**/*.swift
---

# Core 레이어 규칙

이 디렉토리는 SwiftYFinance의 핵심 인프라를 담당한다.

## 구조

- `APIBuilder/` — 각 서비스별 URL 빌더 (YF*URLBuilder). 새 API 엔드포인트 추가 시 여기에 빌더 생성.
- `Cache/` — 검색 결과 캐싱 (YFSearchCache)
- `Network/` — 브라우저 모방(YFBrowserImpersonator), HTML 파싱, 로깅, 레이트 리미팅, 응답 파싱
- `Session/` — YFSession(actor): 인증, 쿠키, 네트워크 세션 관리. YFSessionState/Auth/Cookie로 분리.

## 패턴

- URL 빌더는 순수 함수형 — 상태 없이 URL만 생성
- YFSession은 **actor** — 인증 상태를 안전하게 관리하는 유일한 mutable 지점
- YFServiceCore는 struct — 모든 서비스가 composition으로 공유하는 요청/파싱 로직
- 네트워크 컴포넌트는 `nonisolated` 또는 `Sendable` struct로 구현
