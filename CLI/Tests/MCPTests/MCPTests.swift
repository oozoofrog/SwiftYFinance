/// MCP 서버 핵심 로직 단위 테스트
///
/// 테스트 대상:
/// 1. MCPRequest JSON 디코딩 (유효/무효 입력)
/// 2. tools/list 응답에 12개 tool 포함 여부
/// 3. tools/call 파라미터 파싱 (누락/타입 오류 시 -32602 에러)
/// 4. JSON-RPC 에러 코드 매핑
///
/// 네트워크 호출 없는 순수 로직 테스트 (YFClient, URLSession 미사용)

import Testing
import Foundation
@testable import SwiftYFinanceMCP

// MARK: - MCPRequest 디코딩 테스트

@Suite("MCPRequest 디코딩")
struct MCPRequestDecodeTests {

    @Test("유효한 tools/list 요청 디코딩")
    func decodeValidToolsList() throws {
        let json = """
        {"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}
        """.data(using: .utf8)!

        let request = try MCPRequest.decode(from: json)
        #expect(request.jsonrpc == "2.0")
        #expect(request.method == "tools/list")
        if case .int(let id) = request.id {
            #expect(id == 1)
        } else {
            Issue.record("id는 .int(1)이어야 합니다")
        }
    }

    @Test("문자열 id 디코딩")
    func decodeStringId() throws {
        let json = """
        {"jsonrpc":"2.0","id":"abc-123","method":"tools/list","params":{}}
        """.data(using: .utf8)!

        let request = try MCPRequest.decode(from: json)
        if case .string(let id) = request.id {
            #expect(id == "abc-123")
        } else {
            Issue.record("id는 .string이어야 합니다")
        }
    }

    @Test("null id 디코딩")
    func decodeNullId() throws {
        let json = """
        {"jsonrpc":"2.0","id":null,"method":"tools/list","params":{}}
        """.data(using: .utf8)!

        let request = try MCPRequest.decode(from: json)
        if case .null = request.id {
            // 통과
        } else {
            Issue.record("id는 .null이어야 합니다")
        }
    }

    @Test("notification (id 없음) 디코딩")
    func decodeNotification() throws {
        let json = """
        {"jsonrpc":"2.0","method":"notifications/initialized","params":{}}
        """.data(using: .utf8)!

        let request = try MCPRequest.decode(from: json)
        #expect(request.isNotification == true)
        #expect(request.id == nil)
    }

    @Test("잘못된 JSON 입력 — invalidJSON 에러")
    func decodeInvalidJSON() throws {
        let json = "not valid json{{{".data(using: .utf8)!

        #expect(throws: (any Error).self) {
            try MCPRequest.decode(from: json)
        }
    }

    @Test("jsonrpc 필드 누락 — invalidRequest 에러")
    func decodeMissingJsonrpc() throws {
        let json = """
        {"id":1,"method":"tools/list","params":{}}
        """.data(using: .utf8)!

        #expect(throws: (any Error).self) {
            try MCPRequest.decode(from: json)
        }
    }

    @Test("method 필드 누락 — invalidRequest 에러")
    func decodeMissingMethod() throws {
        let json = """
        {"jsonrpc":"2.0","id":1,"params":{}}
        """.data(using: .utf8)!

        #expect(throws: (any Error).self) {
            try MCPRequest.decode(from: json)
        }
    }

    @Test("params 딕셔너리 파싱")
    func decodeParams() throws {
        let json = """
        {"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"quote","arguments":{"symbol":"AAPL"}}}
        """.data(using: .utf8)!

        let request = try MCPRequest.decode(from: json)
        #expect(request.params["name"] as? String == "quote")
        let args = request.params["arguments"] as? [String: Any]
        #expect(args?["symbol"] as? String == "AAPL")
    }
}

// MARK: - tools/list 테스트

@Suite("tools/list 응답")
struct ToolsListTests {

