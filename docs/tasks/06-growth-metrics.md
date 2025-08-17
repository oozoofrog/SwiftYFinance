# 06. 성장 지표 계산

## 📋 작업 개요

- **파일**: `Sources/SwiftYFinance/Core/YFFinancialsAdvancedAPI.swift:38`
- **메서드**: `calculateGrowthMetrics(ticker:) -> YFGrowthMetrics`
- **설명**: 매출 성장률, 이익 성장률 등 성장 지표 계산

## 🔗 yfinance 참조

- **파일**: `yfinance-reference/yfinance/base.py:391`
- **메서드**: `get_growth_estimates(as_dict=False)`
- **데이터 구조**: Index: 0q +1q 0y +1y +5y -5y, Columns: stock industry sector index
- **내부 소스**: `self._analysis.growth_estimates`
- **계산 방식**: 기간별 성장률 추정치 (분기/연간)

## 🔴 Red Phase: 테스트 작성

### 테스트 케이스
- [ ] `testCalculateGrowthMetricsValidSymbol()` - AAPL 성장 지표 계산 테스트
- [ ] `testGrowthMetricsTimeframeStructure()` - 0q/+1q/0y/+1y/+5y 구조 테스트
- [ ] `testGrowthRateCalculations()` - 개별 성장률 계산 정확성 테스트
- [ ] `testGrowthMetricsOutlierHandling()` - 이상치 처리 테스트

### 테스트 요구사항
- **Swift Testing 프레임워크** 사용 (`@Test`, `#expect`)
- **실제 API 데이터** 활용 (Mock 사용 금지)
- **에러 케이스 테스트** 포함 (`#expect(throws:)`)

## 🟢 Green Phase: 최소 구현

### 구현 단계
- [ ] YFGrowthMetrics 모델 설계 (0q, +1q, 0y, +1y, +5y 구조)
- [ ] 기본 성장률 계산 알고리즘 (기존 재무 데이터 기반)
- [ ] 시계열 비교 로직 (연도별/분기별)

### 기술 요구사항
- **기존 패턴 활용**: YFClient 확장, YFSession 활용
- **에러 처리**: 적절한 YFError 타입 사용
- **타입 안전성**: Swift 6.1 기능 활용

## 🟡 Refactor Phase: 코드 정리

### 성장률 계산 최적화
- [ ] **Revenue Growth Rate** (연도별/분기별)
- [ ] **Earnings Growth Rate**
- [ ] **EPS Growth Rate**  
- [ ] **Free Cash Flow Growth**

### 품질 개선
- [ ] `_analysis` 패턴 활용 개선
- [ ] 이상치 처리 및 검증 강화
- [ ] 캐싱 및 성능 최적화
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

**이전 작업**: [05. 재무 비율 계산](05-financial-ratios.md)  
**다음 작업**: [07. 재무 건전성 평가](07-financial-health.md)