# SwiftYFinance

Python yfinance 라이브러리를 Swift로 포팅한 종합 금융 데이터 라이브러리

## 프로젝트 현황

### 완료된 개발 (Phase 1-5, 7)

#### Phase 1: 기본 구조 설계
- Swift Package Manager 프로젝트 구조
- 기본 모델 (YFTicker, YFPrice, YFError)
- Swift Testing 프레임워크 도입
- DocC 기반 문서 시스템

#### Phase 2: 네트워크 레이어
- YFSession (URLSession 기반)
- YFRequestBuilder (API 요청 생성)
- YFResponseParser (JSON/HTML 파싱)
- 네트워크 에러 처리

#### Phase 3: 데이터 모델 완성
- YFHistoricalData (과거 가격 데이터)
- YFQuote (실시간 시세)
- YFFinancials (재무제표: 손익계산서, 대차대조표, 현금흐름표)
- Codable 프로토콜 완전 지원

#### Phase 4: API 통합 & 인증
- Yahoo Finance API 연동
- Chrome 136 브라우저 모방 (curl_cffi 포팅)
- CSRF 토큰, 쿠키 관리
- Rate limiting 및 재시도 로직

#### Phase 5: 고급 기능
- 옵션 거래 (YFOptions, Greeks 계산)
- 기술적 분석 (SMA, EMA, RSI, MACD, 볼린저밴드)
- 뉴스 & 감성분석
- 종목 스크리닝 (Fluent API)

#### Phase 7: 문서화 품질 표준화
- DocC 문서화 100% 완성
- 용어 통일성 확립
- 개발 원칙 문서화
- **144개 테스트** (96.5% 성공률)

### 진행 중
- **Phase 6**: 회사명 검색 기능 개발

## 주요 기능

### 기본 데이터
- 과거 가격 데이터 (모든 간격 지원)
- 실시간 시세 (장중/장후 거래)
- 재무제표 (손익계산서, 대차대조표, 현금흐름표)

### 고급 기능  
- 옵션 거래 (옵션 체인, Greeks)
- 기술적 분석 (SMA, EMA, RSI, MACD, 볼린저밴드)
- 뉴스 & 감성분석
- 종목 스크리닝

### 추가 예정 (Phase 6)
- 회사명 검색 (Yahoo Finance Search API)
- 검색 자동완성
- 고급 필터링

## 문서 구조

### 개발 문서
- **[개발 원칙](docs/development-principles.md)**
- **[Phase 6 체크리스트](docs/plans/company-search-checklist.md)** ← 진행 상황
- **[Phase 6 검색 기능 개요](docs/plans/company-search-overview.md)**
- **[Phase 6 구현 상세](docs/plans/company-search-implementation.md)**
- **[Phase 6 테스트 계획](docs/plans/company-search-tests.md)**

### 참조 문서
- **[용어 통일성 가이드](docs/docc/terminology-guide.md)**
- **[문서 업데이트 가이드](docs/docc/documentation-update-process.md)**
- **[DocC 문서화](docs/docc/docc-documentation.md)**

---

**현재 상태**: 핵심 기능 완료 + Phase 6 개발 중  
**다음 단계**: Phase 6 완료 → 프로덕션 준비