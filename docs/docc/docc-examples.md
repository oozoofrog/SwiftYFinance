# DocC 문서화 예시 템플릿

## Phase별 DocC 주석 예시

이 문서는 각 Phase에서 작성할 DocC 주석의 구체적인 예시를 제공합니다.

### Phase 1: 핵심 API 클래스 예시

#### YFClient.swift (완료됨)
```swift
/// SwiftYFinance의 메인 클라이언트 클래스
///
/// Yahoo Finance API와 상호작용하여 금융 데이터를 조회하는 핵심 인터페이스입니다.
/// Python yfinance 라이브러리의 Swift 포팅 버전으로, 동일한 API를 제공합니다.
///
/// ## 주요 기능
/// - **과거 가격 데이터**: 일간/분간 OHLCV 데이터
/// - **실시간 시세**: 현재 가격 및 시장 정보
/// - **재무제표**: 손익계산서, 대차대조표, 현금흐름표
/// - **실적 데이터**: 분기별/연간 실적 정보
///
/// ## 사용 예시
/// ```swift
/// let client = YFClient()
/// 
/// // 애플 주식 1년간 일간 데이터
/// let history = try await client.fetchPriceHistory(
///     symbol: "AAPL", 
///     period: .oneYear
/// )
/// 
/// // 실시간 시세 조회
/// let quote = try await client.fetchQuote(symbol: "AAPL")
/// print("현재가: \(quote.regularMarketPrice)")
/// ```
public class YFClient {
    
    /// 네트워크 세션 관리자
    internal let session: YFSession
    
    /// YFClient 초기화
    ///
    /// 기본 설정으로 Yahoo Finance API 클라이언트를 생성합니다.
    /// 내부적으로 네트워크 세션, 요청 빌더, 응답 파서를 초기화합니다.
    public init() { ... }
}
```

### Phase 2: 핵심 데이터 모델 예시

#### YFQuote.swift (완료됨)
```swift
/// 실시간 주식 시세 정보
///
/// Yahoo Finance API에서 제공하는 현재 시장 데이터를 포함합니다.
/// 정규 거래시간, 장전/장후 거래 데이터를 모두 지원합니다.
///
/// ## 포함 데이터
/// - **현재가**: 최신 거래가격
/// - **거래량**: 당일 총 거래량  
/// - **시장 통계**: 시가, 고가, 저가, 전일종가
/// - **시가총액**: 발행주식수 × 현재가
/// - **장외 거래**: 장전/장후 거래 데이터 (해당시)
///
/// ## 사용 예시
/// ```swift
/// let client = YFClient()
/// let quote = try await client.fetchQuote(symbol: "AAPL")
///
/// print("회사명: \(quote.shortName)")
/// print("현재가: $\(quote.regularMarketPrice)")
/// print("거래량: \(quote.regularMarketVolume.formatted())")
/// print("시가총액: $\(quote.marketCap.formatted())")
///
/// // 장후 거래 확인
/// if let postPrice = quote.postMarketPrice {
///     print("장후 거래가: $\(postPrice)")
/// }
/// ```
public struct YFQuote: Codable {
    
    /// 주식 심볼 정보
    public let ticker: YFTicker
    
    /// 정규 시장 현재가 (USD)
    ///
    /// 정규 거래시간 중 최신 거래가격
    public let regularMarketPrice: Double
}
```

### Phase 3: 네트워크 레이어 예시 (예정)

#### YFSession.swift 템플릿
```swift
/// Yahoo Finance API 네트워크 세션 관리자
///
/// HTTP 요청, 인증, 쿠키 관리를 담당하는 핵심 네트워크 컴포넌트입니다.
/// Chrome 브라우저를 모방하여 Yahoo Finance API 차단을 우회합니다.
///
/// ## 주요 기능
/// - **브라우저 모방**: Chrome User-Agent 및 헤더 설정
/// - **쿠키 관리**: 자동 쿠키 저장 및 CSRF 토큰 처리
/// - **Rate Limiting**: 요청 빈도 제한 및 재시도 로직
/// - **에러 처리**: 네트워크 오류 및 API 에러 자동 처리
///
/// ## 사용 예시
/// ```swift
/// let session = YFSession()
/// let data = try await session.performRequest(url: url)
/// ```
public class YFSession {
    
    /// 네트워크 세션 초기화
    ///
    /// Chrome 브라우저 설정을 모방한 URLSession을 생성합니다.
    public init() { ... }
}
```

### Phase 4: 고급 모델 예시 (예정)

#### YFChartModels.swift 템플릿
```swift
/// Yahoo Finance Chart API 응답 데이터 모델
///
/// Chart API에서 반환되는 복잡한 JSON 구조를 Swift 타입으로 매핑합니다.
/// OHLCV 데이터, 메타데이터, 지표 정보를 포함합니다.
///
/// ## 데이터 구조
/// - **ChartResult**: 메인 차트 데이터 컨테이너
/// - **Quote**: OHLCV 원시 데이터
/// - **AdjClose**: 수정종가 배열
/// - **Meta**: 심볼, 통화, 시간대 정보
///
/// ## 사용 예시
/// ```swift
/// // 내부적으로 YFClient에서 사용됨
/// let chartData = try JSONDecoder().decode(ChartResponse.self, from: data)
/// let prices = convertToPrices(chartData.chart.result.first)
/// ```
struct ChartResult: Codable {
    
    /// 타임스탬프 배열
    ///
    /// Unix 타임스탬프 (초 단위) 배열로 각 데이터 포인트의 시간을 나타냅니다.
    let timestamp: [Int]?
}
```

## 문서화 품질 기준

### 우수한 문서화 기준
1. **완전한 설명**: 클래스/구조체의 목적과 역할 명확
2. **실용적 예시**: 실제 사용 가능한 코드 예시 포함
3. **파라미터 문서화**: 모든 파라미터와 반환값 설명
4. **에러 처리**: 발생 가능한 에러 상황 명시
5. **관련 타입**: 연관된 다른 타입들과의 관계 설명

### 피해야 할 패턴
- 단순한 변수명 반복 (예: `/// The name` for `let name`)
- 구현 세부사항 과도 노출
- 업데이트되지 않는 오래된 예시 코드
- 불완전한 파라미터 설명
- 에러 케이스 누락