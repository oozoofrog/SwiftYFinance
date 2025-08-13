import Foundation

/// 세션 상태를 관리하는 Actor (Thread-safe)
actor YFSessionState {
    
    // CSRF 인증 관련 상태
    var cookieStrategy: CookieStrategy = .basic
    var crumbToken: String?
    var isAuthenticated = false
    
    /// 쿠키 전략 전환
    func toggleCookieStrategy() {
        cookieStrategy = cookieStrategy == .basic ? .csrf : .basic
        crumbToken = nil
        isAuthenticated = false
    }
    
    /// 인증 상태 설정
    func setAuthenticated(_ authenticated: Bool) {
        isAuthenticated = authenticated
    }
    
    /// Crumb 토큰 설정
    func setCrumbToken(_ token: String?) {
        crumbToken = token
    }
    
    /// 현재 인증 상태 확인
    var isCSRFAuthenticated: Bool {
        return isAuthenticated && crumbToken != nil
    }
    
    /// 인증 상태 초기화
    func reset() {
        crumbToken = nil
        isAuthenticated = false
    }
}