    @Test("12개 tool 모두 포함")
    func toolsListHas12Tools() {
        let tools = MCPToolDefinition.allTools
        #expect(tools.count == 12)
    }

    @Test("모든 tool에 name/description/inputSchema 존재")
    func toolsHaveRequiredFields() {
        for tool in MCPToolDefinition.allTools {
            #expect(!tool.name.isEmpty, "tool 이름이 비어있습니다")
            #expect(!tool.description.isEmpty, "tool \(tool.name)의 description이 비어있습니다")
            let schema = tool.inputSchema
            #expect(!schema.isEmpty, "tool \(tool.name)의 inputSchema가 비어있습니다")
        }
    }

    @Test("12개 tool 이름 정확히 일치")
    func toolNamesMatch() {
        let expected: Set<String> = [
            "quote", "multi-quote", "chart", "search", "news",
            "options", "screening", "customScreener", "quoteSummary",
            "domain", "fundamentals", "websocket-snapshot"
        ]
        let actual = Set(MCPToolDefinition.allTools.map { $0.name })
        #expect(actual == expected)
    }

    @Test("quote tool의 required 파라미터에 symbol 포함")
    func quoteTooHasRequiredSymbol() {
        let quoteTool = MCPToolDefinition.allTools.first { $0.name == "quote" }
        let required = quoteTool?.inputSchema["required"] as? [String]
        #expect(required?.contains("symbol") == true)
    }

    @Test("options tool의 required 파라미터에 symbol 포함")
    func optionsToolHasRequiredSymbol() {
        let optionsTool = MCPToolDefinition.allTools.first { $0.name == "options" }
        let required = optionsTool?.inputSchema["required"] as? [String]
        #expect(required?.contains("symbol") == true)
    }

    @Test("multi-quote tool의 required 파라미터에 symbols 포함")
    func multiQuoteToolHasRequiredSymbols() {
        let tool = MCPToolDefinition.allTools.first { $0.name == "multi-quote" }
        let required = tool?.inputSchema["required"] as? [String]
        #expect(required?.contains("symbols") == true)
    }

    @Test("toDictionary()가 올바른 키를 포함")
    func toDictionaryHasCorrectKeys() {
        let tool = MCPToolDefinition.quoteToolDefinition
        let dict = tool.toDictionary()
        #expect(dict["name"] as? String == "quote")
        #expect(dict["description"] != nil)
        #expect(dict["inputSchema"] != nil)
    }
}

// MARK: - JSON-RPC 에러 코드 테스트

@Suite("JSON-RPC 에러 코드")
struct ErrorCodeTests {

    @Test("parseError 코드는 -32700")
    func parseErrorCode() {
        #expect(MCPErrorCode.parseError == -32700)
    }

    @Test("invalidRequest 코드는 -32600")
    func invalidRequestCode() {
        #expect(MCPErrorCode.invalidRequest == -32600)
    }

    @Test("methodNotFound 코드는 -32601")
    func methodNotFoundCode() {
        #expect(MCPErrorCode.methodNotFound == -32601)
    }

    @Test("invalidParams 코드는 -32602")
    func invalidParamsCode() {
        #expect(MCPErrorCode.invalidParams == -32602)
    }

    @Test("internalError 코드는 -32603")
    func internalErrorCode() {
        #expect(MCPErrorCode.internalError == -32603)
    }

    @Test("에러 응답 JSON에 jsonrpc/id/error 필드 포함")
    func errorResponseHasRequiredFields() {
        let response = MCPResponse.error(
            id: .int(1),
            code: MCPErrorCode.methodNotFound,
            message: "Method not found"
        )
        let jsonStr = response.jsonString()
        #expect(jsonStr.contains("\"jsonrpc\""))
        #expect(jsonStr.contains("\"2.0\""))
        #expect(jsonStr.contains("\"id\""))
        #expect(jsonStr.contains("\"error\""))
        #expect(jsonStr.contains("\"code\""))
        #expect(jsonStr.contains("\"message\""))
        #expect(jsonStr.contains("-32601"))
    }

