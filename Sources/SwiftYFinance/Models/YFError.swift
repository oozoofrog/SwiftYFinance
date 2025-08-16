/// SwiftYFinance 라이브러리의 에러 타입
///
/// Yahoo Finance API 통신 및 데이터 처리 중 발생할 수 있는
/// 모든 에러 상황을 정의합니다.
///
/// ## 에러 처리 예시
/// ```swift
/// do {
///     let ticker = try YFTicker(symbol: "INVALID_SYMBOL_TOO_LONG")
/// } catch YFError.invalidSymbol {
///     print("유효하지 않은 심볼입니다")
/// } catch YFError.networkError {
///     print("네트워크 오류가 발생했습니다")
/// } catch {
///     print("알 수 없는 오류: \(error)")
/// }
/// ```
public enum YFError: Error, Equatable {
    
    /// 유효하지 않은 심볼
    ///
    /// 다음 조건 중 하나라도 만족하지 않을 때 발생:
    /// - 빈 문자열이거나 공백만 있는 경우
    /// - 10자를 초과하는 경우  
    /// - 허용되지 않은 특수문자 포함
    case invalidSymbol
    
    /// 유효하지 않은 날짜 범위
    ///
    /// 시작일이 종료일보다 늦거나 미래 날짜인 경우 발생
    case invalidDateRange
    
    /// 유효하지 않은 HTTP 요청
    ///
    /// URL 구성이나 요청 파라미터 오류시 발생
    case invalidRequest
    
    /// 유효하지 않은 URL
    ///
    /// URL 구성 실패시 발생
    case invalidURL
    
    /// 유효하지 않은 파라미터
    ///
    /// API 호출 시 전달된 파라미터가 유효하지 않은 경우
    /// - Parameter message: 파라미터 오류 상세 메시지
    case invalidParameter(String)
    
    /// API 응답 파싱 오류
    ///
    /// Yahoo Finance API 응답을 Swift 모델로 변환 중 오류
    case parsingError
    
    /// 네트워크 통신 오류
    /// 
    /// Yahoo Finance API와의 통신 중 발생하는 오류
    case networkError
    
    /// API 응답 파싱 오류 (상세 메시지 포함)
    ///
    /// Yahoo Finance API 응답을 Swift 모델로 변환 중 오류
    /// - Parameter message: 파싱 오류 상세 메시지
    case parsingErrorWithMessage(String)
    
    /// 네트워크 통신 오류 (상세 메시지 포함)
    /// 
    /// Yahoo Finance API와의 통신 중 발생하는 오류
    /// - Parameter message: 네트워크 오류 상세 메시지
    case networkErrorWithMessage(String)
    
    /// API 서버 오류
    ///
    /// Yahoo Finance API 서버에서 반환한 오류 메시지
    /// - Parameter message: 서버에서 제공한 오류 메시지
    case apiError(String)
}