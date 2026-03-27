/// Sendable 컴파일 타임 검증 테스트
///
/// ## 목적
/// `@unchecked Sendable` 없이 JSONValue, MCPRequest, MCPResponse가
/// Task/actor 경계를 안전하게 넘어갈 수 있음을 컴파일러가 검증하도록 합니다.
///
/// ## 방법
/// - `Task { }` 클로저 내에서 `JSONValue`, `MCPRequest`, `MCPResponse` 캡처
/// - actor 메서드에 `JSONValue` 파라미터로 전달
/// - 이 파일이 `-strict-concurrency=complete` (Swift 6)에서 경고/에러 없이 컴파일되면
///   Sendable 준수가 증명됩니다
///
/// 런타임 assertion 불필요 — 빌드 성공 자체가 검증입니다.
/// 단, Swift Testing 프레임워크를 사용하여 테스트 러너가 파일을 인식하도록 합니다.

import Testing
import Foundation
@testable import SwiftYFinanceMCP

// MARK: - Sendable actor 경계 테스트용 actor

/// JSONValue를 actor 경계를 넘겨 수신하는 예시 actor
///
/// actor 메서드의 파라미터 타입이 Sendable이어야 컴파일됩니다.
/// JSONValue가 Sendable이 아니면 이 파일 자체가 컴파일 에러를 냅니다.
private actor JSONValueReceiver {

    private var received: [JSONValue] = []

    /// JSONValue를 actor 경계를 넘겨 수신
    /// Swift 6에서 파라미터 타입은 암묵적으로 Sendable 요구
    func receive(_ value: JSONValue) {
        received.append(value)
    }

    /// MCPRequest를 actor 경계를 넘겨 수신
    func receive(request: MCPRequest) {
        // 요청의 params를 JSONValue로 변환
        let paramsAsValue = JSONValue.object(request.params)
        received.append(paramsAsValue)
    }

    func count() -> Int {
        received.count
    }
}

// MARK: - 컴파일 타임 Sendable 검증 함수

/// Task 클로저에서 JSONValue 캡처 — nonisolated enum이므로 Sendable 충족
///
/// 이 함수가 컴파일되면 JSONValue가 Sendable임이 증명됩니다.
/// @unchecked Sendable 없이 Task 클로저가 JSONValue를 캡처할 수 있어야 합니다.
nonisolated func verifyJSONValueIsSendableInTask() async {
    // 다양한 JSONValue case 생성
    let values: [JSONValue] = [
        .string("hello"),
        .int(42),
        .number(3.14),
        .bool(true),
        .null,
        .array([.string("a"), .int(1)]),
        .object(["key": .string("value")])
    ]

    // Task 클로저에서 캡처 — Sendable 없으면 컴파일 에러
    let _ = await withTaskGroup(of: Void.self) { group in
        for value in values {
            group.addTask {
                // Task 클로저 내에서 JSONValue 접근 — actor 경계 통과
                let _ = value.stringValue ?? value.intValue.map { "\($0)" } ?? "other"
            }
        }
    }
}

/// MCPRequest가 Task 경계를 통과하는지 검증
///
/// MCPRequest가 Sendable이면 이 함수가 컴파일됩니다.
nonisolated func verifyMCPRequestIsSendableInTask() async {
    let request = MCPRequest(
        jsonrpc: "2.0",
        id: .int(1),
        method: "tools/list",
        params: [:]
    )

    // Task 클로저에서 MCPRequest 캡처
    let _ = await Task {
        // MCPRequest의 모든 필드 접근
        let _ = request.jsonrpc
        let _ = request.method
        let _ = request.id
        let _ = request.params
    }.value
}

/// MCPResponse가 Task 경계를 통과하는지 검증
nonisolated func verifyMCPResponseIsSendableInTask() async {
    let response = MCPResponse.success(
        id: .int(1),
        result: .object(["tools": .array([])])
    )

    let _ = await Task {
        // MCPResponse 캡처 및 직렬화 (non-throwing)
        let _ = response.jsonString()
    }.value
}

/// actor 경계를 넘기는 JSONValue 전달 검증
nonisolated func verifyJSONValueCrossesActorBoundary() async {
    let receiver = JSONValueReceiver()

    // actor 메서드에 JSONValue 전달 — actor 경계 통과
    await receiver.receive(.string("actor-crossing"))
    await receiver.receive(.int(100))
    await receiver.receive(.object(["nested": .array([.bool(true)])]))

    // MCPRequest도 actor 경계 통과
    let request = MCPRequest(
        jsonrpc: "2.0",
        id: .string("req-1"),
        method: "tools/call",
        params: ["name": .string("quote"), "arguments": .object(["symbol": .string("AAPL")])]
    )
    await receiver.receive(request: request)
}

// MARK: - Swift Testing 테스트

@Suite("Sendable 컴파일 타임 검증")
struct SendableCompileTimeTests {

    // MARK: - @unchecked Sendable 부재 검증

