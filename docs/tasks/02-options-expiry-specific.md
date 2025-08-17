# 02. 특정 만기일 옵션 체인 조회

## 📋 작업 개요

- **파일**: `Sources/SwiftYFinance/Core/YFOptionsAPI.swift:40`
- **메서드**: `fetchOptionsChain(ticker:expiry:) -> OptionsChain`
- **설명**: 특정 만기일의 옵션 체인만 조회하는 기능

## 🔗 yfinance 참조

- **파일**: `yfinance-reference/yfinance/ticker.py:87`
- **메서드**: `option_chain(date=None, tz=None)` - date 파라미터 사용
- **검증 로직**: line 93-96 (만기일 존재 여부 확인)
- **에러 처리**: `ValueError` when date not in expirations

## 🔴 Red Phase: 테스트 작성

### 테스트 케이스
- [ ] `testFetchOptionsChainSpecificExpiry()` - 특정 만기일 조회 테스트
- [ ] `testFetchOptionsChainInvalidExpiry()` - 잘못된 만기일 에러 테스트
- [ ] `testOptionsChainExpiryValidation()` - 만료일 검증 로직 테스트

### 테스트 요구사항
- **Swift Testing 프레임워크** 사용 (`@Test`, `#expect`)
- **실제 API 데이터** 활용 (Mock 사용 금지)
- **에러 케이스 테스트** 포함 (`#expect(throws:)`)

## 🟢 Green Phase: 최소 구현

### 구현 단계
- [ ] OptionsChain vs YFOptionsChain 모델 차이점 정의
- [ ] 만기일 파라미터 처리 (date → timestamp 변환)
- [ ] 만료일 검증 로직 (yfinance ValueError 패턴)

### 기술 요구사항
- **기존 패턴 활용**: YFClient 확장, YFSession 활용
- **에러 처리**: 적절한 YFError 타입 사용
- **타입 안전성**: Swift 6.1 기능 활용

## 🟡 Refactor Phase: 코드 정리

### 최적화 작업
- [ ] `_expirations` 딕셔너리 활용 패턴 구현
- [ ] 에러 메시지 개선 및 현지화
- [ ] 중복 코드 제거 및 공통 로직 추출

### 품질 기준
- **구조 개선**: 중복 제거, 명확한 이름, 단일 책임
- **파일 크기 관리**: 250줄 초과 시 분리 검토
- **성능 최적화**: 필요시 캐싱, 동시성 개선

## 🔄 Tidy First 커밋 전략

### 커밋 순서
1. **[Tidy]** - 기존 코드 정리 (필요시)
2. **[Test]** - 실패하는 테스트 작성
3. **[Feature]** - 기능 구현
4. **[Tidy]** - 추가 구조 개선 (필요시)

### 커밋 규칙
- **구조 변경과 기능 변경 절대 혼합 금지**
- **각 커밋은 단일 책임 원칙 준수**

## ✅ 완료 체크리스트

### Red Phase 확인
- [ ] 모든 테스트가 초기에 실패함을 확인
- [ ] 테스트 명명 규칙 `test[기능명][조건]` 준수
- [ ] Swift Testing 사용 (`@Test`, `#expect`, `#expect(throws:)`)

### Green Phase 확인
- [ ] 최소 구현으로 모든 테스트 통과
- [ ] 기존 테스트와 새 테스트 모두 통과
- [ ] 컴파일 에러 없음

### Refactor Phase 확인
- [ ] 코드 품질 개선 완료
- [ ] DocC 문서화 완료
- [ ] 파일 크기 250줄 이하 유지

### 최종 검증
- [ ] 전체 테스트 스위트 통과 (254개 + 새 테스트)
- [ ] Warning 없는 깨끗한 빌드
- [ ] 코드 리뷰 완료

---

**이전 작업**: [01. 옵션 체인 조회 API](01-options-chain-api.md)  
**다음 작업**: [03. 옵션 만기일 목록 조회](03-options-expiration-dates.md)