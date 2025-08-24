# SwiftYFinance CLI 확장 계획

## 목표
새로 구현된 서비스들(QuoteSummary, Domain, Custom Screener)을 CLI에 추가하여 라이브러리의 모든 기능을 명령줄에서 사용할 수 있도록 함

## 현재 상태
### 구현된 CLI 명령어 (11개) ✅
- [x] quote - 실시간 시세 조회
- [x] quotesummary - 종합 기업 정보 (60개 모듈, 15개 편의 메서드) **NEW**
- [x] history - 과거 데이터 조회  
- [x] search - 회사 검색
- [x] fundamentals - 기업 펀더멘털 데이터
- [x] news - 뉴스 조회
- [x] options - 옵션 체인 **FIXED**
- [x] screening - 종목 스크리닝
- [x] domain - 섹터/산업/마켓 도메인 데이터 ✅ **NEW**
- [x] custom-screening - 맞춤형 종목 스크리닝 ✅ **NEW**
- [x] websocket - 실시간 WebSocket 스트리밍 ✅ **NEW**

### 구현 완료 서비스 (10개) ✅
- [x] quote - 실시간 시세 조회
- [x] quotesummary - 종합 기업 정보 (60개 모듈, 15개 편의 메서드)
- [x] history - 과거 데이터 조회  
- [x] search - 회사 검색
- [x] fundamentals - 기업 펀더멘털 데이터
- [x] news - 뉴스 조회
- [x] options - 옵션 체인
- [x] screening - 종목 스크리닝
- [x] domain - 섹터/산업/마켓 도메인 데이터 ✅ **NEW**
- [x] customScreener - 맞춤형 종목 스크리닝 ✅ **NEW**

### 라이브러리 커버리지
✅ **100% 완료**: 10/10개 서비스 구현, 11/11개 CLI 명령어 구현 완료 (WebSocket 추가)

## 구현 계획

### Phase 1: QuoteSummary 명령어 추가 ✅
- [x] `quotesummary` 명령어 구조 설계
- [x] QuoteSummary 서브커맨드 구현 (`essential`, `comprehensive`, `company`, `price`, `financials`, `earnings`, `ownership`, `analyst`)
- [x] JSON 출력 지원
- [x] 에러 처리 및 도움말
- [x] 테스트 및 검증

### Phase 1.5: 누락 서비스 구현 ✅
- [x] **Domain Service 구현**
  - [x] YFDomainService 생성 (Protocol + Struct 패턴)
  - [x] 섹터/산업/마켓 데이터 조회 메서드 구현
  - [x] Raw JSON 및 파싱된 응답 메서드 제공
  - [x] YFDomainResponse 모델 구현 (CodableValue enum 활용)
- [x] **Custom Screener Service 구현**
  - [x] YFCustomScreenerService 생성 (Protocol + Struct 패턴)
  - [x] 맞춤형 스크리닝 필터 시스템 구현 (시가총액, P/E, 수익률, 복합조건)
  - [x] Raw JSON 및 파싱된 응답 메서드 제공
  - [x] YFCustomScreenerResponse 모델 구현
  - [x] YFScreenerCondition 편의 클래스 구현
- [x] **YFClient 확장**
  - [x] domain 서비스 프로퍼티 추가
  - [x] customScreener 서비스 프로퍼티 추가

### Phase 1.6: 누락 CLI 명령어 구현 ✅
- [x] **Domain Command 구현**
  - [x] DomainCommand 생성
  - [x] 섹터/산업/마켓 타입별 서브커맨드
  - [x] JSON 출력 및 에러 처리 지원
  - [x] SwiftYFinanceCLI에 추가
- [x] **Custom Screener Command 구현**
  - [x] CustomScreenerCommand 생성
  - [x] 다양한 필터 옵션 지원 (시가총액, P/E 비율 등)
  - [x] 복합 필터 및 범위 지정 기능
  - [x] JSON 출력 및 에러 처리 지원
  - [x] SwiftYFinanceCLI에 추가

