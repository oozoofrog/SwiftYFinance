import Foundation

/// Yahoo Finance의 인증 쿠키를 관리하는 클래스
/// 
/// Yahoo Finance API에서 요구하는 A3 쿠키 및 기타 인증 쿠키들을 추출, 저장, 검증하는 기능을 제공합니다.
/// Python yfinance의 쿠키 관리 로직을 Swift로 포팅하였습니다.
///
/// ## 주요 기능
/// - **A3 쿠키 관리**: Yahoo Finance 인증에 필수적인 A3 쿠키 추출 및 검증
/// - **쿠키 유효성 검증**: 만료 시간 기반 쿠키 유효성 확인
/// - **메모리 캐싱**: 성능 최적화를 위한 쿠키 캐싱
/// - **동시성 안전**: DispatchQueue를 활용한 쓰레드 안전 보장
///
/// ## 사용 예시
/// ```swift
/// let cookieManager = YFCookieManager()
/// 
/// // A3 쿠키 확인
/// if cookieManager.hasValidA3Cookie() {
///     print("인증 쿠키 사용 가능")
/// } else {
///     print("새로운 인증 필요")
/// }
/// 
/// // 만료된 쿠키 정리
/// let removedCount = cookieManager.cleanupExpiredCookies()
/// print("정리된 쿠키 수: \(removedCount)")
/// ```
///
/// - SeeAlso: yfinance-reference/yfinance/data.py:_save_cookie_curlCffi()
public class YFCookieManager {
    /// 쿠키 저장소
    /// 
    /// 시스템의 HTTP 쿠키 저장소에 접근하여 쿠키를 관리합니다.
    private let cookieStorage: HTTPCookieStorage
    
    /// 메모리 캐시된 쿠키들
    /// 
    /// 성능 최적화를 위해 자주 사용되는 쿠키들을 메모리에 캐시합니다.
    private var cachedCookies: [String: HTTPCookie] = [:]
    
    /// 동시성 제어를 위한 큐
    /// 
    /// 쓰레드 안전성을 보장하기 위해 concurrent 큐를 사용합니다.
    private let queue = DispatchQueue(label: "YFCookieManager", attributes: .concurrent)
    
    /// YFCookieManager 초기화
    /// 
    /// 지정된 쿠키 저장소를 사용하여 쿠키 관리자를 초기화합니다.
    /// 
    /// - Parameter cookieStorage: 사용할 쿠키 저장소 (기본값: 시스템 공유 저장소)
    public init(cookieStorage: HTTPCookieStorage = HTTPCookieStorage.shared) {
        self.cookieStorage = cookieStorage
    }
    
    // MARK: - A3 쿠키 추출
    
    /// Yahoo 도메인에서 A3 쿠키를 추출합니다
    /// 
    /// Yahoo Finance 인증에 필요한 A3 쿠키를 시스템 쿠키 저장소에서 찾아 반환합니다.
    /// A3 쿠키는 Yahoo Finance API의 많은 기능에서 요구하는 인증 쿠키입니다.
    /// 
    /// - Returns: 유효한 A3 쿠키, 없으면 nil
    /// - SeeAlso: yfinance-reference/yfinance/data.py cookies[domain]['/']['A3'] 패턴
    public func extractA3Cookie() -> HTTPCookie? {
        return queue.sync {
            guard let cookies = cookieStorage.cookies else { return nil }
            
            // yahoo 도메인과 A3 이름을 가진 쿠키 찾기
            for cookie in cookies {
                if cookie.domain.contains("yahoo") && cookie.name == "A3" {
                    return cookie
                }
            }
            
            return nil
        }
    }
    
    /// 특정 도메인의 모든 yahoo 관련 쿠키 추출
    /// - Parameter domain: 대상 도메인 (예: "finance.yahoo.com")
    /// - Returns: Yahoo 관련 쿠키 배열
    public func extractYahooCookies(for domain: String) -> [HTTPCookie] {
        return queue.sync {
            guard let cookies = cookieStorage.cookies else { return [] }
            
            return cookies.filter { cookie in
                cookie.domain.contains("yahoo") && 
                (cookie.domain == domain || cookie.domain.hasSuffix(domain))
            }
        }
    }
    
    /// consent 쿠키 제외한 finance 쿠키만 필터링
    /// - SeeAlso: yfinance-reference/yfinance/data.py consent 쿠키 제외 로직
    /// - Returns: Finance 관련 쿠키 (consent 제외)
    public func filterFinanceCookies() -> [HTTPCookie] {
        return queue.sync {
            guard let cookies = cookieStorage.cookies else { return [] }
            
            return cookies.filter { cookie in
                cookie.domain.contains("yahoo") && 
                !cookie.domain.contains("consent") &&
                (cookie.domain.contains("finance") || cookie.name == "A3")
            }
        }
    }
    
    // MARK: - 쿠키 유효성 검증
    
    /// 쿠키 유효성 검증 (만료시간 체크)
    /// - SeeAlso: yfinance-reference/yfinance/data.py expired 체크
    /// - Parameter cookie: 검증할 쿠키
    /// - Returns: 유효한 쿠키인지 여부
    public func validateCookie(_ cookie: HTTPCookie) -> Bool {
        // 만료일이 없는 쿠키는 세션 쿠키이므로 유효
        guard let expiresDate = cookie.expiresDate else {
            return true
        }
        
        // 현재 시간과 비교
        return expiresDate > Date()
    }
    
