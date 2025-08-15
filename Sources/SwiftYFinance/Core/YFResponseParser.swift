import Foundation

/// Yahoo Finance API 응답 파싱을 담당하는 클래스
///
/// `YFResponseParser`는 Yahoo Finance API로부터 받은 JSON 응답을 Swift 객체로 변환합니다.
/// 자동으로 타임스탬프를 Date 객체로 변환하고, 에러 응답을 처리합니다.
///
/// ## Overview
///
/// 이 클래스는 두 가지 주요 기능을 제공합니다:
/// - **데이터 파싱**: JSON 응답을 지정된 타입으로 디코딩
/// - **에러 처리**: Yahoo Finance 에러 응답 파싱 및 처리
///
/// ## Topics
///
/// ### 파서 생성
/// - ``init()``
///
/// ### 응답 파싱
/// - ``parse(_:type:)``
/// - ``parseError(_:)``
///
/// ### 에러 타입
/// - ``YFErrorResponse``
public class YFResponseParser {
    /// JSON 디코더 인스턴스
    private let decoder: JSONDecoder
    
    /// YFResponseParser 인스턴스를 생성합니다
    ///
    /// 디코더는 자동으로 Unix 타임스탬프를 Date 객체로 변환하도록 설정됩니다.
    ///
    /// ## Example
    /// ```swift
    /// let parser = YFResponseParser()
    /// ```
    public init() {
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .secondsSince1970
    }
    
    /// JSON 데이터를 지정된 타입으로 파싱합니다
    ///
    /// - Parameters:
    ///   - data: 파싱할 JSON 데이터
    ///   - type: 디코딩할 타입
    ///
    /// - Returns: 파싱된 객체
    ///
    /// - Throws: ``YFError/parsingError`` JSON 파싱 실패 시
    ///
    /// ## Example
    /// ```swift
    /// let parser = YFResponseParser()
    /// let jsonData = Data(...) // API 응답 데이터
    ///
    /// do {
    ///     let quote = try parser.parse(jsonData, type: YFQuote.self)
    ///     print("현재 가격: \(quote.regularMarketPrice)")
    /// } catch {
    ///     print("파싱 실패: \(error)")
    /// }
    /// ```
    ///
    /// - Important: 파싱하려는 타입은 반드시 `Decodable` 프로토콜을 준수해야 합니다.
    public func parse<T: Decodable>(_ data: Data, type: T.Type) throws -> T {
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw YFError.parsingError
        }
    }
    
    /// Yahoo Finance 에러 응답을 파싱합니다
    ///
    /// Yahoo Finance API는 에러 발생 시 특정 형식의 JSON 응답을 반환합니다.
    /// 이 메서드는 해당 에러 응답을 파싱하여 구조화된 에러 정보를 제공합니다.
    ///
    /// - Parameter data: 에러 응답 JSON 데이터
    ///
    /// - Returns: 파싱된 에러 정보 또는 nil (파싱 실패 시)
    ///
    /// ## Example
    /// ```swift
    /// let parser = YFResponseParser()
    ///
    /// if let errorInfo = try parser.parseError(responseData) {
    ///     print("에러 코드: \(errorInfo.code)")
    ///     if let description = errorInfo.description {
    ///         print("에러 설명: \(description)")
    ///     }
    /// }
    /// ```
    ///
    /// - Note: 이 메서드는 에러를 던지지 않고, 파싱 실패 시 nil을 반환합니다.
    public func parseError(_ data: Data) throws -> YFErrorResponse? {
        do {
            let errorWrapper = try decoder.decode(ErrorWrapper.self, from: data)
            return errorWrapper.chart?.error
        } catch {
            return nil
        }
    }
}

/// Yahoo Finance API 에러 응답 모델
///
/// Yahoo Finance API가 반환하는 에러 정보를 담는 구조체입니다.
///
/// ## Properties
/// - ``code``: 에러 코드
/// - ``description``: 에러에 대한 상세 설명 (옵셔널)
///
/// ## Example
/// ```swift
/// let errorResponse = YFErrorResponse(
///     code: "Invalid Symbol",
///     description: "No data found for symbol INVALID"
/// )
/// ```
public struct YFErrorResponse: Codable {
    /// 에러 코드
    ///
    /// Yahoo Finance에서 정의한 에러 타입을 나타냅니다.
    /// 예: "Invalid Symbol", "Rate Limited" 등
    public let code: String
    
    /// 에러에 대한 상세 설명
    ///
    /// 에러의 원인이나 해결 방법에 대한 추가 정보를 제공합니다.
    /// 모든 에러가 설명을 포함하지는 않습니다.
    public let description: String?
}

/// 에러 응답 래퍼 (내부 사용)
struct ErrorWrapper: Codable {
    let chart: ErrorChart?
}

/// 에러 차트 구조 (내부 사용)
struct ErrorChart: Codable {
    let error: YFErrorResponse?
}