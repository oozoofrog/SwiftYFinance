/// JSONValue Codable 단위 테스트
///
/// 검증 대상:
/// 1. 디코딩 순서: Bool → Int → Double → String → Array → Object → null
/// 2. 각 타입의 정확한 디코딩
/// 3. encode → decode round-trip 동등성
/// 4. 타입 판별 정확도 (true가 .int(1)이 되지 않음)

import Testing
import Foundation
@testable import SwiftYFinanceMCP

@Suite("JSONValue Codable")
struct JSONValueCodableTests {

    // MARK: - 기본 타입 디코딩

    @Test("정수 1은 .int(1)로 디코딩 (Double이 아님)")
    func decodeIntAsInt() throws {
        let json = #"{"a":1}"#.data(using: .utf8)!
        let obj = try JSONDecoder().decode([String: JSONValue].self, from: json)
        #expect(obj["a"] == .int(1))
    }

    @Test("소수 1.5는 .number(1.5)로 디코딩 (Int가 아님)")
    func decodeDoubleAsNumber() throws {
        let json = #"{"b":1.5}"#.data(using: .utf8)!
        let obj = try JSONDecoder().decode([String: JSONValue].self, from: json)
        #expect(obj["b"] == .number(1.5))
    }

    @Test("true는 .bool(true)로 디코딩 (Int(1)이 아님)")
    func decodeBoolTrue() throws {
        let json = #"{"c":true}"#.data(using: .utf8)!
        let obj = try JSONDecoder().decode([String: JSONValue].self, from: json)
        #expect(obj["c"] == .bool(true))
    }

    @Test("false는 .bool(false)로 디코딩 (Int(0)이 아님)")
    func decodeBoolFalse() throws {
        let json = #"{"d":false}"#.data(using: .utf8)!
        let obj = try JSONDecoder().decode([String: JSONValue].self, from: json)
        #expect(obj["d"] == .bool(false))
    }

    @Test("문자열은 .string으로 디코딩")
    func decodeString() throws {
        let json = #"{"e":"hello"}"#.data(using: .utf8)!
        let obj = try JSONDecoder().decode([String: JSONValue].self, from: json)
        #expect(obj["e"] == .string("hello"))
    }

    @Test("null은 .null로 디코딩")
    func decodeNull() throws {
        let json = #"{"f":null}"#.data(using: .utf8)!
        let obj = try JSONDecoder().decode([String: JSONValue].self, from: json)
        #expect(obj["f"] == .null)
    }

    @Test("배열은 .array로 디코딩")
    func decodeArray() throws {
        let json = #"[1,2,3]"#.data(using: .utf8)!
        let val = try JSONDecoder().decode(JSONValue.self, from: json)
        #expect(val == .array([.int(1), .int(2), .int(3)]))
    }

    @Test("중첩 object는 .object로 디코딩")
    func decodeObject() throws {
        let json = #"{"key":"val"}"#.data(using: .utf8)!
        let val = try JSONDecoder().decode(JSONValue.self, from: json)
        #expect(val == .object(["key": .string("val")]))
    }

    // MARK: - 복합 구조 디코딩

    @Test("혼합 타입 배열 디코딩")
    func decodeMixedArray() throws {
        let json = #"[1, 2.5, true, "text", null]"#.data(using: .utf8)!
        let val = try JSONDecoder().decode(JSONValue.self, from: json)
        #expect(val == .array([.int(1), .number(2.5), .bool(true), .string("text"), .null]))
    }

    @Test("중첩 object 디코딩")
    func decodeNestedObject() throws {
        let json = #"{"outer":{"inner":42}}"#.data(using: .utf8)!
        let val = try JSONDecoder().decode(JSONValue.self, from: json)
        #expect(val == .object(["outer": .object(["inner": .int(42)])]))
    }

    @Test("object 내 배열 디코딩")
    func decodeObjectWithArray() throws {
        let json = #"{"items":[1,2,3]}"#.data(using: .utf8)!
        let val = try JSONDecoder().decode(JSONValue.self, from: json)
        #expect(val == .object(["items": .array([.int(1), .int(2), .int(3)])]))
    }

    // MARK: - Encoding

    @Test("Bool true 인코딩")
    func encodeBoolTrue() throws {
        let val = JSONValue.bool(true)
        let data = try JSONEncoder().encode(val)
        let str = String(data: data, encoding: .utf8)!
        #expect(str == "true")
    }

