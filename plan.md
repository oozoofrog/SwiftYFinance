# SwiftYFinance

Python yfinance 라이브러리를 Swift로 포팅한 종합 금융 데이터 라이브러리

## 프로젝트 현황

### 완료된 개발 (Phase 1-7)

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

#### Phase 6: 회사명 검색 기능 ✅
- YFSearchResult, YFSearchQuery 모델
- 기본 검색: `search(companyName:)` 
- 고급 검색: `search(query:)` 
- 자동완성: `searchSuggestions(prefix:)`
- 성능 최적화: 1분 TTL 캐싱 (최대 100개 검색어)
- Rate limiting 및 인증 세션 활용
- **41개 테스트** 모두 통과

#### Phase 7: 문서화 품질 표준화
- DocC 문서화 100% 완성
- 용어 통일성 확립
- 개발 원칙 문서화
- **총 185개 테스트** (100% 성공률)

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
- **회사명 검색** (Yahoo Finance Search API)
- **검색 자동완성** (prefix 기반)
- **성능 최적화 캐싱** (1분 TTL)

## 문서 구조

### 개발 문서
- **[개발 원칙](docs/development-principles.md)**

### 참조 문서
- **[용어 통일성 가이드](docs/docc/terminology-guide.md)**
- **[문서 업데이트 가이드](docs/docc/documentation-update-process.md)**
- **[DocC 문서화](docs/docc/docc-documentation.md)**

---

**현재 상태**: 모든 Phase 완료 (Phase 1-7) ✅  
**다음 단계**: 프로덕션 준비 → 배포 및 유지보수