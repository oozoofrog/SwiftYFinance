/// MCP stdio 트랜스포트 레이어
///
/// stdin을 한 줄씩 읽어 JSON 요청을 수신하고, stdout에 JSON 응답을 한 줄로 출력합니다.
/// JSON-RPC 2.0 over stdio 규격을 준수합니다.
///
/// ## 설계 원칙
/// - nonisolated struct — actor isolation 불필요한 순수 I/O 유틸리티
/// - stderr 혼용 없이 stdout만으로 JSON-RPC 응답 출력 (MCP 규격)
/// - EOF 수신 시 nil 반환 → 호출부에서 루프 종료

import Foundation

/// JSON-RPC 2.0 stdio 트랜스포트
nonisolated struct MCPTransport: Sendable {

    /// stdin에서 한 줄을 읽습니다.
    /// - Returns: 읽은 줄 문자열, EOF이면 nil
    func readLine() -> String? {
        return Swift.readLine(strippingNewline: true)
    }

    /// stdout에 JSON 문자열을 한 줄로 출력합니다.
    /// - Parameter line: 출력할 JSON 문자열 (줄바꿈 없이)
    func writeLine(_ line: String) {
        print(line)
        // stdout flush — Swift의 print()는 라인 버퍼링을 사용하므로 명시적 flush
        fflush(stdout)
    }
}

// MARK: - MCPRequestId

/// JSON-RPC 2.0 요청 ID — String | Int | null 처리
public enum MCPRequestId: Sendable, Codable, CustomStringConvertible {
    case string(String)
    case int(Int)
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let intVal = try? container.decode(Int.self) {
            self = .int(intVal)
        } else if let strVal = try? container.decode(String.self) {
            self = .string(strVal)
        } else {
            self = .null
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let s): try container.encode(s)
        case .int(let i): try container.encode(i)
        case .null: try container.encodeNil()
        }
    }

    public var description: String {
        switch self {
        case .string(let s): return s
        case .int(let i): return "\(i)"
        case .null: return "null"
        }
    }

    /// JSON 리터럴로 직렬화
    var jsonLiteral: String {
        switch self {
        case .string(let s):
            let escaped = s.replacingOccurrences(of: "\\", with: "\\\\")
                           .replacingOccurrences(of: "\"", with: "\\\"")
            return "\"\(escaped)\""
        case .int(let i): return "\(i)"
        case .null: return "null"
        }
    }
}

// MARK: - MCPDecodeError

/// MCP 요청 디코딩 에러
enum MCPDecodeError: Error {
    /// JSON 파싱 자체 실패 (-32700)
    case invalidJSON(Error)
    /// JSON 구조는 유효하나 필수 필드 누락 (-32600)
    case invalidRequest(String)
}

// MARK: - MCPRequest

/// JSON-RPC 2.0 요청 구조체
///
/// `params`의 `[String: Any]`는 JSON 딕셔너리이므로 @unchecked Sendable로 표시합니다.
/// JSON 파싱 직후 한 번만 읽히며 공유 상태가 없습니다.
struct MCPRequest: @unchecked Sendable {
    /// JSON-RPC 버전 ("2.0")
    let jsonrpc: String
    /// 요청 ID (notification은 nil)
    let id: MCPRequestId?
    /// 메서드 이름
    let method: String
    /// 파라미터 딕셔너리
    let params: [String: Any]

    /// notification 여부 (id 없음)
    var isNotification: Bool { id == nil }

    /// Data에서 MCPRequest를 디코딩합니다.
    static func decode(from data: Data) throws -> MCPRequest {
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw MCPDecodeError.invalidJSON(
                NSError(domain: "MCPDecode", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not a JSON object"])
            )
        }

        // jsonrpc 필드 검증
        guard let jsonrpc = obj["jsonrpc"] as? String else {
            throw MCPDecodeError.invalidRequest("Missing 'jsonrpc' field")
        }

        // method 필드 검증
        guard let method = obj["method"] as? String else {
            throw MCPDecodeError.invalidRequest("Missing 'method' field")
        }

        // id 파싱 (optional — notification은 id 없음)
        let requestId: MCPRequestId?
        if let rawId = obj["id"] {
            if rawId is NSNull {
                requestId = .null
            } else if let intId = rawId as? Int {
                requestId = .int(intId)
            } else if let strId = rawId as? String {
                requestId = .string(strId)
            } else {
                requestId = .null
            }
        } else {
            requestId = nil
        }

        // params 파싱 (optional, 기본값 빈 딕셔너리)
        let params = obj["params"] as? [String: Any] ?? [:]

        return MCPRequest(
            jsonrpc: jsonrpc,
            id: requestId,
            method: method,
            params: params
        )
    }
}

// MARK: - MCPResponse

/// JSON-RPC 2.0 응답 구조체
///
/// `body`의 `Any`는 JSON 직렬화 직전까지만 사용되므로 @unchecked Sendable로 표시합니다.
struct MCPResponse: @unchecked Sendable {
    let id: MCPRequestId
    /// result 또는 error 중 하나
    private let body: ResponseBody

    private enum ResponseBody {
        case result(Any)
        case error(code: Int, message: String, data: String?)
    }

    /// 성공 응답 생성
    static func success(id: MCPRequestId, result: Any) -> MCPResponse {
        MCPResponse(id: id, body: .result(result))
    }

    /// 에러 응답 생성
    static func error(id: MCPRequestId, code: Int, message: String, data: String? = nil) -> MCPResponse {
        MCPResponse(id: id, body: .error(code: code, message: message, data: data))
    }

    /// JSON 문자열로 직렬화 (단일 줄)
    func jsonString() -> String {
        let idStr = id.jsonLiteral
        switch body {
        case .result(let value):
            if let jsonData = try? JSONSerialization.data(withJSONObject: value),
               let jsonStr = String(data: jsonData, encoding: .utf8) {
                return "{\"jsonrpc\":\"2.0\",\"id\":\(idStr),\"result\":\(jsonStr)}"
            } else {
                return "{\"jsonrpc\":\"2.0\",\"id\":\(idStr),\"result\":null}"
            }
        case .error(let code, let message, let data):
            let msgEscaped = message
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
                .replacingOccurrences(of: "\n", with: "\\n")
            var errorObj = "{\"code\":\(code),\"message\":\"\(msgEscaped)\""
            if let dataStr = data {
                let dataEscaped = dataStr
                    .replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "\"", with: "\\\"")
                    .replacingOccurrences(of: "\n", with: "\\n")
                errorObj += ",\"data\":\"\(dataEscaped)\""
            }
            errorObj += "}"
            return "{\"jsonrpc\":\"2.0\",\"id\":\(idStr),\"error\":\(errorObj)}"
        }
    }
}

// MARK: - MCPErrorCode

/// JSON-RPC 2.0 표준 에러 코드
enum MCPErrorCode {
    /// JSON 파싱 실패
    static let parseError = -32700
    /// 요청 구조 오류 (jsonrpc/method 누락 등)
    static let invalidRequest = -32600
    /// 존재하지 않는 메서드
    static let methodNotFound = -32601
    /// 파라미터 오류 (필수 파라미터 누락, 타입 오류)
    static let invalidParams = -32602
    /// 서버 내부 에러 (YFError 등)
    static let internalError = -32603
}
