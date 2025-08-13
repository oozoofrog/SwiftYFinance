import Foundation

extension YFSession {
    // MARK: - User-Agent 로테이션 메서드들
    
    /// 현재 User-Agent 반환
    internal func getCurrentUserAgent() -> String {
        return Self.chromeUserAgents[currentUserAgentIndex]
    }
    
    /// User-Agent 로테이션 (탐지 방지)
    public func rotateUserAgent() {
        currentUserAgentIndex = (currentUserAgentIndex + 1) % Self.chromeUserAgents.count
    }
    
    /// 랜덤 User-Agent 선택
    public func randomizeUserAgent() {
        currentUserAgentIndex = Int.random(in: 0..<Self.chromeUserAgents.count)
    }
}