    /// A3 쿠키의 유효성 검증
    /// - Returns: 유효한 A3 쿠키가 있는지 여부
    public func hasValidA3Cookie() -> Bool {
        guard let a3Cookie = extractA3Cookie() else { return false }
        return validateCookie(a3Cookie)
    }
    
    /// 만료된 쿠키들 정리
    /// - Returns: 정리된 쿠키 개수
    @discardableResult
    public func cleanupExpiredCookies() -> Int {
        return queue.sync(flags: .barrier) {
            guard let cookies = cookieStorage.cookies else { return 0 }
            
            var removedCount = 0
            
            for cookie in cookies {
                if cookie.domain.contains("yahoo") && !validateCookie(cookie) {
                    cookieStorage.deleteCookie(cookie)
                    removedCount += 1
                }
            }
            
            return removedCount
        }
    }
    
    // MARK: - 메모리 기반 쿠키 관리
    
    /// 쿠키를 메모리 캐시에 저장
    /// - Parameters:
    ///   - cookie: 저장할 쿠키
    ///   - strategy: 쿠키 획득 전략 (basic/csrf)
    public func cacheCookie(_ cookie: HTTPCookie, for strategy: CookieStrategy) {
        queue.async(flags: .barrier) {
            let key = "\(strategy):\(cookie.domain):\(cookie.name)"
            self.cachedCookies[key] = cookie
        }
    }
    
    /// 메모리 캐시에서 쿠키 조회
    /// - Parameters:
    ///   - strategy: 쿠키 전략
    ///   - domain: 도메인
    ///   - name: 쿠키 이름
    /// - Returns: 캐시된 쿠키 정보 (쿠키와 나이)
    public func getCachedCookie(strategy: CookieStrategy, domain: String, name: String) -> (cookie: HTTPCookie, age: TimeInterval)? {
        return queue.sync {
            let key = "\(strategy):\(domain):\(name)"
            guard let cookie = cachedCookies[key] else { return nil }
            
            // 쿠키 나이 계산 (현재는 단순히 0 반환, 필요시 확장)
            let age: TimeInterval = 0
            
            return (cookie: cookie, age: age)
        }
    }
    
    /// 특정 전략의 모든 캐시된 쿠키 조회
    /// - Parameter strategy: 쿠키 전략
    /// - Returns: 전략별 쿠키 배열
    public func getCachedCookies(for strategy: CookieStrategy) -> [HTTPCookie] {
        return queue.sync {
            let strategyPrefix = "\(strategy):"
            
            return cachedCookies.compactMap { key, cookie in
                key.hasPrefix(strategyPrefix) ? cookie : nil
            }
        }
    }
    
    /// 메모리 캐시 초기화
    /// - Parameter strategy: 특정 전략만 초기화 (nil이면 전체 초기화)
    public func clearCache(for strategy: CookieStrategy? = nil) {
        queue.async(flags: .barrier) {
            if let strategy = strategy {
                let strategyPrefix = "\(strategy):"
                self.cachedCookies = self.cachedCookies.filter { key, _ in
                    !key.hasPrefix(strategyPrefix)
                }
            } else {
                self.cachedCookies.removeAll()
            }
        }
    }
    
    // MARK: - HTTPCookieStorage 연동
    
    /// A3 쿠키를 HTTPCookieStorage에 설정
    /// - Parameter cookie: 설정할 A3 쿠키
    public func setA3Cookie(_ cookie: HTTPCookie) {
        queue.async(flags: .barrier) {
            self.cookieStorage.setCookie(cookie)
            self.cacheCookie(cookie, for: .csrf)
        }
    }
    
    /// 쿠키 상태 정보 반환
    /// - Returns: 쿠키 관리 상태 정보
    public func getCookieStatus() -> CookieStatus {
        return queue.sync {
            let allCookies = cookieStorage.cookies ?? []
            let yahooCookies = allCookies.filter { $0.domain.contains("yahoo") }
            let validCookies = yahooCookies.filter { validateCookie($0) }
            let a3Cookie = extractA3Cookie()
            
            return CookieStatus(
                totalCookies: allCookies.count,
                yahooCookies: yahooCookies.count,
                validCookies: validCookies.count,
                hasA3Cookie: a3Cookie != nil,
                a3CookieValid: a3Cookie != nil ? validateCookie(a3Cookie!) : false,
                cachedCookies: cachedCookies.count
            )
        }
    }
}

/// 쿠키 관리 상태 정보
/// 
/// 현재 쿠키 저장소와 캐시의 상태를 나타내는 구조체입니다.
/// 디버깅과 모니터링에 유용한 정보를 제공합니다.
public struct CookieStatus {
    /// 전체 쿠키 수
    public let totalCookies: Int
    
    /// Yahoo 관련 쿠키 수
    public let yahooCookies: Int
    
    /// 유효한 쿠키 수 (만료되지 않음)
    public let validCookies: Int
    
    /// A3 쿠키 존재 여부
    public let hasA3Cookie: Bool
    
    /// A3 쿠키의 유효성
    public let a3CookieValid: Bool
    
    /// 메모리에 캐시된 쿠키 수
    public let cachedCookies: Int
}