### Phase 2: CLI 개선 및 최적화
- [ ] 명령어별 성능 최적화
- [ ] 에러 메시지 개선
- [ ] 출력 포맷 통일성 향상
- [ ] 추가 옵션 및 필터 지원

### Phase 3: 문서화 및 사용성 개선
- [x] CLI README.md 전체 업데이트 (8개 명령어)
- [ ] Domain/Custom Screener 명령어 문서 추가 (10개 명령어 완료 필요)
- [ ] 각 명령어별 상세 사용 예제 작성
- [ ] 도움말 시스템 개선
- [ ] 사용자 가이드 작성

### Phase 4: 품질 보증 및 배포 준비
- [ ] 전체 명령어 통합 테스트 (10개 명령어)
- [ ] Domain/Custom Screener 서비스 단위 테스트
- [ ] 릴리스 빌드 검증
- [ ] 성능 벤치마크
- [ ] 배포 문서 준비

## 세부 구현 테스트 목록

### QuoteSummary 명령어 테스트
- [ ] `swift run swiftyfinance quotesummary AAPL --type essential` 실행 테스트
- [ ] `swift run swiftyfinance quotesummary AAPL --type comprehensive` 실행 테스트  
- [ ] `swift run swiftyfinance quotesummary AAPL --type company` 실행 테스트
- [ ] `swift run swiftyfinance quotesummary AAPL --type price` 실행 테스트
- [ ] `swift run swiftyfinance quotesummary AAPL --type financials --quarterly` 실행 테스트
- [ ] `swift run swiftyfinance quotesummary AAPL --json` JSON 출력 테스트
- [ ] 잘못된 티커 심볼 에러 처리 테스트
- [ ] 도움말 출력 테스트 (`--help`)

### Domain 명령어 테스트
- [ ] `swift run swiftyfinance domain --type sector` 실행 테스트
- [ ] `swift run swiftyfinance domain --type industry` 실행 테스트
- [ ] `swift run swiftyfinance domain --type market` 실행 테스트
- [ ] `swift run swiftyfinance domain --json` JSON 출력 테스트
- [ ] 도움말 출력 테스트

### Custom Screener 명령어 테스트
- [ ] `swift run swiftyfinance custom-screening --market-cap "1B:10B"` 실행 테스트
- [ ] `swift run swiftyfinance custom-screening --pe-ratio "10:20"` 실행 테스트
- [ ] `swift run swiftyfinance custom-screening --json` JSON 출력 테스트
- [ ] 복합 필터 테스트
- [ ] 도움말 출력 테스트

### 통합 테스트
- [ ] 전체 명령어 빌드 테스트
- [ ] 모든 명령어 `--help` 출력 테스트
- [ ] 전체 CLI README.md 업데이트 검증
- [ ] 릴리즈 빌드 테스트

## 우선순위
1. ✅ **QuoteSummary 명령어** - 가장 자주 사용될 것으로 예상되는 종합 정보 조회 완료
2. ✅ **Domain Service** - 시장 분석에 유용한 섹터/산업 데이터 서비스 완료
3. ✅ **Custom Screener Service** - 고급 사용자를 위한 맞춤형 스크리닝 서비스 완료
4. ✅ **Domain + Custom Screener CLI 명령어** - 모든 10개 명령어 구현 완료

## 성공 기준
- ✅ 기존 8개 명령어 일관된 인터페이스 제공
- ✅ 모든 10개 서비스 구현 완료 (Protocol + Struct 패턴)
- ✅ 모든 10개 CLI 명령어에서 JSON 출력 옵션 동작
- ✅ 사용자 친화적 에러 처리
- 🔄 CLI README.md에 모든 10개 명령어 문서화 완료 (대기중)
- ✅ 전체 빌드 및 기본 기능 테스트 통과 (10개 명령어)