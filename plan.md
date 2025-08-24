# SwiftYFinance CLI 확장 계획

## 목표
새로 구현된 서비스들(QuoteSummary, Domain, Custom Screener)을 CLI에 추가하여 라이브러리의 모든 기능을 명령줄에서 사용할 수 있도록 함

## 현재 상태
### 구현된 CLI 명령어 (5개)
- [x] quote - 실시간 시세 조회
- [x] history - 과거 데이터 조회  
- [x] search - 회사 검색
- [x] fundamentals - 기업 펀더멘털 데이터
- [x] screening - 종목 스크리닝

### 구현된 라이브러리 서비스 (미CLI화)
- [ ] QuoteSummary - 종합 기업 정보 (60개 모듈, 15개 편의 메서드)
- [ ] Domain - 섹터/산업/시장 데이터
- [ ] Custom Screener - 사용자 정의 스크리닝

## 구현 계획

### Phase 1: QuoteSummary 명령어 추가
- [ ] `quotesummary` 명령어 구조 설계
- [ ] QuoteSummary 서브커맨드 구현 (`essential`, `comprehensive`, `company`, `price`, `financials`)
- [ ] JSON 출력 지원
- [ ] 에러 처리 및 도움말
- [ ] 테스트 및 검증

### Phase 2: Domain 명령어 추가  
- [ ] `domain` 명령어 구조 설계
- [ ] Domain 서브커맨드 구현 (`sector`, `industry`, `market`)
- [ ] JSON 출력 지원
- [ ] 에러 처리 및 도움말
- [ ] 테스트 및 검증

### Phase 3: Custom Screener 명령어 추가
- [ ] `custom-screening` 명령어 구조 설계
- [ ] 사용자 정의 필터 파라미터 지원
- [ ] JSON 출력 지원
- [ ] 에러 처리 및 도움말
- [ ] 테스트 및 검증

### Phase 4: 문서 및 통합
- [ ] CLI README.md 업데이트
- [ ] 도움말 시스템 개선
- [ ] 전체 빌드 및 테스트
- [ ] 사용 예제 작성

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
1. **QuoteSummary 명령어** - 가장 자주 사용될 것으로 예상되는 종합 정보 조회
2. **Domain 명령어** - 시장 분석에 유용한 섹터/산업 데이터
3. **Custom Screener 명령어** - 고급 사용자를 위한 맞춤형 스크리닝

## 성공 기준
- 모든 새 명령어가 기존 명령어와 일관된 인터페이스 제공
- JSON 출력 옵션이 모든 명령어에서 동작
- 에러 처리가 사용자 친화적
- CLI README.md에 모든 새 명령어 문서화 완료
- 빌드 및 기본 기능 테스트 통과