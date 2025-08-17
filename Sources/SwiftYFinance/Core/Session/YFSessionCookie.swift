import Foundation

extension YFSession {
    // MARK: - User-Agent 로테이션 메서드들 (YFBrowserImpersonator 활용)
    
    /// 현재 사용 중인 User-Agent 문자열 반환
    ///
    /// YFBrowserImpersonator에서 관리하는 현재 User-Agent를 반환합니다.
    /// Chrome 브라우저의 최신 버전을 모방합니다.
    ///
    /// - Returns: 현재 설정된 User-Agent 문자열
    nonisolated internal func getCurrentUserAgent() -> String {
        return browserImpersonator.getCurrentUserAgent()
    }
    
    /// User-Agent 로테이션 (탐지 방지)
    ///
    /// 다음 User-Agent로 순차적으로 전환하여 봇 탐지를 방지합니다.
    /// 여러 Chrome 버전과 운영체제 조합을 순환합니다.
    ///
    /// ## 사용 예시
    /// ```swift
    /// // 정기적으로 User-Agent 변경
    /// session.rotateUserAgent()
    /// ```
    nonisolated public func rotateUserAgent() {
        browserImpersonator.rotateUserAgent()
    }
    
    /// 랜덤 User-Agent 선택
    ///
    /// 사용 가능한 User-Agent 목록에서 무작위로 하나를 선택합니다.
    /// 예측하기 어려운 패턴으로 봇 탐지를 더욱 효과적으로 방지합니다.
    ///
    /// ## 사용 예시
    /// ```swift
    /// // 무작위 User-Agent로 변경
    /// session.randomizeUserAgent()
    /// ```
    nonisolated public func randomizeUserAgent() {
        browserImpersonator.randomizeUserAgent()
    }
}