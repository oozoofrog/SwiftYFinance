---
globs: Sources/SwiftYFinance/Services/**/*.swift
---

# Services 레이어 규칙

Yahoo Finance API의 각 기능 단위를 서비스로 구현한다.

## 새 서비스 추가 절차

1. `YFService` 프로토콜 준수하는 struct 생성
2. `client: YFClient` 프로퍼티 필수
3. `Core/APIBuilder/`에 대응하는 URL 빌더 생성
4. `YFClient`에 computed property로 서비스 노출
5. 대응하는 테스트 파일을 `Tests/SwiftYFinanceTests/Services/`에 생성

## 공통 패턴

- 인증 필요 API: `performFetch()` / `performPostFetch()` 사용
- 공개 API (인증 불필요): `performPublicFetch()` 사용
- Raw JSON 반환: `performFetchRawJSON()` / `performPublicFetchRawJSON()`
- 모든 서비스 메서드는 `async throws`
- YFServiceCore를 통한 composition (상속 아님)
