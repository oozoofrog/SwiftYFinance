# 08. 산업 비교 분석

## 📋 작업 개요

- **파일**: `Sources/SwiftYFinance/Core/YFFinancialsAdvancedAPI.swift:56`
- **메서드**: `compareToIndustry(ticker:) -> YFIndustryComparison`
- **설명**: 동일 산업 내 다른 기업들과의 비교 분석

## 🔗 yfinance 참조

- **파일**: `yfinance-reference/yfinance/base.py:391` (growth_estimates)
- **데이터 구조**: Columns: stock, industry, sector, index (line 394)
- **산업 데이터**: `industry` 컬럼에서 산업 평균 제공
- **비교 기준**: stock vs industry vs sector vs index
- **활용 패턴**: 성장 추정치에서 산업/섹터 비교 데이터 추출

## 🔴 Red Phase: 테스트 작성

### 테스트 케이스
- [ ] `testCompareToIndustryValidSymbol()` - AAPL 산업 비교 분석 테스트
- [ ] `testIndustryComparisonStructure()` - stock/industry/sector 구조 테스트
- [ ] `testIndustryClassificationLogic()` - 산업 분류 체계 테스트
- [ ] `testIndustryBenchmarking()` - 벤치마킹 지표 계산 테스트

### 테스트 요구사항
- **Swift Testing 프레임워크** 사용 (`@Test`, `#expect`)
- **실제 API 데이터** 활용 (Mock 사용 금지)
- **에러 케이스 테스트** 포함 (`#expect(throws:)`)

## 🟢 Green Phase: 최소 구현

### 구현 단계
- [ ] YFIndustryComparison 모델 설계 (stock vs industry vs sector)
- [ ] 기본 산업 분류 체계 (growth_estimates 기반)
- [ ] 기본 벤치마킹 계산

### 기술 요구사항
- **기존 패턴 활용**: YFClient 확장, YFSession 활용
- **에러 처리**: 적절한 YFError 타입 사용
- **타입 안전성**: Swift 6.1 기능 활용

## 🟡 Refactor Phase: 코드 정리

### 산업 비교 지표 최적화
- [ ] **산업 평균 P/E** (industry 컬럼 데이터 활용)
- [ ] **산업 평균 성장률** (growth_estimates industry 값)
- [ ] **섹터 비교 분석** (sector 컬럼 데이터)

### 품질 개선
- [ ] 동일 산업 기업 식별 로직 개선
- [ ] 비교 결과 데이터 구조 최적화 (상대적 위치 표시)
- [ ] 성능 및 정확도 개선
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

**이전 작업**: [07. 재무 건전성 평가](07-financial-health.md)  
**프로젝트 완료**: 모든 TODO 작업 완성!