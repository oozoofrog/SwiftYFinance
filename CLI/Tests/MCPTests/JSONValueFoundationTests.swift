/// JSONValue Foundation 양방향 변환 단위 테스트
///
/// 검증 대상:
/// 1. JSONValue.from(jsonObject:) — JSONSerialization 출력 → JSONValue
/// 2. JSONValue.toJSONObject() — JSONValue → JSONSerialization 입력
/// 3. NSNumber Bool/Int/Double 구분
/// 4. round-trip: JSONSerialization → JSONValue → toJSONObject() → JSONSerialization

import Testing
import Foundation
@testable import SwiftYFinanceMCP

@Suite("JSONValue Foundation 변환")
struct JSONValueFoundationTests {

    // MARK: - from(jsonObject:) 기본 타입 변환

    @Test("NSNull → .null 변환")
    func fromNSNull() throws {
        let result = try JSONValue.from(jsonObject: NSNull())
        #expect(result == .null)
    }

    @Test("NSNumber(bool: true) → .bool(true) 변환")
    func fromNSNumberBoolTrue() throws {
        let num = NSNumber(value: true)
        let result = try JSONValue.from(jsonObject: num)
        #expect(result == .bool(true))
    }

    @Test("NSNumber(bool: false) → .bool(false) 변환")
    func fromNSNumberBoolFalse() throws {
        let num = NSNumber(value: false)
        let result = try JSONValue.from(jsonObject: num)
        #expect(result == .bool(false))
    }

    @Test("NSNumber(int: 42) → .int(42) 변환")
    func fromNSNumberInt() throws {
        let num = NSNumber(value: 42)
        let result = try JSONValue.from(jsonObject: num)
        #expect(result == .int(42))
    }

    @Test("NSNumber(double: 3.14) → .number(3.14) 변환")
    func fromNSNumberDouble() throws {
        let num = NSNumber(value: 3.14)
        let result = try JSONValue.from(jsonObject: num)
        #expect(result == .number(3.14))
    }

    @Test("NSString → .string 변환")
    func fromNSString() throws {
        let result = try JSONValue.from(jsonObject: "hello" as NSString)
        #expect(result == .string("hello"))
    }

    @Test("Swift String → .string 변환")
    func fromSwiftString() throws {
        let result = try JSONValue.from(jsonObject: "world")
        #expect(result == .string("world"))
    }

    @Test("NSArray → .array 변환")
    func fromNSArray() throws {
        let arr: [Any] = [NSNumber(value: 1), "two", NSNull()]
        let result = try JSONValue.from(jsonObject: arr)
        #expect(result == .array([.int(1), .string("two"), .null]))
    }

    @Test("NSDictionary → .object 변환")
    func fromNSDictionary() throws {
        let dict: [String: Any] = ["key": "value", "num": NSNumber(value: 42)]
        let result = try JSONValue.from(jsonObject: dict)
        guard case .object(let obj) = result else {
            Issue.record("object 여야 합니다")
            return
        }
        #expect(obj["key"] == .string("value"))
        #expect(obj["num"] == .int(42))
    }

    // MARK: - NSNumber Bool/Int/Double 구분 (핵심 로직)

    @Test("NSNumber(bool) 구분 — CFBooleanGetTypeID 사용")
    func nsNumberBoolVsInt() throws {
        // JSONSerialization이 true/false를 반환하는 NSNumber와
        // 정수 1/0을 반환하는 NSNumber를 구분해야 함
        let boolTrue = NSNumber(value: true)
        let boolFalse = NSNumber(value: false)
        let intOne = NSNumber(value: 1)
        let intZero = NSNumber(value: 0)

        let fromBoolTrue = try JSONValue.from(jsonObject: boolTrue)
        let fromBoolFalse = try JSONValue.from(jsonObject: boolFalse)
        let fromIntOne = try JSONValue.from(jsonObject: intOne)
        let fromIntZero = try JSONValue.from(jsonObject: intZero)

        #expect(fromBoolTrue == .bool(true))
        #expect(fromBoolFalse == .bool(false))
        #expect(fromIntOne == .int(1))
        #expect(fromIntZero == .int(0))
    }

    @Test("JSONSerialization이 파싱한 true는 .bool(true)로 변환")
    func jsonSerializationBoolToBool() throws {
        let json = #"{"flag":true,"count":1}"#.data(using: .utf8)!
        let obj = try JSONSerialization.jsonObject(with: json) as! [String: Any]

        let flagValue = try JSONValue.from(jsonObject: obj["flag"]!)
        let countValue = try JSONValue.from(jsonObject: obj["count"]!)

        #expect(flagValue == .bool(true))
        #expect(countValue == .int(1))
    }

    // MARK: - toJSONObject() 변환

    @Test(".null → NSNull")
    func toJSONObjectNull() {
        let result = JSONValue.null.toJSONObject()
        #expect(result is NSNull)
    }

    @Test(".bool(true) → true (JSONSerialization 호환)")
    func toJSONObjectBoolTrue() {
        let result = JSONValue.bool(true).toJSONObject()
        #expect((result as? Bool) == true)
    }

