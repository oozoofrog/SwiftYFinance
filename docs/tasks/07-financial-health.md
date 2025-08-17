# 07. 재무 건전성 평가

## 📋 작업 개요

- **파일**: `Sources/SwiftYFinance/Core/YFFinancialsAdvancedAPI.swift:47`
- **메서드**: `assessFinancialHealth(ticker:) -> YFFinancialHealth`
- **설명**: 재무 안정성과 건전성을 종합 평가

## 🔗 yfinance 참조

- **파일**: 직접 API 없음, 기존 재무 데이터 조합 계산
- **데이터 소스**: `get_balance_sheet()`, `get_income_stmt()`, `get_cash_flow()`
- **계산 베이스**: 대차대조표 + 손익계산서 + 현금흐름표 조합
- **패턴**: 재무 비율들의 종합 분석 및 점수화

## 🔴 Red Phase: 테스트 작성

### 테스트 케이스
- [ ] `testAssessFinancialHealthValidSymbol()` - AAPL 재무 건전성 평가 테스트
- [ ] `testFinancialHealthScoring()` - 점수화/등급화 시스템 테스트
- [ ] `testFinancialHealthRatios()` - 개별 건전성 지표 계산 테스트
- [ ] `testFinancialHealthRiskAssessment()` - 위험도 평가 로직 테스트

### 테스트 요구사항
- **Swift Testing 프레임워크** 사용 (`@Test`, `#expect`)
- **실제 API 데이터** 활용 (Mock 사용 금지)
- **에러 케이스 테스트** 포함 (`#expect(throws:)`)

## 🟢 Green Phase: 최소 구현

### 구현 단계
- [ ] YFFinancialHealth 모델 설계 (점수, 등급, 세부 지표)
- [ ] 기본 건전성 평가 알고리즘 (재무 비율 조합)
- [ ] 점수화 시스템 (0-100 또는 A-F 등급)

### 기술 요구사항
- **기존 패턴 활용**: YFClient 확장, YFSession 활용
- **에러 처리**: 적절한 YFError 타입 사용
- **타입 안전성**: Swift 6.1 기능 활용

## 🟡 Refactor Phase: 코드 정리

### 건전성 지표 계산 최적화
- [ ] **Debt-to-Equity 분석** (totalDebt / totalStockholderEquity)
- [ ] **Interest Coverage Ratio** (operatingIncome / interestExpense)
- [ ] **Quick Ratio** ((currentAssets - inventory) / currentLiabilities)
- [ ] **Working Capital 분석** (currentAssets - currentLiabilities)

### 품질 개선
- [ ] 위험도 평가 로직 개선 (복합 지표 기반)
- [ ] 알고리즘 가중치 조정 및 최적화
- [ ] DocC 문서화 완성

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

**이전 작업**: [06. 성장 지표 계산](06-growth-metrics.md)  
**다음 작업**: [08. 산업 비교 분석](08-industry-comparison.md)