    @Test("Int 인코딩")
    func encodeInt() throws {
        let val = JSONValue.int(42)
        let data = try JSONEncoder().encode(val)
        let str = String(data: data, encoding: .utf8)!
        #expect(str == "42")
    }

    @Test("Double 인코딩")
    func encodeDouble() throws {
        let val = JSONValue.number(3.14)
        let data = try JSONEncoder().encode(val)
        let str = String(data: data, encoding: .utf8)!
        #expect(str.hasPrefix("3.14"))
    }

    @Test("null 인코딩")
    func encodeNull() throws {
        let val = JSONValue.null
        let data = try JSONEncoder().encode(val)
        let str = String(data: data, encoding: .utf8)!
        #expect(str == "null")
    }

    @Test("NaN은 null로 인코딩 (JSON 미지원)")
    func encodeNaN() throws {
        let val = JSONValue.number(Double.nan)
        let data = try JSONEncoder().encode(val)
        let str = String(data: data, encoding: .utf8)!
        #expect(str == "null")
    }

    @Test("Infinity는 null로 인코딩 (JSON 미지원)")
    func encodeInfinity() throws {
        let val = JSONValue.number(Double.infinity)
        let data = try JSONEncoder().encode(val)
        let str = String(data: data, encoding: .utf8)!
        #expect(str == "null")
    }

    // MARK: - Round-trip

    @Test("Int round-trip: encode → decode 동등성")
    func roundTripInt() throws {
        let original = JSONValue.int(12345)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
        #expect(decoded == original)
    }

    @Test("Double round-trip: encode → decode 동등성")
    func roundTripDouble() throws {
        let original = JSONValue.number(3.14159)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
        #expect(decoded == original)
    }

    @Test("String round-trip: encode → decode 동등성")
    func roundTripString() throws {
        let original = JSONValue.string("hello world")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
        #expect(decoded == original)
    }

    @Test("Bool round-trip: encode → decode 동등성")
    func roundTripBool() throws {
        for b in [true, false] {
            let original = JSONValue.bool(b)
            let data = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
            #expect(decoded == original)
        }
    }

    @Test("null round-trip: encode → decode 동등성")
    func roundTripNull() throws {
        let original = JSONValue.null
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
        #expect(decoded == original)
    }

    @Test("Array round-trip: encode → decode 동등성")
    func roundTripArray() throws {
        let original = JSONValue.array([.int(1), .string("a"), .bool(true), .null])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
        #expect(decoded == original)
    }

    @Test("Object round-trip: encode → decode 동등성")
    func roundTripObject() throws {
        let original = JSONValue.object(["x": .int(1), "y": .string("z"), "flag": .bool(false)])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
        #expect(decoded == original)
    }

    @Test("중첩 구조 round-trip: encode → decode 동등성")
    func roundTripNested() throws {
        let original = JSONValue.object([
            "list": .array([.int(1), .int(2)]),
            "meta": .object(["name": .string("test"), "active": .bool(true)])
        ])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
        #expect(decoded == original)
    }

    // MARK: - 디코딩 순서 검증 (Bool이 Int보다 먼저)

    @Test("true/false는 .bool로 디코딩 — .int(1)/.int(0)이 되어서는 안 됨")
    func boolDecodedBeforeInt() throws {
        let jsonTrue = #"true"#.data(using: .utf8)!
        let jsonFalse = #"false"#.data(using: .utf8)!
        let trueVal = try JSONDecoder().decode(JSONValue.self, from: jsonTrue)
        let falseVal = try JSONDecoder().decode(JSONValue.self, from: jsonFalse)
        #expect(trueVal == .bool(true))
        #expect(falseVal == .bool(false))
        // .int가 아님을 명시적 검증
        #expect(trueVal != .int(1))
        #expect(falseVal != .int(0))
    }

    @Test("정수 0과 1은 .bool이 아닌 .int로 디코딩")
    func intNotDecodedAsBool() throws {
        let json0 = #"0"#.data(using: .utf8)!
        let json1 = #"1"#.data(using: .utf8)!
        let val0 = try JSONDecoder().decode(JSONValue.self, from: json0)
        let val1 = try JSONDecoder().decode(JSONValue.self, from: json1)
        #expect(val0 == .int(0))
        #expect(val1 == .int(1))
        // .bool이 아님을 명시적 검증
        #expect(val0 != .bool(false))
        #expect(val1 != .bool(true))
    }
}
