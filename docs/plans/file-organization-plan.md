# 파일 조직화 규칙 및 원칙

## 🎯 분리 기준 (언제 분리할 것인가)

### 크기 기준 (모든 파일 공통)
- **250줄 초과**: 분리 검토 시작
- **300줄 초과**: 강제 분리 실행
- **테스트**: 15개 메서드 초과 시 검토, 20개 초과 시 강제 분리
- **소스코드**: 복잡도 15 초과 시 검토, 20 초과 시 분리
- **문서**: 섹션 10개 초과 시 검토, 15개 초과 시 분리

### 기능 기준
- 서로 다른 도메인 로직이 섞여있을 때
- 독립적으로 실행/사용 가능한 기능 그룹이 있을 때
- 의존성 구조가 복잡해질 때

## 📁 파일 분리 작업 계획

### 🎉 주요 소스 파일 분리 완료 (2025-08-13)
```
✅ YFClient.swift (856줄) → 7개 Core 파일
✅ YFFinancials.swift (395줄) → 4개 Models 파일  
✅ YFSession.swift (326줄) → 3개 Core 파일
```

### 다음 분리 후보
```
🔶 검토 중:
├── YFCookieManagerTests.swift (341줄) - 테스트 파일
└── phase4-api-integration.md (12개) - 문서 파일
```

### 네이밍 컨벤션

#### 소스코드
- **패턴**: `YF{Feature}.swift`
- **예시**: `YFClient.swift`, `YFSession.swift`
- **클래스/구조체**: PascalCase
- **함수/변수**: camelCase

#### 테스트 파일
- **패턴**: `{Feature}Tests.swift` 
- **예시**: `SessionTests.swift`, `PriceHistoryTests.swift`

#### 문서 파일
- **패턴**: `{topic}-{subtopic}.md`
- **예시**: `phase1-setup.md`, `error-handling.md`
- **폴더 구조**: 목적별 분류 (plans/, api/, guides/)

## 🔄 분리 방식

### 소스코드 분리 원칙
1. **단일 책임 원칙**: 각 파일이 하나의 명확한 책임
2. **의존성 역전**: 고수준 모듈이 저수준 모듈에 의존하지 않음
3. **프로토콜 지향**: 구체 타입보다 프로토콜 사용

### 테스트 분리 원칙
1. **기능적 응집성**: 관련된 기능 테스트끼리 그룹화
2. **독립성**: 각 파일이 독립적으로 실행 가능
3. **빠른 실행**: 단위 테스트와 통합 테스트 분리

### 문서 분리 원칙
1. **주제별 분류**: 관련 주제별로 파일 분리
2. **깊이 제한**: 최대 3단계 깊이의 섹션 구조
3. **상호 참조**: 관련 문서 간 링크 유지

## 📋 분리 체크리스트

### Phase 1: 현재 상태 분석 ✅ 완료
- [x] 각 소스 파일의 라인 수 확인 ✅ 완료
- [x] 각 소스 파일의 복잡도 측정 ✅ 완료
- [x] 테스트 파일의 메서드 개수 확인 ✅ 완료
- [x] 문서 파일의 섹션 구조 확인 ✅ 완료
- [x] 도메인별 그룹화 가능 여부 확인 ✅ 완료

### Phase 2: 분리 계획 수립 ✅ 완료
- [x] 분리 대상 파일 우선순위 결정 ✅ 완료
- [x] 각 파일별 분리 방식 결정 ✅ 완료
- [x] 새로운 디렉토리 구조 설계 ✅ 완료
- [x] 의존성 관계 다이어그램 작성 ✅ 완료

### Phase 3: 분리 실행 ✅ 완료
- [x] 새 디렉토리 구조 생성 ✅ 완료
- [x] 파일 분리 및 이동 ✅ 완료
- [x] import 구문 및 의존성 확인 ✅ 완료
- [x] 접근 제어자(public/internal/private) 조정 ✅ 완료
- [x] 모든 테스트 실행하여 정상 동작 확인 ✅ 완료

