# 커뮤니티 기여 가이드

SwiftYFinance 프로젝트에 기여하는 방법과 가이드라인입니다.

## 🤝 기여에 오신 것을 환영합니다!

SwiftYFinance는 오픈소스 커뮤니티의 기여를 통해 발전하는 프로젝트입니다. 모든 종류의 기여를 환영하며, 이 가이드가 여러분의 기여를 도와드릴 것입니다.

## 🎯 기여 방법

### 1. 문서화 기여

**쉬운 시작점들**:
- 오타 및 문법 오류 수정
- 설명이 부족한 부분 보완
- 누락된 예시 코드 추가
- 번역 및 현지화

**중급 기여**:
- 새로운 튜토리얼 작성
- API 문서 품질 개선
- FAQ 섹션 확장
- 성능 최적화 가이드 작성

**고급 기여**:
- 전체 문서 아키텍처 개선
- 자동화 도구 개발
- 문서 품질 메트릭 구축

### 2. 코드 기여

**버그 수정**:
- GitHub Issues에서 'good first issue' 라벨 확인
- 재현 가능한 테스트 케이스 작성
- 수정사항과 함께 문서 업데이트

**새 기능 추가**:
- 먼저 Issue나 Discussion에서 논의
- 기능 명세 및 설계 문서 작성
- 테스트 케이스 포함
- 관련 문서 업데이트

**성능 개선**:
- 벤치마크 결과 제공
- 메모리 사용량 분석
- 호환성 영향 평가

## 📋 기여 프로세스

### 1. 준비 단계

```bash
# 1. 프로젝트 포크
git clone https://github.com/your-username/SwiftYFinance.git
cd SwiftYFinance

# 2. 개발 브랜치 생성
git checkout -b feature/your-contribution-name

# 3. 개발 환경 설정
swift package resolve
```

### 2. 개발 단계

**코드 작성 가이드라인**:
- Swift API 디자인 가이드라인 준수
- 기존 코드 스타일 일치
- 충분한 단위 테스트 작성
- 문서화 주석 포함

```swift
/// 새로운 기능을 구현하는 메서드
/// 
/// 이 메서드는 특정 조건에서 데이터를 처리합니다.
/// 
/// - Parameters:
///   - input: 처리할 입력 데이터
///   - options: 처리 옵션 설정
/// - Returns: 처리된 결과 데이터
/// - Throws: `YFError.invalidInput` 입력이 유효하지 않은 경우
/// 
/// ## 사용 예시
/// ```swift
/// let result = try processData(input: data, options: .default)
/// print("처리 결과: \(result)")
/// ```
public func processData(input: Data, options: ProcessingOptions) throws -> ProcessedData {
    // 구현 내용
}
```

### 3. 테스트 단계

```bash
# 단위 테스트 실행
swift test

# 문서 빌드 테스트
swift package generate-documentation

# 코드 스타일 검사 (swiftformat 설치 필요)
swiftformat Sources/ Tests/
```

### 4. 제출 단계

**Pull Request 체크리스트**:
- [ ] 관련 Issue 번호 참조
- [ ] 변경사항 상세 설명
- [ ] 테스트 결과 포함
- [ ] 문서 업데이트 완료
- [ ] 호환성 영향 평가

**PR 템플릿**:
```markdown
## 변경사항 요약
간단하게 변경사항을 설명해주세요.

## 관련 Issue
Fixes #(issue number)

## 변경 유형
- [ ] 버그 수정
- [ ] 새 기능 추가
- [ ] 문서 개선
- [ ] 성능 최적화
- [ ] 코드 리팩터링

## 테스트
어떤 테스트를 수행했는지 설명해주세요.
- [ ] 단위 테스트 통과
- [ ] 통합 테스트 수행
- [ ] 수동 테스트 완료

## 스크린샷/로그
필요시 스크린샷이나 로그를 첨부해주세요.

## 체크리스트
- [ ] 코드가 프로젝트의 스타일 가이드를 따름
- [ ] 자체 리뷰를 완료함
- [ ] 관련 문서를 업데이트함
- [ ] 테스트를 추가/수정함
```

## 🎨 코드 스타일 가이드

### Swift 코딩 규칙

```swift
// ✅ 좋은 예시
class YFDataProcessor {
    private let networkClient: YFClient
    private var processingQueue: DispatchQueue
    
    init(client: YFClient) {
        self.networkClient = client
        self.processingQueue = DispatchQueue(label: "data.processing")
    }
    
    func processTickerData(_ ticker: YFTicker) async throws -> ProcessedData {
        let rawData = try await networkClient.fetchQuote(ticker: ticker)
        return ProcessedData(from: rawData)
    }
}

