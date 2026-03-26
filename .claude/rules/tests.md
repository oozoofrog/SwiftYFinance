---
globs: Tests/**/*.swift
---

# 테스트 규칙

## 프레임워크

- **Swift Testing** 사용 (`@Test`, `#expect`, `@Suite`)
- XCTest 아님

## 테스트 격리

- `TestHelper.setUp()` / `TestHelper.tearDown()` 으로 환경 격리
- Yahoo 쿠키 정리, Rate Limiter 테스트 모드, 세션 리셋 포함
- 모킹 없이 실제 API 사용 (통합 테스트 성격)

## 구조

- `Core/` — URL 빌더, WebSocket 테스트
- `Services/` — 각 서비스별 테스트
- `Models/` — 모델 단위 테스트
- `Integration/` — 통합 테스트
- `Performance/` — 메모리/성능 테스트

## 주의사항

- Yahoo Finance API는 외부 서비스 — 네트워크 없으면 테스트 실패 가능
- Rate limiting 고려하여 테스트 간 적절한 간격 유지
