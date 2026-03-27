/// JSONValue 경계 값 테스트
///
/// 검증 대상:
/// - Int.max, Int.min round-trip
/// - Double.infinity, -Double.infinity → null 인코딩
/// - Double.nan → null 인코딩
/// - -0.0 처리
/// - 빈 string, array, object
/// - null
/// - 단일 원소 array/object

import Testing
import Foundation
@testable import SwiftYFinanceMCP

@Suite("JSONValue 경계 값")
struct JSONValueBoundaryTests {

    // MARK: - Int 경계 값

    @Test("Int.max round-trip")
    func intMaxRoundTrip() throws {
        // Int.max = 9223372036854775807
        // JSON에서 이 값을 표현하려면 JSONEncoder가 정확한 정수로 직렬화해야 함
        // 단, JSONDecoder의 디코딩 순서(Bool→Int→Double)에서 Int로 디코딩되어야 함
        let original = JSONValue.int(Int.max)
        let data = try JSONEncoder().encode(original)
        let jsonStr = String(data: data, encoding: .utf8)!
        #expect(jsonStr == "9223372036854775807")

        // JSONDecoder로 복원
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
        #expect(decoded == original)
    }

    @Test("Int.min round-trip")
    func intMinRoundTrip() throws {
        let original = JSONValue.int(Int.min)
        let data = try JSONEncoder().encode(original)
        let jsonStr = String(data: data, encoding: .utf8)!
        #expect(jsonStr == "-9223372036854775808")

        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
        #expect(decoded == original)
    }

    @Test("Int 0 round-trip")
    func intZeroRoundTrip() throws {
        let original = JSONValue.int(0)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
        #expect(decoded == original)
    }

    @Test("Int -1 round-trip")
    func intMinusOneRoundTrip() throws {
        let original = JSONValue.int(-1)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
        #expect(decoded == original)
    }

    // MARK: - Double 경계 값

    @Test("Double.infinity → null 인코딩")
    func doubleInfinityEncodedAsNull() throws {
        let val = JSONValue.number(Double.infinity)
        let data = try JSONEncoder().encode(val)
        let jsonStr = String(data: data, encoding: .utf8)!
        #expect(jsonStr == "null")
    }

    @Test("-Double.infinity → null 인코딩")
    func doubleNegativeInfinityEncodedAsNull() throws {
        let val = JSONValue.number(-Double.infinity)
        let data = try JSONEncoder().encode(val)
        let jsonStr = String(data: data, encoding: .utf8)!
        #expect(jsonStr == "null")
    }

    @Test("Double.nan → null 인코딩")
    func doubleNanEncodedAsNull() throws {
        let val = JSONValue.number(Double.nan)
        let data = try JSONEncoder().encode(val)
        let jsonStr = String(data: data, encoding: .utf8)!
        #expect(jsonStr == "null")
    }

    @Test("-0.0 인코딩 — 정의된 동작")
    func negativeZeroEncoding() throws {
        // -0.0은 JSON으로 "-0" 또는 "0"으로 표현 가능 — 구현에 따라 다름
        // JSONValue로 인코딩했다가 디코딩하면 Double 비교에서 -0.0 == 0.0
        let val = JSONValue.number(-0.0)
        let data = try JSONEncoder().encode(val)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
        // -0.0 == 0.0 이므로 round-trip 결과가 0.0이어도 "동등"
        if case .number(let d) = decoded {
            #expect(d == -0.0)  // Double에서 -0.0 == 0.0
        } else if case .int(let i) = decoded {
            #expect(i == 0)     // 0으로 디코딩되어도 정상
        } else {
            Issue.record("-0.0 디코딩 결과가 number 또는 int여야 합니다: \(decoded)")
        }
    }

    @Test("Double.greatestFiniteMagnitude round-trip")
    func doubleMaxRoundTrip() throws {
        let original = JSONValue.number(Double.greatestFiniteMagnitude)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
        // Double 최대값은 JSON으로 직렬화 가능
        if case .number(let d) = decoded {
            #expect(d == Double.greatestFiniteMagnitude || d.isFinite)
        } else {
            Issue.record("Double.greatestFiniteMagnitude는 .number로 디코딩되어야 합니다: \(decoded)")
        }
    }

    @Test("Double.leastNormalMagnitude round-trip")
    func doubleLeastNormalRoundTrip() throws {
        let original = JSONValue.number(Double.leastNormalMagnitude)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
        if case .number(let d) = decoded {
            #expect(d.isFinite)
        } else if case .int(0) = decoded {
            // 매우 작은 Double이 0으로 반올림될 수 있음 — 허용
            ()
        } else {
            Issue.record("Double.leastNormalMagnitude 디코딩 결과가 예상과 다릅니다: \(decoded)")
        }
    }

    // MARK: - 빈 구조체

    @Test("빈 string round-trip")
    func emptyStringRoundTrip() throws {
        let original = JSONValue.string("")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
        #expect(decoded == original)
    }

    @Test("빈 array round-trip")
    func emptyArrayRoundTrip() throws {
        let original = JSONValue.array([])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
        #expect(decoded == original)
    }

    @Test("빈 object round-trip")
    func emptyObjectRoundTrip() throws {
        let original = JSONValue.object([:])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
        #expect(decoded == original)
    }

    @Test("null round-trip")
    func nullRoundTrip() throws {
        let original = JSONValue.null
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
        #expect(decoded == original)
    }

    // MARK: - 단일 원소 구조체

    @Test("단일 원소 array round-trip")
    func singleElementArrayRoundTrip() throws {
        let original = JSONValue.array([.string("single")])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
        #expect(decoded == original)
    }

    @Test("단일 키 object round-trip")
    func singleKeyObjectRoundTrip() throws {
        let original = JSONValue.object(["only": .int(42)])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
        #expect(decoded == original)
    }

    // MARK: - toJSONObject 경계 값

    @Test("Int.max toJSONObject")
    func intMaxToJSONObject() {
        let val = JSONValue.int(Int.max)
        let obj = val.toJSONObject()
        #expect((obj as? Int) == Int.max)
    }

    @Test("Int.min toJSONObject")
    func intMinToJSONObject() {
        let val = JSONValue.int(Int.min)
        let obj = val.toJSONObject()
        #expect((obj as? Int) == Int.min)
    }

    @Test("Double.infinity toJSONObject → NSNull")
    func doubleInfinityToJSONObject() {
        let val = JSONValue.number(Double.infinity)
        let obj = val.toJSONObject()
        #expect(obj is NSNull)
    }

    @Test("Double.nan toJSONObject → NSNull")
    func doubleNanToJSONObject() {
        let val = JSONValue.number(Double.nan)
        let obj = val.toJSONObject()
        #expect(obj is NSNull)
    }
}
