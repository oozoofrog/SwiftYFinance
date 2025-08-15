# SwiftYFinance 용어 가이드

## 표준 용어 정의

SwiftYFinance 프로젝트에서 일관된 용어 사용을 위한 표준화 가이드입니다.

### 1. 금융 상품 식별자

#### Ticker vs Symbol
- **`ticker`** (권장): Swift 코드에서 `YFTicker` 타입의 인스턴스를 지칭할 때 사용
- **`symbol`** (제한적): 문자열 형태의 원시 심볼값을 지칭할 때만 사용

**올바른 사용 예시:**
```swift
let ticker = try YFTicker(symbol: "AAPL")  // ✅ symbol은 문자열 파라미터명
let quote = try await client.fetchQuote(ticker: ticker)  // ✅ ticker는 YFTicker 인스턴스
```

**피할 사용 예시:**
```swift
let symbol = try YFTicker(symbol: "AAPL")  // ❌ 변수명으로 symbol 사용 지양
let quote = try await client.fetchQuote(symbol: symbol)  // ❌ 타입 혼동
```

### 2. 시간 관련 용어

#### Period vs Range vs Duration
- **`period`**: 데이터 조회 기간을 나타내는 열거형 (`.oneYear`, `.oneMonth` 등)
- **`range`**: 시작-종료 날짜 범위를 나타낼 때
- **`duration`**: 시간의 길이나 경과 시간을 나타낼 때

### 3. 가격 관련 용어

#### Price vs Quote vs Rate
- **`price`**: 단순한 숫자값 가격 (예: `regularMarketPrice`)
- **`quote`**: 가격과 부가 정보를 포함한 시세 데이터 (예: `YFQuote`)
- **`rate`**: 비율이나 수익률 (예: `interestRate`, `returnRate`)

### 4. 데이터 관련 용어

#### History vs Historical vs Past
- **`history`**: 과거 데이터 전체를 지칭할 때 사용 (권장)
- **`historical`**: 형용사로만 사용 ("historical data")
- **`past`**: 일반적인 맥락에서만 사용

### 5. API 관련 용어

#### Fetch vs Get vs Retrieve
- **`fetch`**: API 호출을 통한 데이터 조회에 사용 (권장)
- **`get`**: 속성 접근자나 간단한 값 반환에 사용
- **`retrieve`**: 캐시나 저장소에서 데이터를 가져올 때 사용

### 6. 에러 관련 용어

#### Error vs Exception vs Failure
- **`error`**: Swift의 `Error` 프로토콜을 따르는 에러 타입
- **`exception`**: 사용 금지 (Java/Python 용어)
- **`failure`**: 동작의 실패 상태를 나타낼 때 사용

### 7. 설정 관련 용어

#### Configuration vs Settings vs Options
- **`configuration`**: 시스템 전체 설정
- **`settings`**: 사용자 정의 설정
- **`options`**: 메서드나 함수의 선택적 매개변수

## 문서화 스타일 가이드

### 1. 문체
- **단정적 톤**: "데이터를 조회합니다" (권장)
- **설명적 톤**: "데이터를 조회할 수 있습니다" (제한적 사용)

### 2. 코드 예시
- 항상 실행 가능한 완전한 예시 제공
- `async/await` 패턴 일관성 있게 사용
- 에러 처리 포함 권장

### 3. 매개변수 문서화
```swift
/// 주식 시세를 조회합니다
/// 
/// - Parameter ticker: 조회할 주식의 ticker 객체
/// - Returns: 실시간 주식 시세 데이터
/// - Throws: `YFError.invalidTicker` 유효하지 않은 ticker인 경우
```

### 4. 반환값 설명
- 구체적인 타입과 내용 명시
- 실패 조건과 예외 상황 포함
- 빈 결과의 의미 설명

## 번역 및 현지화

### 1. 한글 사용 원칙
- 기술 용어는 영어 유지 (ticker, API, JSON 등)
- 일반 설명은 자연스러운 한국어 사용
- 금융 전문 용어는 표준 번역어 사용

### 2. 코드 내 주석
- 한글 주석 권장
- 영어 약어 설명 시 한글 병기

### 3. 예시 데이터
- 미국 주식: AAPL, MSFT, GOOGL (실제 데이터)
- 한국 주식: 예시 목적으로만 사용
- 가상 데이터 사용 시 명확히 표기

## 일관성 체크리스트

### 문서 작성 시 확인사항
- [ ] ticker/symbol 용어 일관성
- [ ] fetch 동사 사용 일관성
- [ ] 에러 처리 패턴 일관성
- [ ] 코드 예시 실행 가능성
- [ ] 매개변수 설명 완전성
- [ ] 반환값 설명 구체성

### 코드 리뷰 시 확인사항
- [ ] 네이밍 컨벤션 준수
- [ ] 문서화 주석 완성도
- [ ] 예시 코드 정확성
- [ ] 용어 사용 일관성
- [ ] 한글 번역 자연스러움

---

이 가이드는 SwiftYFinance 프로젝트의 품질과 일관성을 보장하기 위해 모든 기여자가 준수해야 하는 표준입니다.