import Testing
@testable import SwiftYFinance

/// YFError LocalizedError 구현 검증 테스트
///
/// F002 기능 요구사항:
/// - errorDescription, failureReason, recoverySuggestion 프로퍼티 구현 검증
/// - 모든 케이스에서 localizedDescription이 비어있지 않음을 보장
@Suite("YFError Tests")
struct YFErrorTests {

    // MARK: - errorDescription 검증

    @Test("모든 YFError 케이스의 localizedDescription이 비어있지 않음")
    func allCasesHaveNonEmptyLocalizedDescription() {
        let cases: [YFError] = [
            .invalidDateRange,
            .invalidRequest,
            .invalidURL,
            .invalidParameter("테스트 파라미터"),
            .parsingError("파싱 실패 이유"),
            .parsingError(nil),
            .networkError("네트워크 실패 이유"),
            .networkError(nil),
            .apiError("API 오류 메시지"),
            .invalidResponse,
            .httpError(statusCode: 404),
            .noData,
            .webSocketError(.connectionFailed("연결 실패"))
        ]

        for error in cases {
            #expect(error.localizedDescription.isEmpty == false,
                    "YFError.\(error)의 localizedDescription이 비어있으면 안 됩니다.")
        }
    }

    @Test("invalidDateRange 에러 설명 검증")
    func invalidDateRangeDescription() {
        let error = YFError.invalidDateRange
        #expect(error.errorDescription?.isEmpty == false)
        #expect(error.failureReason?.isEmpty == false)
        #expect(error.recoverySuggestion?.isEmpty == false)
    }

    @Test("invalidParameter 에러 설명에 파라미터 메시지 포함")
    func invalidParameterDescriptionContainsMessage() {
        let message = "Symbol cannot be empty"
        let error = YFError.invalidParameter(message)
        #expect(error.errorDescription?.contains(message) == true)
    }

    @Test("parsingError(String?) — 메시지 있는 경우")
    func parsingErrorWithMessage() {
        let message = "JSON 키 누락"
        let error = YFError.parsingError(message)
        #expect(error.errorDescription?.contains(message) == true)
        #expect(error.localizedDescription.isEmpty == false)
    }

    @Test("parsingError(String?) — 메시지 없는 경우")
    func parsingErrorWithoutMessage() {
        let error = YFError.parsingError(nil)
        #expect(error.errorDescription?.isEmpty == false)
        #expect(error.localizedDescription.isEmpty == false)
    }

    @Test("networkError(String?) — 메시지 있는 경우")
    func networkErrorWithMessage() {
        let message = "HTTP 503"
        let error = YFError.networkError(message)
        #expect(error.errorDescription?.contains(message) == true)
        #expect(error.localizedDescription.isEmpty == false)
    }

    @Test("networkError(String?) — 메시지 없는 경우")
    func networkErrorWithoutMessage() {
        let error = YFError.networkError(nil)
        #expect(error.errorDescription?.isEmpty == false)
        #expect(error.localizedDescription.isEmpty == false)
    }

    @Test("httpError 에러 설명에 상태 코드 포함")
    func httpErrorDescriptionContainsStatusCode() {
        let statusCode = 404
        let error = YFError.httpError(statusCode: statusCode)
        #expect(error.errorDescription?.contains("\(statusCode)") == true)
    }

    @Test("httpError 429 복구 제안 검증")
    func httpError429RecoverySuggestion() {
        let error = YFError.httpError(statusCode: 429)
        #expect(error.recoverySuggestion?.isEmpty == false)
    }

    @Test("apiError 에러 설명에 서버 메시지 포함")
    func apiErrorDescriptionContainsMessage() {
        let message = "Invalid Symbol: XYZABC"
        let error = YFError.apiError(message)
        #expect(error.errorDescription?.contains(message) == true)
    }

    @Test("webSocketError 에러 설명이 비어있지 않음")
    func webSocketErrorDescription() {
        let error = YFError.webSocketError(.connectionFailed("서버 응답 없음"))
        #expect(error.errorDescription?.isEmpty == false)
        #expect(error.localizedDescription.isEmpty == false)
    }

    // MARK: - failureReason 검증

    @Test("모든 YFError 케이스의 failureReason이 비어있지 않음")
    func allCasesHaveNonEmptyFailureReason() {
        let cases: [YFError] = [
            .invalidDateRange,
            .invalidRequest,
            .invalidURL,
            .invalidParameter("테스트"),
            .parsingError("이유"),
            .parsingError(nil),
            .networkError("이유"),
            .networkError(nil),
            .apiError("메시지"),
            .invalidResponse,
            .httpError(statusCode: 500),
            .noData,
            .webSocketError(.timeout("30초 초과"))
        ]

        for error in cases {
            #expect(error.failureReason?.isEmpty == false,
                    "YFError.\(error)의 failureReason이 nil이거나 비어있으면 안 됩니다.")
        }
    }

    // MARK: - recoverySuggestion 검증

    @Test("모든 YFError 케이스의 recoverySuggestion이 비어있지 않음")
    func allCasesHaveNonEmptyRecoverySuggestion() {
        let cases: [YFError] = [
            .invalidDateRange,
            .invalidRequest,
            .invalidURL,
            .invalidParameter("테스트"),
            .parsingError(nil),
            .networkError(nil),
            .apiError("메시지"),
            .invalidResponse,
            .httpError(statusCode: 500),
            .noData,
            .webSocketError(.notConnected("연결 안 됨"))
        ]

        for error in cases {
            #expect(error.recoverySuggestion?.isEmpty == false,
                    "YFError.\(error)의 recoverySuggestion이 nil이거나 비어있으면 안 됩니다.")
        }
    }
}
