# SwiftYFinance 파일 분리 및 최적화 계획

## 🎯 목표
300줄 이상의 대용량 Swift 파일들을 기능별로 분리하여 코드 가독성, 유지보수성, 재사용성을 향상시킵니다.

## 📊 현재 상황
- **11개 파일**이 300줄 초과 (최대 959줄)
- **4개 파일**이 즉시 분리 필요 (500줄 초과)
- 총 **5,821줄**을 체계적으로 재구성 필요

## 🚀 Phase 1: 최우선 분리 (YFQuote.swift - 959줄)

### 1.1 Quote 모델 분리 전략
**목표**: 15개 구조체를 6개 파일로 분리

```
Network/Quote/
├── YFQuoteResponse.swift       # API 응답 래퍼들
├── YFQuoteBasicInfo.swift      # 기본 종목 정보  
├── YFQuoteMarketData.swift     # 시세 데이터
├── YFQuoteSummaryDetail.swift  # 상세 분석 정보
├── YFQuoteExtensions.swift     # 편의 기능들
└── YFQuote.swift               # 메인 구조체 (통합)
```

### 1.2 분리 기준
- **API 응답**: YFQuoteSummaryResponse, YFQuoteResponse 등
- **기본 정보**: YFQuoteBasicInfo, YFQuoteExchangeInfo  
- **시장 데이터**: YFQuoteMarketData, YFQuoteVolumeInfo
- **상세 정보**: YFQuoteSummaryDetail (600줄 → 별도 파일)
- **확장 기능**: 계산된 프로퍼티 및 유틸리티

## 🔧 Phase 2: 기술 지표 확장 분리 (YFClient+TechnicalIndicators.swift - 796줄)

### 2.1 기능별 확장 분리
```
Utils/TechnicalIndicators/
├── YFClient+MovingAverages.swift    # SMA, EMA 이동평균
├── YFClient+Oscillators.swift       # RSI, Stochastic 오실레이터  
├── YFClient+TrendIndicators.swift   # MACD, ADX 추세 지표
├── YFClient+VolumeIndicators.swift  # Volume-based 지표들
├── YFClient+BollingerBands.swift   # 볼린저 밴드 전용
└── YFClient+SignalAnalysis.swift   # 종합 신호 분석
```

### 2.2 분리 혜택
- **지표별 독립성**: 필요한 지표만 import 가능
- **확장성**: 새 지표 추가 시 별도 파일로 관리
- **테스트 용이성**: 지표별 단위 테스트 작성

## 💼 Phase 3: 재무 모델 최적화 (YFFinancialsAdvanced.swift - 706줄)

### 3.1 재무 지표 카테고리 분리
```
Business/Financials/
├── YFFinancialsCore.swift          # 핵심 재무 지표
├── YFFinancialsRatios.swift        # 재무 비율들
├── YFFinancialsGrowth.swift        # 성장률 지표  
├── YFFinancialsValuation.swift     # 밸류에이션 지표
└── YFFinancialsAdvanced.swift      # 통합 구조체 (축소)
```

### 3.2 기능별 분류
- **핵심 지표**: 매출, 이익, 자산, 부채 기본 데이터
- **재무 비율**: ROE, ROA, 부채비율, 유동비율
- **성장 지표**: YoY 성장률, CAGR, 성장 추세
- **밸류에이션**: PER, PBR, EV/EBITDA, FCF

## 🏦 Phase 4: 대차대조표 구조 개선 (YFBalanceSheet.swift - 688줄)

### 4.1 재무제표 구조별 분리  
```
Business/BalanceSheet/
├── YFBalanceSheetAssets.swift      # 자산 항목들
├── YFBalanceSheetLiabilities.swift # 부채 항목들  
├── YFBalanceSheetEquity.swift      # 자본 항목들
└── YFBalanceSheet.swift            # 통합 구조체
```

### 4.2 회계 원칙 반영
- **자산 = 부채 + 자본** 구조 명확화
- **유동/비유동 분류** 체계화
- **계정과목별 그룹핑** 일관성

## 🔍 Phase 5: 중간 우선순위 파일들 검토

### 5.1 WebSocket 클라이언트 (512줄)
- **현재 평가**: 기능 응집도 높음, 당장 분리 불필요
- **향후 계획**: 600줄 초과 시 연결/파싱/상태관리 분리

### 5.2 세션 인증 (485줄)  
- **현재 평가**: 보안 로직 응집도 높음, 유지
- **향후 계획**: 기능 추가 시에만 분리 고려

## 📐 분리 표준 및 원칙

### 파일 크기 기준
- **🟢 양호**: 250줄 이하
- **🟡 주의**: 250-300줄 (검토 필요)  
- **🔴 분리**: 300줄 초과 (즉시 분리)

### 분리 원칙
1. **단일 책임**: 각 파일이 하나의 명확한 목적
2. **높은 응집도**: 관련 기능들의 물리적 근접성
3. **낮은 결합도**: 파일 간 의존성 최소화
4. **논리적 구조**: 직관적이고 예측 가능한 구성

### 명명 규칙
- **기본형**: `YF{Domain}{Purpose}.swift`
- **확장형**: `YFClient+{Feature}.swift`  
- **세부형**: `YF{Domain}{Category}.swift`

## 📅 실행 일정

### Week 1: Foundation (Phase 1-2)
- **Day 1-2**: YFQuote.swift 분리 (최우선)
- **Day 3-4**: YFClient+TechnicalIndicators.swift 분리
- **Day 5**: 테스트 실행 및 검증

### Week 2: Business Logic (Phase 3-4) 
- **Day 1-2**: YFFinancialsAdvanced.swift 분리
- **Day 3-4**: YFBalanceSheet.swift 분리  
- **Day 5**: 통합 테스트 및 문서 업데이트

### Week 3: Polish & Optimize
- **Day 1-2**: 추가 최적화 및 리팩토링
- **Day 3-4**: 성능 테스트 및 검증
- **Day 5**: 문서화 완료 및 배포 준비

## 🎯 예상 효과

### 개발 생산성
- **파일 탐색 시간** 50% 단축
- **코드 이해도** 향상  
- **버그 수정 속도** 개선

### 코드 품질
- **유지보수성** 대폭 향상
- **테스트 커버리지** 향상
- **코드 재사용성** 증대

### 팀 협업
- **충돌 최소화**: 작은 파일 단위 작업
- **리뷰 효율성**: 집중적인 코드 리뷰
- **지식 공유**: 명확한 구조로 이해도 증진

## 🔄 지속적 관리

### 모니터링
- **주간 점검**: 300줄 초과 파일 체크
- **월간 리뷰**: 구조 최적화 기회 평가
- **분기별 평가**: 전체 아키텍처 점검

### 예방책
- **개발 가이드라인**: 파일 크기 제한 명시
- **CI/CD 체크**: 자동화된 파일 크기 검증
- **코드 리뷰**: 분리 기준 준수 확인

이 계획을 통해 SwiftYFinance는 더욱 유지보수하기 쉽고 확장 가능한 구조로 발전할 것입니다!