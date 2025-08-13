# SwiftYFinance 포팅 계획

## 🚨 **작업 원칙 (매우 중요!)**

### TDD 원칙
- ✅ **TDD (Red → Green → Refactor)**: 실패하는 테스트 → 최소 구현 → 리팩토링
- ✅ **Tidy First**: 구조 변경과 동작 변경 분리
- ✅ **한 번에 하나의 테스트만 작업**
- ✅ **테스트 통과를 위한 최소 코드만 구현**

### 테스트 프레임워크 원칙
- ✅ **Swift Testing 필수**: 모든 테스트는 반드시 Swift Testing(`import Testing`, `@Test`, `#expect`) 사용
- ❌ **XCTest 금지**: 새로운 테스트에서 XCTest(`import XCTest`, `XCTestCase`, `XCTAssert`) 사용 금지
- ✅ **기존 XCTest → Swift Testing 마이그레이션**: 기존 XCTest 테스트들을 점진적으로 Swift Testing으로 전환

### 문서화 및 커밋 규칙
- ✅ **문서 먼저 업데이트**: 작업 완료 후 바로 커밋하지 말고 **반드시 문서부터 업데이트**
- ✅ **각 테스트 완료시 서브플랜 업데이트 및 필요시 plan.md도 업데이트 후 git commit 실행**
- "단계"는 개별 테스트 케이스 또는 기능적으로 완결된 작업 단위를 의미

### 개발 방법론
- ✅ **참조 기반 학습**: 각 테스트 작성 전 yfinance-reference/ 폴더의 Python 코드 참조
- ✅ **실제 데이터 구조 확인**: Python yfinance로 실제 API 응답 구조 파악 후 Swift 모델 설계

---

## 🎯 프로젝트 개요
Python yfinance 라이브러리를 Swift로 TDD 방식으로 포팅

---

## 📊 현재 상황 (2025-08-13)

### 완료된 Phase
| Phase | 상태 | 상세 계획 |
|-------|------|-----------|
| **Phase 1-4** | ✅ 완료 | [기본 구조, 모델, 네트워크, API 통합](docs/plans/) |

### 🚨 긴급 수정 필요 사항
- **Yahoo Finance API 인증 문제**: 13개 테스트가 "Authentication failed" 에러로 실패
- **우선순위**: 파일 분리 작업 완료 → 즉시 curl_cffi 포팅 시작
- **상세 계획**: [Phase 4.5 curl_cffi Swift 포팅](docs/plans/phase4.5-curl-cffi-porting.md) ✅ 생성완료

---

## 🎯 다음 작업

### 1. ✅ 소스 파일 구조 정리 (완료)
- **~~YFClient.swift 분리~~**: ✅ 완료
- **~~YFFinancials.swift 분리~~**: ✅ 완료 (2025-08-13)
- **~~YFSession.swift 분리~~**: ✅ 완료 (2025-08-13)
- **~~YFCookieManagerTests.swift 분리~~**: ✅ 완료 (2025-08-13)

**상세 계획**: [파일 구조 정리 가이드](docs/plans/file-organization.md)

### 2. ⏳ Phase 4.5: curl_cffi Swift 포팅 (현재 진행 중)
- **목표**: Yahoo Finance API 인증 문제 해결 (인증 성공률 향상)
- **접근법**: Python yfinance의 Chrome 모방 + Swift Concurrency 기반 Rate Limiting
- **현재 단계**: Phase 4.5.2 완료, Phase 4.5.3 네트워크 계층 최적화 준비
- **Phase 4.5.2 성과**: Swift Concurrency 완전 대응, XCTest → Swift Testing 마이그레이션 완료

**상세 계획**: [Phase 4.5 curl_cffi Swift 포팅](docs/plans/phase4.5-curl-cffi-porting.md)

### 3. Phase 5: Advanced Features (대기 중)
**상세 계획**: [Advanced Features](docs/plans/phase5-advanced.md)

---

## 🔗 작업 절차

1. **참조 분석**: yfinance-reference/ 폴더에서 Python 구현 확인
2. **실제 데이터 확인**: Python yfinance로 API 응답 구조 파악  
3. **Swift 모델 설계**: 데이터 구조 기반 Swift 모델 정의
4. **TDD 구현**: 실패하는 테스트 → 실제 API 구현 → 리팩토링
5. **검증**: Python yfinance와 동일한 결과 반환 확인
6. **서브플랜 업데이트 및 커밋**

---

📋 **상세 계획은 각 Phase별 서브플랜 문서를 참조하세요**