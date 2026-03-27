/// JSONValue 깊이/규모 스트레스 테스트
///
/// 검증 대상:
/// - depth 제한: JSONSerialization depth limit 안전 처리 (크래시 없음)
/// - 10,000 원소 배열 round-trip (JSONEncoder/Decoder 경유)
/// - 키 1,000개 object round-trip
/// - 길이 100,000 문자 string round-trip
///
/// 주의: JSONValue.from(jsonObject:)는 재귀 함수로 깊은 중첩에서 스택 오버플로 발생 가능.
/// 깊이 테스트는 JSONSerialization의 depth limit 동작을 검증합니다.

import Testing
import Foundation
@testable import SwiftYFinanceMCP

@Suite("JSONValue 깊이/규모 스트레스", .serialized)
struct JSONValueStressTests {

    // MARK: - depth 한계 검증

    @Test("200 depth 중첩 배열 JSONDecoder 경유 파싱", .timeLimit(.minutes(1)))
    func depth200NestedArray() throws {
        // JSONDecoder는 내부적으로 depth 제한이 있음 (통상 512)
        // 200 depth는 안전하게 통과 가능
        var json = String(repeating: "[", count: 200)
        json += "1"
        json += String(repeating: "]", count: 200)
        let data = json.data(using: .utf8)!

        // JSONDecoder 경유 파싱
        let jsonValue = try JSONDecoder().decode(JSONValue.self, from: data)

        // 최외곽은 array여야 함
        guard case .array = jsonValue else {
            Issue.record("200 depth 중첩 배열 파싱 결과가 .array가 아닙니다")
            return
        }
    }

    @Test("1000 depth 중첩 배열 — depth limit 초과 시 throws (크래시 아님)", .timeLimit(.minutes(1)))
    func depth1000NestedArraySafeError() {
        // JSONSerialization은 약 512 depth에서 에러를 throw — 크래시 아님
        var json = String(repeating: "[", count: 1000)
        json += "1"
        json += String(repeating: "]", count: 1000)
        let data = json.data(using: .utf8)!

        // JSONSerialization — depth limit 초과 시 throws
        let serResult = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        _ = serResult  // nil 또는 값 — 어느 쪽이든 크래시 없음

        // JSONDecoder — 역시 depth limit 초과 시 throws
        let decResult = try? JSONDecoder().decode(JSONValue.self, from: data)
        _ = decResult  // nil 또는 값 — 어느 쪽이든 크래시 없음

        // 이 라인에 도달 = 스택 오버플로 없이 안전 처리됨
    }

    // MARK: - 10,000 원소 배열

    @Test("10,000 원소 배열 round-trip", .timeLimit(.minutes(1)))
    func array10000Elements() throws {
        // 10,000 원소 배열 생성
        let arr = (0..<10_000).map { JSONValue.int($0) }
        let original = JSONValue.array(arr)

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)

        #expect(decoded == original)

        // 원소 수 검증
        if case .array(let elements) = decoded {
            #expect(elements.count == 10_000)
        }
    }

    @Test("10,000 원소 배열 toJSONObject 변환", .timeLimit(.minutes(1)))
    func array10000ToJSONObject() throws {
        let arr = (0..<10_000).map { JSONValue.int($0) }
        let original = JSONValue.array(arr)

        let jsonObj = original.toJSONObject()
        guard let anyArr = jsonObj as? [Any] else {
            Issue.record("toJSONObject 결과가 [Any]가 아닙니다")
            return
        }
        #expect(anyArr.count == 10_000)

        // JSONSerialization 직렬화 검증
        let data = try JSONSerialization.data(withJSONObject: jsonObj)
        #expect(!data.isEmpty)
    }

    // MARK: - 키 1,000개 object

    @Test("키 1,000개 object round-trip", .timeLimit(.minutes(1)))
    func object1000Keys() throws {
        var dict: [String: JSONValue] = [:]
        dict.reserveCapacity(1_000)
        for i in 0..<1_000 {
            dict["key\(i)"] = .int(i)
        }
        let original = JSONValue.object(dict)

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)

        #expect(decoded == original)

        if case .object(let obj) = decoded {
            #expect(obj.count == 1_000)
        }
    }

    // MARK: - 길이 100,000 문자 string

    @Test("100,000자 문자열 round-trip", .timeLimit(.minutes(1)))
    func string100000Chars() throws {
        let longString = String(repeating: "a", count: 100_000)
        let original = JSONValue.string(longString)

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)

        #expect(decoded == original)

        if case .string(let s) = decoded {
            #expect(s.count == 100_000)
        }
    }

    @Test("100,000자 유니코드 문자열 round-trip", .timeLimit(.minutes(1)))
    func string100000UnicodeChars() throws {
        // 한국어 문자 반복 (3바이트 UTF-8)
        let longString = String(repeating: "가", count: 100_000)
        let original = JSONValue.string(longString)

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)

        #expect(decoded == original)

        if case .string(let s) = decoded {
            #expect(s.count == 100_000)
        }
    }

    // MARK: - 복합 규모 테스트

    @Test("1,000개 키 object에 100자 string 값 — 규모 검증", .timeLimit(.minutes(1)))
    func largeObjectWithLargeValues() throws {
        var dict: [String: JSONValue] = [:]
        for i in 0..<1_000 {
            let value = String(repeating: "v", count: 100)
            dict["k\(i)"] = .string(value)
        }
        let original = JSONValue.object(dict)

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)

        if case .object(let obj) = decoded {
            #expect(obj.count == 1_000)
        } else {
            Issue.record("복합 규모 테스트 실패")
        }
    }
}
