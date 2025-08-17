# 05. 재무 비율 계산

## 📋 작업 개요

- **파일**: `Sources/SwiftYFinance/Core/YFFinancialsAdvancedAPI.swift:29`
- **메서드**: `calculateFinancialRatios(ticker:) -> YFFinancialRatios`
- **설명**: P/E, P/B, ROE 등 주요 재무 비율 계산

## 🔗 yfinance 참조

- **파일**: 기존 재무 데이터를 활용한 계산 (직접 API 없음)
- **데이터 소스**: `get_income_stmt()`, `get_balance_sheet()`, `get_quote()`
- **계산 베이스**: 손익계산서 + 대차대조표 + 현재가격 조합
- **참조 패턴**: pandas DataFrame 기반 비율 계산

## 🔴 Red Phase: 테스트 작성

### 테스트 케이스
- [ ] `testCalculateFinancialRatiosValidSymbol()` - AAPL 재무 비율 계산 테스트
- [ ] `testFinancialRatiosCalculations()` - 개별 비율 계산 정확성 테스트
- [ ] `testFinancialRatiosZeroDivision()` - 0으로 나누기 에러 처리 테스트
- [ ] `testFinancialRatiosDataIntegration()` - 기존 데이터 통합 테스트

### 테스트 요구사항
- **Swift Testing 프레임워크** 사용 (`@Test`, `#expect`)
- **실제 API 데이터** 활용 (Mock 사용 금지)
- **에러 케이스 테스트** 포함 (`#expect(throws:)`)

## 🟢 Green Phase: 최소 구현

### 구현 단계
- [ ] YFFinancialRatios 모델 설계 (P/E, P/B, ROE, ROA 등)
- [ ] 기존 YFClient 메서드 조합 (fetchFinancials + fetchQuote)
- [ ] 기본 비율 계산 로직
- [ ] nil/zero 분모 안전 처리

### 기술 요구사항
- **기존 패턴 활용**: YFClient 확장, YFSession 활용
- **에러 처리**: 적절한 YFError 타입 사용
- **타입 안전성**: Swift 6.1 기능 활용

## 🟡 Refactor Phase: 코드 정리

### 재무 비율 계산 공식 최적화
- [ ] **P/E Ratio** (regularMarketPrice / EPS)
- [ ] **P/B Ratio** (marketCap / totalStockholderEquity)
- [ ] **ROE** (netIncome / totalStockholderEquity)
- [ ] **ROA** (netIncome / totalAssets)
- [ ] **Debt-to-Equity Ratio** (totalDebt / totalStockholderEquity)
- [ ] **Current Ratio** (currentAssets / currentLiabilities)

### 품질 개선
- [ ] 계산 로직 단순화 및 성능 개선
- [ ] 에러 처리 강화
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

**이전 작업**: [04. 분기별 재무제표 조회](04-quarterly-financials.md)  
**다음 작업**: [06. 성장 지표 계산](06-growth-metrics.md)