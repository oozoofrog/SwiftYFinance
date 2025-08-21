import Foundation

/// 전역 디버그 설정
internal var _globalDebugEnabled: Bool = false

/// 전역 디버그 모드 설정
/// - Parameter enabled: 디버그 모드 활성화 여부
internal func setGlobalDebugEnabled(_ enabled: Bool) {
    _globalDebugEnabled = enabled
}

/// 조건부 디버그 출력 함수
/// 
/// 전역 디버그 설정이 활성화된 경우에만 메시지를 출력합니다.
/// 기존의 `if debugEnabled { print(...) }` 패턴을 대체합니다.
///
/// - Parameter message: 출력할 디버그 메시지
internal func DebugPrint(_ message: String) {
    if _globalDebugEnabled {
        print(message)
    }
}

/// 조건부 디버그 출력 함수 (클로저 버전)
/// 
/// 메시지 생성 비용이 큰 경우 사용합니다.
/// 디버그가 비활성화된 경우 클로저가 실행되지 않아 성능상 이점이 있습니다.
///
/// - Parameter messageProvider: 디버그 메시지를 생성하는 클로저
internal func DebugPrint(_ messageProvider: @autoclosure () -> String) {
    if _globalDebugEnabled {
        print(messageProvider())
    }
}