// ❌ 나쁜 예시
class dataProcessor {
    var client:YFClient
    var queue:DispatchQueue
    
    init(c:YFClient){
        client=c
        queue=DispatchQueue(label:"queue")
    }
    
    func process(_ t:YFTicker)async throws->ProcessedData{
        let d=try await client.fetchQuote(ticker:t)
        return ProcessedData(from:d)
    }
}
```

### 문서화 규칙

**API 문서화**:
- 모든 public 인터페이스는 문서화 필수
- 매개변수와 반환값 설명 포함
- 사용 예시 코드 제공
- 에러 케이스 명시

**주석 스타일**:
```swift
// ✅ 좋은 주석
/// Yahoo Finance API에서 주식 시세를 조회합니다
/// 
/// 이 메서드는 실시간 또는 지연된 시세 데이터를 반환합니다.
/// 시장 시간 외에는 이전 거래일의 종가가 반환됩니다.

// ❌ 불필요한 주석
/// 주식 시세를 가져옴
func fetchQuote() { }

// ❌ 코드 반복하는 주석  
let price = quote.price // price에 quote의 price를 할당
```

## 🐛 버그 리포트 가이드

### 좋은 버그 리포트 작성법

```markdown
## 버그 설명
간결하고 명확한 버그 설명

## 재현 단계
1. '...' 으로 이동
2. '...' 클릭
3. '...' 입력
4. 에러 발생 확인

## 예상 결과
정상적으로 동작해야 하는 내용

## 실제 결과
실제로 발생한 문제

## 환경 정보
- OS: macOS 15.0
- Swift: 6.1
- SwiftYFinance: 1.0.0
- Xcode: 16.0

## 추가 정보
스크린샷, 로그, 또는 기타 관련 정보
```

## 🌟 인정 및 보상

### 기여자 인정

**문서화 기여자**:
- README.md의 Contributors 섹션에 이름 추가
- 분기별 문서 품질 개선상
- 커뮤니티 Discord 채널에서 특별 역할

**코드 기여자**:
- 릴리스 노트에 기여 내용 명시
- GitHub Sponsors를 통한 후원 기회
- 연례 기여자 모임 초대

### 기여 단계별 뱃지

**🥉 Bronze Contributor**:
- 첫 PR 머지 완료
- 문서 오타 수정 5회 이상

**🥈 Silver Contributor**:
- 10개 이상의 의미있는 PR
- 새로운 기능 구현
- 문서 품질 개선 기여

**🥇 Gold Contributor**:
- 프로젝트 핵심 개선 기여
- 커뮤니티 멘토링 활동
- 장기적 유지보수 참여

## 📞 소통 채널

### 공식 채널

**GitHub**:
- Issues: 버그 신고 및 기능 요청
- Discussions: 아이디어 공유 및 질문
- Pull Requests: 코드 및 문서 기여

**커뮤니티**:
- Discord: 실시간 채팅 및 도움말
- Blog: 프로젝트 소식 및 튜토리얼
- Twitter: 업데이트 및 공지사항

### 소통 가이드라인

**존중과 포용**:
- 모든 기여자를 존중하며 대화
- 건설적인 피드백 제공
- 초보자 친화적 분위기 조성

**효과적 소통**:
- 명확하고 구체적인 질문
- 적절한 채널 사용
- 검색 후 질문하기

## 🚀 시작하기

### 첫 기여 추천사항

**문서화 기여**:
1. [good first issue](GitHub 링크) 라벨 확인
2. 간단한 오타 수정부터 시작
3. 예시 코드 개선 기여
4. FAQ 섹션 확장

**코드 기여**:
1. 기존 코드베이스 이해
2. 테스트 케이스 추가
3. 작은 버그 수정
4. 성능 최적화 기여

### 멘토 프로그램

**신규 기여자 지원**:
- 경험있는 기여자와 1:1 멘토링
- 기여 방향 가이드 제공
- 코드 리뷰 및 피드백

**멘토 신청**:
```markdown
안녕하세요! SwiftYFinance 프로젝트에 기여하고 싶습니다.

**관심 분야**: 문서화 / 코드 / 테스트 / 디자인
**경험 수준**: 초급 / 중급 / 고급
**사용 가능 시간**: 주 X시간
**연락처**: your-email@example.com

**간단 소개**:
본인 소개와 기여하고 싶은 이유를 적어주세요.
```

---

SwiftYFinance 프로젝트에 기여해주셔서 감사합니다! 여러분의 기여가 프로젝트를 더욱 발전시킵니다. 🚀