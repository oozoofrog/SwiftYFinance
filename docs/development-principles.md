# 개발 원칙

SwiftYFinance 프로젝트의 핵심 개발 원칙과 아키텍처 가이드라인

## TDD 방법론
- **Red → Green → Refactor** 사이클 엄격히 준수
- 테스트 우선 개발로 모든 기능 검증
- Swift Testing 프레임워크 사용

## Tidy First? 원칙
Kent Beck의 "Tidy First?" 방법론에 따라 구조 변경과 기능 변경을 명확히 분리합니다.

### 기본 원칙
- **구조 변경 먼저**: 코드 정리를 기능 추가보다 우선
- **별도 커밋**: 구조 변경과 기능 변경은 절대 같은 커밋에 포함하지 않음
- **작은 단위**: 한 번에 하나씩 작은 개선 수행

### 커밋 유형
```
[Tidy] 리팩토링, 이름 변경, 파일 분리 등 구조 개선
[Feature] 새로운 기능 추가
[Fix] 버그 수정
[Test] 테스트 추가 또는 수정
```

### 작업 순서
1. 코드가 지저분하면 먼저 정리 (Tidy)
2. 테스트가 모두 통과하는지 확인
3. 정리된 코드에 새 기능 추가 (Feature)
4. 다시 정리가 필요하면 별도 커밋으로 정리

## 코드 품질
- **Swift 6.1**: 최신 언어 기능 활용
- **Async/Await**: 현대적 동시성 프로그래밍
- **Sendable 프로토콜**: concurrency 안전성
- **모듈화 설계**: 기능별 파일 분리

## Swift 동시성 원칙

### Actor 패턴 활용
- **상태 격리**: mutable 상태는 actor로 격리하여 데이터 레이스 방지
- **Internal State Actor**: 복잡한 상태 관리가 필요한 경우 별도 actor 생성
- **관심사 분리**: 상태 관리와 비즈니스 로직을 명확히 분리

```swift
// ✅ 올바른 패턴: Internal State Actor
internal actor InternalState {
    private var mutableData: [String: Any] = [:]
    
    func updateData(key: String, value: Any) {
        mutableData[key] = value
    }
}

public final class Manager: @unchecked Sendable {
    private let internalState = InternalState()
    
    public func updateValue(key: String, value: Any) async {
        await internalState.updateData(key: key, value: value)
    }
}
```

### Sendable 준수 가이드라인
- **final class 선호**: 상속이 불필요한 경우 final로 선언하여 Sendable 준수 간소화
- **@unchecked Sendable 신중 사용**: 반드시 필요한 경우에만 사용하고 안전성을 보장
- **Non-Sendable 타입 처리**: URLSession 관련 타입은 메인 클래스에서 신중하게 관리

### 동시성 안전 코딩 패턴
- **모든 actor 접근은 async**: actor 메서드 호출 시 반드시 await 사용
- **상태 변경 원자성**: 관련된 여러 상태 변경은 하나의 actor 메서드에서 수행
- **읽기 전용 연산 최적화**: 가능한 경우 computed property로 구현

```swift
// ✅ 원자적 상태 변경
actor StateManager {
    private var count = 0
    private var isActive = false
    
    func activateWithCount(_ newCount: Int) {
        count = newCount
        isActive = true
    }
}

// ❌ 비원자적 상태 변경 (데이터 레이스 위험)
actor BadStateManager {
    private var count = 0
    private var isActive = false
    
    func setCount(_ newCount: Int) { count = newCount }
    func activate() { isActive = true }
}
```

### 테스트에서의 동시성
- **async 테스트 메서드**: actor 상태에 접근하는 테스트는 async로 선언
- **await 사용**: 모든 actor 메서드 호출에 await 키워드 사용
- **동시성 테스트**: 복잡한 동시성 시나리오에 대한 별도 테스트 작성

## 파일 크기 관리

### 분리 기준
- **250줄 초과**: 분리 검토 시작
- **300줄 초과**: 강제 분리 실행
- **테스트 파일**: 15개 메서드 초과 시 검토, 20개 초과 시 분리
- **복잡도**: 15 초과 시 검토, 20 초과 시 분리

### 분리 방식
- **기능별 분리**: 서로 다른 도메인 로직 분리
- **확장 활용**: YFClient의 API별 확장 파일로 분리
- **모델 분리**: 관련 데이터 구조끼리 그룹화

### 분리 원칙
- 의존성 단방향 유지
- public 인터페이스 변경 없이 내부 구조만 정리
- 각 분리 작업은 별도 커밋으로 관리

## 아키텍처 원칙

### 관심사 분리 (Separation of Concerns)
- **모델**: 순수한 데이터 구조 (API 호출 금지)
- **클라이언트**: 모든 API 호출은 YFClient를 통해
- **확장**: 모델에는 계산 속성만, API 로직은 클라이언트에서

```swift
// ✅ 올바른 패턴
let client = YFClient()
let quote = try await client.fetchQuote(ticker: ticker)

// ❌ 잘못된 패턴
let quote = try await YFTicker.fetchQuote() // 모델에 API 로직 금지
```

### 단일 책임 원칙
- 각 파일과 클래스는 하나의 명확한 책임
- 의존성 역전을 통한 결합도 최소화
- 프로토콜 지향 설계

## 네이밍 컨벤션
- **`ticker`**: YFTicker 인스턴스
- **`symbol`**: 문자열 형태의 심볼값  
- **`fetch`**: API 호출을 통한 데이터 조회
- **`period`**: 데이터 조회 기간 열거형

## 에러 처리
- Swift의 Result 타입과 throws/try 사용
- 네트워크부터 데이터 파싱까지 포괄적 에러 처리
- 명확한 에러 메시지와 복구 가이드 제공

## 테스트 원칙
- 단위 테스트와 통합 테스트 분리
- 각 테스트는 독립적으로 실행 가능
- 실제 API 호출을 통한 검증 (필요시)

## 리팩토링 가이드
- 테스트 통과 상태에서만 리팩토링
- 작은 단위로 점진적 개선
- 리팩토링은 [Tidy] 커밋으로 분리