    @Test(".int(42) → 42 (JSONSerialization 호환)")
    func toJSONObjectInt() {
        let result = JSONValue.int(42).toJSONObject()
        #expect((result as? Int) == 42)
    }

    @Test(".number(3.14) → 3.14 (JSONSerialization 호환)")
    func toJSONObjectDouble() {
        let result = JSONValue.number(3.14).toJSONObject()
        #expect((result as? Double) == 3.14)
    }

    @Test(".string → String")
    func toJSONObjectString() {
        let result = JSONValue.string("hello").toJSONObject()
        #expect((result as? String) == "hello")
    }

    @Test(".array → [Any]")
    func toJSONObjectArray() {
        let result = JSONValue.array([.int(1), .string("a")]).toJSONObject()
        guard let arr = result as? [Any] else {
            Issue.record("[Any] 여야 합니다")
            return
        }
        #expect(arr.count == 2)
        #expect((arr[0] as? Int) == 1)
        #expect((arr[1] as? String) == "a")
    }

    @Test(".object → [String: Any]")
    func toJSONObjectDict() {
        let result = JSONValue.object(["k": .bool(false)]).toJSONObject()
        guard let dict = result as? [String: Any] else {
            Issue.record("[String: Any] 여야 합니다")
            return
        }
        #expect((dict["k"] as? Bool) == false)
    }

    @Test(".number(NaN) → NSNull (JSON 미지원)")
    func toJSONObjectNaN() {
        let result = JSONValue.number(Double.nan).toJSONObject()
        #expect(result is NSNull)
    }

    @Test(".number(Infinity) → NSNull (JSON 미지원)")
    func toJSONObjectInfinity() {
        let result = JSONValue.number(Double.infinity).toJSONObject()
        #expect(result is NSNull)
    }

    // MARK: - Round-trip: JSONSerialization → JSONValue → toJSONObject()

    @Test("단순 JSON round-trip — JSONSerialization 직렬화 동등성")
    func roundTripSimpleJSON() throws {
        let json = #"{"name":"Apple","price":150,"active":true,"ratio":0.95}"#
        let data = json.data(using: .utf8)!

        // JSONSerialization으로 파싱
        let serializationResult = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        // JSONValue 경유
        let jsonValue = try JSONValue.from(jsonObject: serializationResult)
        let backToAny = jsonValue.toJSONObject()

        // 재직렬화
        let reserializedDirect = try JSONSerialization.data(
            withJSONObject: serializationResult,
            options: [.sortedKeys]
        )
        let reserializedViaJSONValue = try JSONSerialization.data(
            withJSONObject: backToAny,
            options: [.sortedKeys]
        )

        #expect(reserializedDirect == reserializedViaJSONValue)
    }

    @Test("중첩 구조 round-trip")
    func roundTripNestedJSON() throws {
        let json = #"{"data":{"items":[1,2,3],"meta":{"total":3}}}"#
        let data = json.data(using: .utf8)!

        let serializationResult = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let jsonValue = try JSONValue.from(jsonObject: serializationResult)
        let backToAny = jsonValue.toJSONObject()

        let original = try JSONSerialization.data(withJSONObject: serializationResult, options: [.sortedKeys])
        let viaValue = try JSONSerialization.data(withJSONObject: backToAny, options: [.sortedKeys])

        #expect(original == viaValue)
    }

    @Test("JSONDecoder 경유 round-trip — JSONSerialization과 의미적 동등성")
    func roundTripViaJSONDecoder() throws {
        let json = #"{"symbol":"AAPL","price":150.5,"volume":1000000,"active":true}"#
        let data = json.data(using: .utf8)!

        // JSONDecoder 경유
        let decodedValue = try JSONDecoder().decode(JSONValue.self, from: data)
        let backToAny = decodedValue.toJSONObject()
        let reencoded = try JSONSerialization.data(withJSONObject: backToAny, options: [.sortedKeys])
        let reencodedStr = String(data: reencoded, encoding: .utf8)!

        // JSONSerialization 직접 경유
        let serObj = try JSONSerialization.jsonObject(with: data)
        let serDirect = try JSONSerialization.data(withJSONObject: serObj, options: [.sortedKeys])
        let serDirectStr = String(data: serDirect, encoding: .utf8)!

        #expect(reencodedStr == serDirectStr)
    }

    @Test("배열 JSON round-trip")
    func roundTripArrayJSON() throws {
        let json = #"[1,2.5,true,"hello",null]"#.data(using: .utf8)!
        let serializationResult = try JSONSerialization.jsonObject(with: json)
        let jsonValue = try JSONValue.from(jsonObject: serializationResult)
        let backToAny = jsonValue.toJSONObject()

        let original = try JSONSerialization.data(withJSONObject: serializationResult)
        let viaValue = try JSONSerialization.data(withJSONObject: backToAny)

        // 배열 순서와 타입이 보존되어야 함
        let originalStr = String(data: original, encoding: .utf8)!
        let viaValueStr = String(data: viaValue, encoding: .utf8)!
        #expect(originalStr == viaValueStr)
    }
}
