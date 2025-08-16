/// SwiftYFinance 라이브러리의 에러 타입
///
/// Yahoo Finance API 통신 및 데이터 처리 중 발생할 수 있는
/// 모든 에러 상황을 정의합니다.
///
/// ## 에러 처리 예시
/// ```swift
/// do {
///     let quote = try await client.fetchQuote(ticker: ticker)
/// } catch YFError.networkError {
///     print("네트워크 오류가 발생했습니다")
/// } catch YFError.apiError(let message) {
///     print("API 오류: \(message)")
/// } catch {
///     print("알 수 없는 오류: \(error)")
/// }
/// ```
public enum YFError: Error, Equatable {
    
    // invalidSymbol 케이스 제거됨 - API에서 처리
    
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
    
    /// WebSocket 관련 오류
    ///
    /// Yahoo Finance WebSocket 연결 및 스트리밍 중 발생하는 오류
    /// - Parameter error: WebSocket 세부 오류 타입
    case webSocketError(YFWebSocketError)
}

/// Yahoo Finance WebSocket 관련 에러 타입
///
/// WebSocket 연결, 구독, 메시지 처리 중 발생할 수 있는
/// 모든 에러 상황을 정의합니다.
///
/// ## 에러 처리 예시
/// ```swift
/// do {
///     try await webSocketManager.connect()
/// } catch YFError.webSocketError(.connectionFailed(let message)) {
///     print("WebSocket 연결 실패: \(message)")
/// } catch YFError.webSocketError(.messageDecodingFailed(let message)) {
///     print("메시지 디코딩 실패: \(message)")
/// }
/// ```
public enum YFWebSocketError: Error, Equatable {
    
    /// 잘못된 WebSocket URL
    ///
    /// WebSocket 연결을 위한 URL이 유효하지 않은 경우
    /// - Parameter message: URL 오류 상세 메시지
    case invalidURL(String)
    
    /// WebSocket 연결 실패
    ///
    /// Yahoo Finance WebSocket 서버 연결 실패
    /// - Parameter message: 연결 실패 상세 메시지
    case connectionFailed(String)
    
    /// WebSocket 인증 실패
    ///
    /// WebSocket 연결 시 인증이 실패한 경우
    /// - Parameter message: 인증 실패 상세 메시지
    case authenticationFailed(String)
    
    /// WebSocket 프로토콜 오류
    ///
    /// WebSocket 프로토콜 관련 오류
    /// - Parameter message: 프로토콜 오류 상세 메시지
    case protocolError(String)
    
    /// 메시지 디코딩 실패
    ///
    /// 수신한 WebSocket 메시지 디코딩 실패 (Protobuf 파싱 오류 등)
    /// - Parameter message: 디코딩 실패 상세 메시지
    case messageDecodingFailed(String)
    
    /// 구독 실패
    ///
    /// 특정 심볼 구독 실패
    /// - Parameter message: 구독 실패 상세 메시지 (심볼 포함)
    case subscriptionFailed(String)
    
    /// 연결 타임아웃
    ///
    /// WebSocket 연결 시도 시간 초과
    /// - Parameter message: 타임아웃 상세 메시지
    case timeout(String)
    
    /// 예기치 않은 연결 끊김
    ///
    /// WebSocket 연결이 예기치 않게 끊어진 경우
    /// - Parameter message: 연결 끊김 상세 메시지
    case unexpectedDisconnection(String)
    
    /// 재연결 실패
    ///
    /// 자동 재연결 시도가 실패한 경우
    /// - Parameter message: 재연결 실패 상세 메시지
    case reconnectionFailed(String)
}