    @Test("CLI 소스에 @unchecked Sendable 선언 없음")
    func noUncheckedSendableInSources() throws {
        // 파일 시스템에서 @unchecked Sendable 검색
        let sourcesPath = "/Volumes/eyedisk/develop/oozoofrog/SwiftYFinance/CLI/Sources/SwiftYFinanceMCP"
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(atPath: sourcesPath) else {
            Issue.record("소스 디렉토리를 열 수 없습니다: \(sourcesPath)")
            return
        }

        var violations: [String] = []
        while let file = enumerator.nextObject() as? String {
            guard file.hasSuffix(".swift") else { continue }
            let fullPath = "\(sourcesPath)/\(file)"
            guard let contents = try? String(contentsOfFile: fullPath, encoding: .utf8) else { continue }

            let lines = contents.components(separatedBy: "\n")
            for (lineNum, line) in lines.enumerated() {
                // 주석이 아닌 @unchecked Sendable 선언만 검사
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.contains("@unchecked Sendable") && !trimmed.hasPrefix("//") && !trimmed.hasPrefix("*") {
                    violations.append("\(file):\(lineNum + 1): \(trimmed)")
                }
            }
        }

        if !violations.isEmpty {
            for v in violations {
                Issue.record("@unchecked Sendable 발견: \(v)")
            }
        }
        #expect(violations.isEmpty, "@unchecked Sendable이 \(violations.count)개 발견됨")
    }

    // MARK: - 컴파일 타임 Sendable 검증 (런타임 실행)

    @Test("JSONValue — Task 클로저에서 캡처 가능 (Sendable 충족)")
    func jsonValueSendableInTask() async {
        // 이 테스트가 컴파일되고 실행되면 JSONValue의 Sendable 준수가 증명됨
        await verifyJSONValueIsSendableInTask()
        // 런타임 검증: 실행 완료 자체가 성공
    }

    @Test("MCPRequest — Task 경계 통과 가능 (Sendable 충족)")
    func mcpRequestSendableInTask() async {
        await verifyMCPRequestIsSendableInTask()
    }

    @Test("MCPResponse — Task 경계 통과 가능 (Sendable 충족)")
    func mcpResponseSendableInTask() async {
        await verifyMCPResponseIsSendableInTask()
    }

    @Test("JSONValue — actor 경계 통과 가능 (nonisolated enum Sendable)")
    func jsonValueCrossesActorBoundary() async {
        await verifyJSONValueCrossesActorBoundary()
    }

    // MARK: - JSONValue Sendable 특성 검증

    @Test("JSONValue — withTaskGroup에서 병렬 처리 가능")
    func jsonValueInParallelTaskGroup() async {
        // JSONValue 배열을 Task Group에서 병렬 처리
        let input: [JSONValue] = (0..<10).map { .int($0) }

        let results = await withTaskGroup(of: JSONValue.self) { group -> [JSONValue] in
            for value in input {
                group.addTask {
                    // Task 클로저 내 JSONValue 변환
                    if let i = value.intValue {
                        return .int(i * 2)
                    }
                    return value
                }
            }
            var collected: [JSONValue] = []
            for await result in group {
                collected.append(result)
            }
            return collected
        }

        #expect(results.count == 10, "Task Group에서 10개 JSONValue 처리 완료")
        // 모든 결과가 .int인지 확인
        let allInts = results.allSatisfy { $0.intValue != nil }
        #expect(allInts, "모든 결과가 .int여야 합니다")
    }

    @Test("JSONValue — async let 병렬 바인딩 (Sendable 필요)")
    func jsonValueAsyncLet() async {
        // async let은 Sendable 값만 캡처 가능
        async let v1 = Task { JSONValue.string("async1") }.value
        async let v2 = Task { JSONValue.int(42) }.value
        async let v3 = Task { JSONValue.array([.null, .bool(true)]) }.value

        let results = await [v1, v2, v3]
        #expect(results.count == 3)
        #expect(results[0].stringValue == "async1")
        #expect(results[1].intValue == 42)
        #expect(results[2].arrayValue?.count == 2)
    }

    @Test("MCPRequest.params — [String: JSONValue]가 actor 경계 통과")
    func mcpParamsDictCrossesActorBoundary() async {
        let receiver = JSONValueReceiver()

        let params: [String: JSONValue] = [
            "symbol": .string("TSLA"),
            "count": .int(10),
            "includeHistory": .bool(true)
        ]
        let request = MCPRequest(jsonrpc: "2.0", id: .int(99), method: "tools/call", params: params)

        // actor 경계를 넘겨 MCPRequest 전달
        await receiver.receive(request: request)
        let count = await receiver.count()
        #expect(count == 1, "actor가 MCPRequest를 수신해야 합니다")
    }

    // MARK: - MCPToolDefinition Sendable 검증

    @Test("MCPToolDefinition.inputSchema — JSONValue이므로 Task 경계 통과")
    func toolDefinitionSendableInTask() async {
        let toolDef = MCPToolDefinition.quoteToolDefinition

        // Task 클로저에서 MCPToolDefinition 캡처
        let schema = await Task {
            toolDef.inputSchema
        }.value

        // inputSchema는 .object여야 함
        #expect(schema.objectValue != nil, "inputSchema는 .object여야 합니다")
    }

    // MARK: - JSONValue Hashable (Set에서 사용 가능)

    @Test("JSONValue — Set에 저장 가능 (Hashable 충족)")
    func jsonValueInSet() {
        // Hashable이어야 Set에 넣을 수 있음
        let set: Set<JSONValue> = [
            .string("a"),
            .int(1),
            .bool(true),
            .null,
            .string("a")  // 중복
        ]
        // "a"가 중복이므로 4개
        #expect(set.count == 4, "중복 제거 후 4개여야 합니다")
    }

    @Test("JSONValue — Dictionary 키로 사용 가능 (Hashable 충족)")
    func jsonValueAsDictionaryKey() {
        var dict: [JSONValue: String] = [:]
        dict[.string("key1")] = "value1"
        dict[.int(42)] = "fortyTwo"
        dict[.bool(true)] = "yes"
        dict[.null] = "nothing"

        #expect(dict.count == 4)
        #expect(dict[.string("key1")] == "value1")
        #expect(dict[.int(42)] == "fortyTwo")
    }
}
