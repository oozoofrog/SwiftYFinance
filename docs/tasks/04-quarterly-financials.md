# 04. 분기별 재무제표 조회

## 📋 작업 개요

- **파일**: `Sources/SwiftYFinance/Core/YFFinancialsAdvancedAPI.swift:20`
- **메서드**: `fetchQuarterlyFinancials(ticker:) -> YFQuarterlyFinancials`
- **설명**: 분기별 상세 재무제표 데이터 조회

## 🔗 yfinance 참조

- **파일**: `yfinance-reference/yfinance/ticker.py:229`
- **프로퍼티**: `quarterly_financials`, `quarterly_income_stmt`, `quarterly_balance_sheet`
- **내부 호출**: `get_income_stmt(freq='quarterly')`, `get_balance_sheet(freq='quarterly')`
- **API 엔드포인트**: `fundamentals-timeseries/v1/finance/timeseries/{symbol}` (line 127 in fundamentals.py)
- **데이터 구조**: pandas DataFrame with quarterly columns

## 🔴 Red Phase: 테스트 작성

### 테스트 케이스
- [ ] `testFetchQuarterlyFinancialsValidSymbol()` - AAPL 분기 재무제표 테스트
- [ ] `testQuarterlyFinancialsDataStructure()` - 분기별 컬럼 구조 검증
- [ ] `testQuarterlyVsYearlyFinancials()` - 연간/분기 데이터 차이 테스트
- [ ] `testQuarterlyFinancialsTimeSeries()` - 시계열 데이터 형식 검증

### 테스트 요구사항
- **Swift Testing 프레임워크** 사용 (`@Test`, `#expect`)
- **실제 API 데이터** 활용 (Mock 사용 금지)
- **에러 케이스 테스트** 포함 (`#expect(throws:)`)

## 🟢 Green Phase: 최소 구현

### 구현 단계
- [ ] YFQuarterlyFinancials 모델 설계 (quarterly columns)
- [ ] fundamentals-timeseries API 연동 (`freq='quarterly'`)
- [ ] 기본 분기 데이터 파싱
- [ ] 기존 YFFinancials와 차이점 정의

### 기술 요구사항
- **기존 패턴 활용**: YFClient 확장, YFSession 활용
- **에러 처리**: 적절한 YFError 타입 사용
- **타입 안전성**: Swift 6.1 기능 활용

## 🟡 Refactor Phase: 코드 정리

### 최적화 작업
- [ ] 시계열 데이터 처리 최적화 (`time_series` 구조)
- [ ] 중복 로직 제거 (yearly와 공통 부분)
- [ ] 캐싱 전략 구현
- [ ] 파일 크기 관리 (필요시 분리)

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

**이전 작업**: [03. 옵션 만기일 목록 조회](03-options-expiration-dates.md)  
**다음 작업**: [05. 재무 비율 계산](05-financial-ratios.md)