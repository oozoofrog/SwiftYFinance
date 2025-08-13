import Foundation

extension YFSession {
    // MARK: - User-Agent 로테이션 메서드들 (YFBrowserImpersonator 활용)
    
    /// 현재 User-Agent 반환
    internal func getCurrentUserAgent() -> String {
        return browserImpersonator.getCurrentUserAgent()
    }
    
    /// User-Agent 로테이션 (탐지 방지)
    public func rotateUserAgent() {
        browserImpersonator.rotateUserAgent()
    }
    
    /// 랜덤 User-Agent 선택
    public func randomizeUserAgent() {
        browserImpersonator.randomizeUserAgent()
    }
}