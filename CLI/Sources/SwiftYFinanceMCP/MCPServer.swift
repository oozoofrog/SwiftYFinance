/// MCP 서버 실행기
///
/// MCPTransport와 MCPDispatcher를 조합하여 stdin/stdout JSON-RPC 루프를 구동합니다.

import Foundation

/// MCP 서버 진입 구조체
public nonisolated struct MCPServer: Sendable {

    public init() {}

    /// 서버 실행 — stdin에서 JSON-RPC 요청을 읽고 stdout으로 응답을 씁니다.
    public func run() async {
        let transport = MCPTransport()
        let dispatcher = MCPDispatcher()

        while let line = transport.readLine() {
            // 빈 줄 무시
            guard !line.isEmpty else { continue }

            let response: MCPResponse

            // 1. JSON 파싱
            guard let data = line.data(using: .utf8) else {
                // UTF-8 변환 실패는 매우 드문 경우 — 파싱 에러로 처리
                response = MCPResponse.error(
                    id: .null,
                    code: MCPErrorCode.parseError,
                    message: "Invalid UTF-8 encoding"
                )
                transport.writeLine(response.jsonString())
                continue
            }

            let request: MCPRequest
            do {
                request = try MCPRequest.decode(from: data)
            } catch let decodeError as MCPDecodeError {
                // JSON 파싱 실패 → -32700 Parse error
                // JSON 구조 유효하나 필수 필드 누락 → -32600 Invalid Request
                let code: Int
                let message: String
                switch decodeError {
                case .invalidJSON:
                    code = MCPErrorCode.parseError
                    message = "Parse error: invalid JSON"
                case .invalidRequest(let reason):
                    code = MCPErrorCode.invalidRequest
                    message = "Invalid Request: \(reason)"
                }
                response = MCPResponse.error(id: .null, code: code, message: message)
                transport.writeLine(response.jsonString())
                continue
            } catch {
                response = MCPResponse.error(
                    id: .null,
                    code: MCPErrorCode.parseError,
                    message: "Parse error: \(error)"
                )
                transport.writeLine(response.jsonString())
                continue
            }

            // 2. notification 처리 (id 없음) — 응답 불필요
            if request.isNotification {
                // notifications/initialized 등 — 무시
                continue
            }

            // 3. 메서드 디스패치
            let result = await dispatcher.dispatch(request: request)
            transport.writeLine(result.jsonString())
        }
        // EOF → 정상 종료
    }
}
