# 테스트 파일 분리 규칙 및 원칙

## 🎯 분리 기준 (언제 분리할 것인가)

### 크기 기준
- **250줄 초과**: 분리 검토 시작
- **300줄 초과**: 강제 분리 실행
- **15개 테스트 메서드 초과**: 분리 검토
- **20개 테스트 메서드 초과**: 강제 분리

### 기능 기준
- 서로 다른 도메인 테스트가 섞여있을 때
- 테스트 setup이 달라질 때  
- 독립적으로 실행 가능한 테스트 그룹이 있을 때

## 📁 분리 구조

### 디렉토리 구조
```
Tests/SwiftYFinanceTests/
├── Parser/                    # JSON 파싱 관련
│   ├── BasicParsingTests.swift       # 기본 JSON 파싱
│   ├── TimestampParsingTests.swift   # 타임스탬프 변환
│   ├── OHLCVParsingTests.swift      # OHLCV 데이터 추출
│   └── ErrorParsingTests.swift      # 에러 응답 처리
├── Network/                   # 네트워크 관련
│   ├── SessionTests.swift           # YFSession
│   └── RequestBuilderTests.swift   # YFRequestBuilder
├── Client/                    # API 클라이언트
│   ├── PriceHistoryTests.swift     # 가격 이력
│   ├── QuoteDataTests.swift        # 실시간 시세
│   └── FinancialDataTests.swift    # 재무 데이터
├── Models/                    # 데이터 모델
│   ├── TickerTests.swift
│   ├── PriceTests.swift
│   └── HistoricalDataTests.swift
└── Integration/               # 통합 테스트
    ├── RealAPITests.swift         # 실제 API 호출
    └── EndToEndTests.swift       # E2E 테스트
```

### 네이밍 컨벤션
- **패턴**: `{Feature}Tests.swift` 
- **예시**: `TimestampParsingTests.swift`, `PriceHistoryTests.swift`
- **폴더명**: 도메인별 명사형 (Parser, Network, Client, Models)

## 🔄 분리 방식

### 테스트 메서드 그룹화 기준
1. **기능적 응집성**: 관련된 기능 테스트끼리 그룹화
2. **독립성**: 각 파일이 독립적으로 실행 가능
3. **단일 책임**: 각 파일이 하나의 명확한 책임을 가짐

### 분리 단위
- ✅ **권장**: 테스트 메서드 그룹 단위 (의미있는 단위)
- ❌ **비권장**: 라인 수 기준 기계적 분리

## 📋 분리 체크리스트

### Phase 1: 현재 파일 분석
- [ ] 각 테스트 파일의 라인 수 확인
- [ ] 테스트 메서드 개수 확인  
- [ ] 테스트 도메인별 그룹화 가능 여부 확인

### Phase 2: 분리 계획 수립
- [ ] 분리 대상 파일 우선순위 결정
- [ ] 각 파일별 분리 방식 결정
- [ ] 새로운 폴더 구조 설계

### Phase 3: 분리 실행
- [ ] 새 디렉토리 구조 생성
- [ ] 테스트 파일 분리 및 이동
- [ ] import 구문 및 의존성 확인
- [ ] 모든 테스트 실행하여 정상 동작 확인

### Phase 4: 검증 및 정리
- [ ] 분리된 테스트 파일들 개별 실행 테스트
- [ ] 전체 테스트 스위트 실행 확인
- [ ] 불필요한 파일 정리
- [ ] git commit으로 변경사항 기록

## 🎯 우선순위 분리 대상

### 현재 상태 (2025-08-13)
```
파일명                          라인수    상태
YFResponseParserTests.swift     532줄    🚨 즉시 분리 필요
YFClientTests.swift             335줄    🔶 분리 검토 필요  
YFRequestBuilderTests.swift     268줄    🔶 분리 검토 필요
YFSessionTests.swift            212줄    ✅ 현재 적정
```

### 분리 순서
1. **1순위**: YFResponseParserTests.swift → Parser/ 폴더로 분리
2. **2순위**: YFClientTests.swift → Client/ 폴더로 분리  
3. **3순위**: YFRequestBuilderTests.swift → Network/ 폴더로 분리

## 📝 분리 후 관리 원칙

### 지속적인 모니터링
- 새로운 테스트 추가 시 적절한 파일 배치
- 정기적인 파일 크기 점검 (250줄 기준)
- 테스트 실행 시간 모니터링

### 리팩토링 가이드라인
- 테스트 분리는 구조적 변경이므로 Tidy First 원칙 적용
- 분리 작업은 독립된 커밋으로 관리
- 기능 변경과 분리 작업을 혼재하지 않음