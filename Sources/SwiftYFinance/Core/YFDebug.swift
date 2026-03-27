import Foundation

/// 전역 디버그 모드 설정 (하위 호환성 유지용 no-op)
///
/// OSLog는 런타임 플래그 없이 OS 수준에서 로그 레벨을 관리합니다.
/// 이 함수는 하위 호환성을 위해 유지되지만 더 이상 동작을 변경하지 않습니다.
/// - Parameter enabled: 무시됨 (OSLog가 자체적으로 레벨 관리)
internal func setGlobalDebugEnabled(_ enabled: Bool) {
    // OSLog는 debug 레벨 메시지를 OS 수준에서 필터링합니다.
    // 전역 변수 없이도 actor isolation 없이 안전하게 동작합니다.
}

/// 조건부 디버그 출력 함수 (하위 호환성 유지)
///
/// OSLog의 debug 레벨을 사용하여 구조화된 로깅을 제공합니다.
/// debug 레벨은 개발 환경에서만 표시되며 프로덕션 릴리즈에서는 자동으로 필터링됩니다.
/// 신규 코드는 YFLogger를 직접 사용하세요.
///
/// - Parameter message: 출력할 디버그 메시지
@inline(__always)
internal func DebugPrint(_ message: String) {
    YFLogger.service.debug(message)
}
