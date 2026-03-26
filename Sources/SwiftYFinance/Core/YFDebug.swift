import Foundation

/// 전역 디버그 설정
nonisolated(unsafe) internal var _globalDebugEnabled: Bool = false

/// 전역 디버그 모드 설정
/// - Parameter enabled: 디버그 모드 활성화 여부
internal func setGlobalDebugEnabled(_ enabled: Bool) {
    _globalDebugEnabled = enabled
}

/// 조건부 디버그 출력 함수 (하위 호환성 유지)
///
/// 전역 디버그 설정이 활성화된 경우에만 메시지를 출력합니다.
/// 신규 코드는 YFLogger를 직접 사용하세요.
///
/// - Parameter message: 출력할 디버그 메시지
@inline(__always)
internal func DebugPrint(_ message: String) {
    if _globalDebugEnabled {
        YFLogger.service.debug(message)
    }
}
