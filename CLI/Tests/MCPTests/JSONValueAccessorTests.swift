/// JSONValue 편의 접근자 단위 테스트
///
/// 검증 대상:
/// 1. 6개 편의 접근자 (stringValue, intValue, doubleValue, boolValue, arrayValue, objectValue)
/// 2. 타입 불일치 시 nil 반환 (throws 아님)
/// 3. String 키 subscript
/// 4. Int 인덱스 subscript

import Testing
import Foundation
@testable import SwiftYFinanceMCP

@Suite("JSONValue 편의 접근자")
struct JSONValueAccessorTests {

    // MARK: - stringValue

    @Test(".string(\"hello\").stringValue == \"hello\"")
    func stringValueMatchesCase() {
        #expect(JSONValue.string("hello").stringValue == "hello")
    }

    @Test("stringValue — 타입 불일치 시 nil 반환")
    func stringValueTypesMismatch() {
        #expect(JSONValue.int(42).stringValue == nil)
        #expect(JSONValue.bool(true).stringValue == nil)
        #expect(JSONValue.number(1.5).stringValue == nil)
        #expect(JSONValue.null.stringValue == nil)
        #expect(JSONValue.array([]).stringValue == nil)
        #expect(JSONValue.object([:]).stringValue == nil)
    }

    // MARK: - intValue

    @Test(".int(42).intValue == 42")
    func intValueMatchesCase() {
        #expect(JSONValue.int(42).intValue == 42)
    }

    @Test("intValue — 타입 불일치 시 nil 반환")
    func intValueTypesMismatch() {
        #expect(JSONValue.string("42").intValue == nil)
        #expect(JSONValue.bool(true).intValue == nil)
        #expect(JSONValue.number(42.0).intValue == nil)
        #expect(JSONValue.null.intValue == nil)
    }

    // MARK: - doubleValue

    @Test(".number(3.14).doubleValue == 3.14")
    func doubleValueMatchesCase() {
        #expect(JSONValue.number(3.14).doubleValue == 3.14)
    }

    @Test("doubleValue — .int case는 nil 반환 (별도 case)")
    func doubleValueDoesNotMatchInt() {
        // .int와 .number는 별도 case — intValue로 접근해야 함
        #expect(JSONValue.int(42).doubleValue == nil)
    }

    @Test("doubleValue — 타입 불일치 시 nil 반환")
    func doubleValueTypesMismatch() {
        #expect(JSONValue.string("3.14").doubleValue == nil)
        #expect(JSONValue.bool(false).doubleValue == nil)
        #expect(JSONValue.null.doubleValue == nil)
    }

    // MARK: - boolValue

    @Test(".bool(true).boolValue == true")
    func boolValueTrue() {
        #expect(JSONValue.bool(true).boolValue == true)
    }

    @Test(".bool(false).boolValue == false")
    func boolValueFalse() {
        #expect(JSONValue.bool(false).boolValue == false)
    }

    @Test("boolValue — 타입 불일치 시 nil 반환")
    func boolValueTypesMismatch() {
        #expect(JSONValue.int(1).boolValue == nil)
        #expect(JSONValue.string("true").boolValue == nil)
        #expect(JSONValue.null.boolValue == nil)
    }

    // MARK: - arrayValue

    @Test(".array([.int(1)]).arrayValue — 배열 반환")
    func arrayValueMatchesCase() {
        let arr = JSONValue.array([.int(1), .string("a")])
        #expect(arr.arrayValue == [.int(1), .string("a")])
    }

    @Test("빈 배열 arrayValue 반환")
    func arrayValueEmpty() {
        let arr = JSONValue.array([])
        #expect(arr.arrayValue == [])
    }

    @Test("arrayValue — 타입 불일치 시 nil 반환")
    func arrayValueTypesMismatch() {
        #expect(JSONValue.object([:]).arrayValue == nil)
        #expect(JSONValue.string("[]").arrayValue == nil)
        #expect(JSONValue.null.arrayValue == nil)
    }

    // MARK: - objectValue

    @Test(".object([\"k\": .bool(true)]).objectValue — 딕셔너리 반환")
    func objectValueMatchesCase() {
        let obj = JSONValue.object(["k": .bool(true)])
        #expect(obj.objectValue?["k"] == .bool(true))
    }

    @Test("빈 object objectValue 반환")
    func objectValueEmpty() {
        let obj = JSONValue.object([:])
        #expect(obj.objectValue == [:])
    }

    @Test("objectValue — 타입 불일치 시 nil 반환")
    func objectValueTypesMismatch() {
        #expect(JSONValue.array([]).objectValue == nil)
        #expect(JSONValue.string("{}").objectValue == nil)
        #expect(JSONValue.null.objectValue == nil)
    }

    // MARK: - String 키 subscript

    @Test("object subscript[key] — 키 존재 시 값 반환")
    func objectSubscriptKeyExists() {
        let obj = JSONValue.object(["name": .string("Apple"), "price": .number(150.5)])
        #expect(obj["name"] == .string("Apple"))
        #expect(obj["price"] == .number(150.5))
    }

    @Test("object subscript[key] — 키 없으면 nil")
    func objectSubscriptKeyMissing() {
        let obj = JSONValue.object(["name": .string("Apple")])
        #expect(obj["nonexistent"] == nil)
    }

    @Test("object subscript — .object가 아닌 case에서 nil")
    func objectSubscriptNonObject() {
        #expect(JSONValue.array([.int(1)])["key"] == nil)
        #expect(JSONValue.string("hello")["key"] == nil)
        #expect(JSONValue.null["key"] == nil)
    }

    @Test("중첩 object 체이닝 subscript")
    func objectSubscriptChaining() {
        let val = JSONValue.object([
            "outer": .object(["inner": .bool(true)])
        ])
        #expect(val["outer"]?["inner"]?.boolValue == true)
    }

    // MARK: - Int 인덱스 subscript

    @Test("array subscript[index] — 유효 인덱스에서 값 반환")
    func arraySubscriptValidIndex() {
        let arr = JSONValue.array([.int(10), .string("b"), .bool(true)])
        #expect(arr[0] == .int(10))
        #expect(arr[1] == .string("b"))
        #expect(arr[2] == .bool(true))
    }

    @Test("array subscript[index] — 범위 초과 시 nil")
    func arraySubscriptOutOfRange() {
        let arr = JSONValue.array([.int(1)])
        #expect(arr[1] == nil)
        #expect(arr[-1] == nil)
        #expect(arr[100] == nil)
    }

    @Test("array subscript — .array가 아닌 case에서 nil")
    func arraySubscriptNonArray() {
        #expect(JSONValue.object(["a": .int(1)])[0] == nil)
        #expect(JSONValue.string("hello")[0] == nil)
        #expect(JSONValue.null[0] == nil)
    }

    @Test("빈 배열 subscript는 항상 nil")
    func arraySubscriptEmptyArray() {
        let arr = JSONValue.array([])
        #expect(arr[0] == nil)
    }

    // MARK: - 복합 접근 패턴

    @Test("object 내 bool 값을 subscript + boolValue로 접근")
    func combinedObjectBoolAccess() {
        let obj = JSONValue.object(["k": .bool(true)])
        #expect(obj["k"]?.boolValue == true)
    }

    @Test("array 내 object를 subscript로 접근")
    func combinedArrayObjectAccess() {
        let arr = JSONValue.array([.object(["id": .int(1)])])
        #expect(arr[0]?["id"]?.intValue == 1)
    }
}
