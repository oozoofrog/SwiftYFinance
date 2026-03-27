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
/// @unchecked Sendable 안전성 근거:
/// - `params: [String: Any]`는 `JSONSerialization.jsonObject`가 반환하는 Foundation 타입
///   (NSString, NSNumber, NSArray, NSDictionary)으로만 구성되며, 이들은 불변(immutable)
/// - MCPRequest는 생성 직후 MCPDispatcher.dispatch()로 전달되어 한 번만 읽힘
/// - 생성과 소비가 동일한 서버 루프 내에서 순차적으로 발생하므로 동시 접근 불가
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
/// @unchecked Sendable 안전성 근거:
/// - `body`의 `Any`는 JSONSerialization 호환 타입(NSString, NSNumber 등 불변 Foundation 타입)
/// - MCPResponse는 생성 즉시 `jsonString()`으로 직렬화되어 stdout에 출력됨 — 공유/저장 없음
/// - 생성과 직렬화가 동일한 서버 루프 내에서 순차적으로 발생
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
    ///
    /// JSONSerialization을 사용하여 제어 문자, 유니코드 등을 안전하게 이스케이프합니다.
    func jsonString() -> String {
        var dict: [String: Any] = ["jsonrpc": "2.0"]

        // id 직렬화
        switch id {
        case .string(let s): dict["id"] = s
        case .int(let i): dict["id"] = i
        case .null: dict["id"] = NSNull()
        }

        switch body {
        case .result(let value):
            dict["result"] = value
        case .error(let code, let message, let data):
            var errorObj: [String: Any] = ["code": code, "message": message]
            if let dataStr = data {
                errorObj["data"] = dataStr
            }
            dict["error"] = errorObj
        }

        if let jsonData = try? JSONSerialization.data(withJSONObject: dict),
           let jsonStr = String(data: jsonData, encoding: .utf8) {
            return jsonStr
        }
        // 폴백 — 직렬화 실패 시 최소한의 에러 응답
        return "{\"jsonrpc\":\"2.0\",\"id\":null,\"error\":{\"code\":-32603,\"message\":\"Internal serialization error\"}}"
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