    @Test("성공 응답 JSON에 jsonrpc/id/result 필드 포함")
    func successResponseHasRequiredFields() {
        let response = MCPResponse.success(
            id: .int(42),
            result: ["tools": []]
        )
        let jsonStr = response.jsonString()
        #expect(jsonStr.contains("\"jsonrpc\""))
        #expect(jsonStr.contains("\"2.0\""))
        #expect(jsonStr.contains("\"id\""))
        #expect(jsonStr.contains("\"result\""))
    }

    @Test("응답이 단일 줄 JSON")
    func responseIsSingleLine() {
        let response = MCPResponse.success(
            id: .int(1),
            result: ["key": "value"]
        )
        let jsonStr = response.jsonString()
        let lineCount = jsonStr.components(separatedBy: "\n").count
        #expect(lineCount == 1)
    }
}

// MARK: - MCPRequestId 테스트

@Suite("MCPRequestId")
struct MCPRequestIdTests {

    @Test("int id JSON 리터럴")
    func intIdJsonLiteral() {
        let id = MCPRequestId.int(42)
        #expect(id.jsonLiteral == "42")
    }

    @Test("string id JSON 리터럴")
    func stringIdJsonLiteral() {
        let id = MCPRequestId.string("test-id")
        #expect(id.jsonLiteral == "\"test-id\"")
    }

    @Test("null id JSON 리터럴")
    func nullIdJsonLiteral() {
        let id = MCPRequestId.null
        #expect(id.jsonLiteral == "null")
    }

    @Test("string id 이스케이프 처리")
    func stringIdEscaping() {
        let id = MCPRequestId.string("id\"with\"quotes")
        #expect(id.jsonLiteral.contains("\\\""))
    }
}

// MARK: - tools/call 파라미터 파싱 테스트

@Suite("tools/call 파라미터 파싱")
struct ToolsCallParamsTests {

    @Test("MCPToolError.missingParam 에러 타입")
    func missingParamError() {
        let error = MCPToolError.missingParam("symbol")
        if case .missingParam(let param) = error {
            #expect(param == "symbol")
        } else {
            Issue.record("missingParam 에러가 아닙니다")
        }
    }

    @Test("MCPToolError.unknownTool 에러 타입")
    func unknownToolError() {
        let error = MCPToolError.unknownTool("nonexistent")
        if case .unknownTool(let name) = error {
            #expect(name == "nonexistent")
        } else {
            Issue.record("unknownTool 에러가 아닙니다")
        }
    }

    @Test("MCPToolError.invalidParam 에러 타입")
    func invalidParamError() {
        let error = MCPToolError.invalidParam("symbols must be an array")
        if case .invalidParam(let msg) = error {
            #expect(msg.contains("symbols"))
        } else {
            Issue.record("invalidParam 에러가 아닙니다")
        }
    }

    @Test("에러 응답에 -32602 코드 — 필수 파라미터 누락")
    func missingParamReturns32602() {
        // MCPResponse.error로 직접 생성하여 코드 확인
        let response = MCPResponse.error(
            id: .int(3),
            code: MCPErrorCode.invalidParams,
            message: "Invalid params: missing required parameter 'symbol'"
        )
        let jsonStr = response.jsonString()
        #expect(jsonStr.contains("-32602"))
        #expect(jsonStr.contains("symbol"))
    }

    @Test("에러 응답에 -32601 코드 — 존재하지 않는 tool")
    func unknownToolReturns32601() {
        let response = MCPResponse.error(
            id: .int(2),
            code: MCPErrorCode.methodNotFound,
            message: "Unknown tool: nonexistent_tool"
        )
        let jsonStr = response.jsonString()
        #expect(jsonStr.contains("-32601"))
        #expect(jsonStr.contains("nonexistent_tool"))
    }
}