### Phase 4: 검증 및 정리 ✅ 완료
- [x] 빌드 및 테스트 성공 확인 ✅ 완료
- [x] 코드 커버리지 유지 확인 ✅ 완료
- [x] 문서 링크 및 참조 업데이트 ✅ 완료
- [x] 불필요한 파일 정리 ✅ 완료
- [x] git commit으로 변경사항 기록 ✅ 완료

## 📊 분리 완료 현황 (2025-08-13 최종)

### ✅ 완료된 분리 작업

#### 1. YFClient.swift (856줄 → 7개 파일)
```
Core/YFEnums.swift (52줄) - YFPeriod, YFInterval enum
Core/YFClient.swift (157줄) - 메인 클래스 + 초기화  
Core/YFHistoryAPI.swift (252줄) - 가격 이력 API
Core/YFQuoteAPI.swift (137줄) - 실시간 시세 API
Core/YFFinancialsAPI.swift (153줄) - 재무 데이터 API
Core/YFBalanceSheetAPI.swift (149줄) - 대차대조표 API
Core/YFCashFlowAPI.swift (151줄) - 현금흐름 API
Core/YFEarningsAPI.swift (179줄) - 손익계산서 API
Models/YFChartModels.swift (91줄) - Chart 응답 모델
Models/YFQuoteModels.swift (48줄) - Quote 응답 모델
```

#### 2. YFFinancials.swift (395줄 → 4개 파일)
```
Models/YFFinancials.swift (121줄) - 기본 재무제표
Models/YFBalanceSheet.swift (105줄) - 대차대조표
Models/YFCashFlow.swift (120줄) - 현금흐름표  
Models/YFEarnings.swift (179줄) - 손익계산서
```

#### 3. YFSession.swift (326줄 → 3개 파일)
```
Core/YFSession.swift (117줄) - 메인 세션 클래스
Core/YFSessionAuth.swift (189줄) - CSRF 인증
Core/YFSessionCookie.swift (19줄) - User-Agent 로테이션
```

#### 4. YFCookieManagerTests.swift (342줄 → 6개 파일)
```
Core/YFCookieManagerExtractionTests.swift (89줄) - A3 쿠키 추출/필터링
Core/YFCookieManagerValidationTests.swift (88줄) - 쿠키 유효성 검증  
Core/YFCookieManagerCacheTests.swift (65줄) - 메모리 캐시 테스트
Core/YFCookieManagerStorageTests.swift (38줄) - HTTPCookieStorage 연동
Core/YFCookieManagerStatusTests.swift (43줄) - 쿠키 상태 테스트
Core/YFCookieManagerSeparationTests.swift (76줄) - 분리 검증 테스트
```

### 🔍 남은 분리 후보 (300줄+ 기준)  
```
문서 파일: phase4-api-integration.md (12개 섹션)
```

## 📈 분리 성과 요약

### 전체 통계
```
분리된 파일 수: 4개 → 20개 파일
감소된 복잡도: 1,919줄 → 평균 96줄/파일  
TDD 적용: 모든 분리에 Red → Green 사이클 적용
테스트 통과율: 100% (전체 빌드 및 테스트 성공)
```

### 🎯 달성한 목표
- ✅ **유지보수성 향상**: 300줄+ 대형 파일 모두 분리
- ✅ **단일 책임 원칙**: 각 파일이 명확한 단일 책임
- ✅ **TDD 준수**: 모든 분리 작업에 테스트 우선 적용
- ✅ **안전한 리팩토링**: 기능 변경 없이 구조만 개선

## 📝 향후 유지보수 가이드

### 파일 크기 모니터링
- **250줄 초과**: 분리 검토 시작  
- **300줄 초과**: 강제 분리 실행
- **TDD 적용**: 분리 시 반드시 테스트 우선 작성

### 분리 원칙
- **Tidy First**: 구조 변경과 기능 변경 분리
- **단일 책임**: 각 파일이 하나의 명확한 책임
- **독립 커밋**: 분리 작업은 별도 커밋으로 관리