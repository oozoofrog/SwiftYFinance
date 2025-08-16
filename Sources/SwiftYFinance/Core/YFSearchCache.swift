import Foundation

/// 검색 결과 캐싱을 위한 내부 캐시 매니저
///
/// 분 단위의 TTL(Time To Live)을 사용하여 검색 결과를 메모리에 캐싱합니다.
/// 동일한 검색어에 대한 반복 요청을 최적화하고 Yahoo Finance API 호출을 줄입니다.
///
/// ## 캐싱 정책
/// - **TTL**: 1분 (60초)
/// - **최대 항목**: 100개
/// - **Thread-Safe**: DispatchQueue 기반 동기화
///
/// ## 사용 예시
/// ```swift
/// let cache = YFSearchCache()
/// 
/// // 캐시에서 검색
/// if let cached = cache.get(for: "Apple") {
///     return cached
/// }
/// 
/// // API 호출 후 캐시에 저장
/// let results = try await performAPISearch(query)
/// cache.set(results, for: "Apple")
/// ```
internal final class YFSearchCache: @unchecked Sendable {
    
    /// 캐시 항목 구조체
    private struct CacheItem {
        let results: [YFSearchResult]
        let timestamp: Date
        
        /// 캐시 항목이 만료되었는지 확인
        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > YFSearchCache.ttl
        }
    }
    
    /// TTL (Time To Live) - 1분
    private static let ttl: TimeInterval = 60.0
    
    /// 최대 캐시 항목 수
    private static let maxItems: Int = 100
    
    /// 캐시 저장소
    private var cache: [String: CacheItem] = [:]
    
    /// 동시성 제어를 위한 큐
    private let queue = DispatchQueue(label: "YFSearchCache", attributes: .concurrent)
    
    /// 싱글톤 인스턴스
    static let shared = YFSearchCache()
    
    /// 프라이빗 초기화 (싱글톤)
    private init() {}
    
    /// 캐시에서 검색 결과 조회
    /// - Parameter query: 검색 쿼리 문자열
    /// - Returns: 캐시된 검색 결과, 없거나 만료된 경우 nil
    func get(for query: String) -> [YFSearchResult]? {
        return queue.sync {
            let key = normalizeKey(query)
            guard let item = cache[key] else { return nil }
            
            if item.isExpired {
                cache.removeValue(forKey: key)
                return nil
            }
            
            return item.results
        }
    }
    
    /// 캐시에 검색 결과 저장
    /// - Parameters:
    ///   - results: 저장할 검색 결과
    ///   - query: 검색 쿼리 문자열
    func set(_ results: [YFSearchResult], for query: String) {
        queue.async(flags: .barrier) {
            let key = self.normalizeKey(query)
            let item = CacheItem(results: results, timestamp: Date())
            
            self.cache[key] = item
            
            // 최대 항목 수 초과 시 오래된 항목 제거
            if self.cache.count > Self.maxItems {
                self.removeOldestItems()
            }
        }
    }
    
    /// 만료된 캐시 항목들 정리
    /// - Returns: 정리된 항목 수
    @discardableResult
    func cleanupExpired() -> Int {
        return queue.sync(flags: .barrier) {
            let initialCount = cache.count
            cache = cache.filter { !$0.value.isExpired }
            return initialCount - cache.count
        }
    }
    
    /// 모든 캐시 항목 삭제
    func clearAll() {
        queue.async(flags: .barrier) {
            self.cache.removeAll()
        }
    }
    
    /// 캐시 상태 정보 반환
    /// - Returns: 캐시 통계 정보
    func getStats() -> CacheStats {
        return queue.sync {
            let expired = cache.values.filter { $0.isExpired }.count
            return CacheStats(
                totalItems: cache.count,
                expiredItems: expired,
                validItems: cache.count - expired,
                memoryUsage: estimateMemoryUsage()
            )
        }
    }
    
    // MARK: - Private Methods
    
    /// 검색 쿼리를 캐시 키로 정규화
    private func normalizeKey(_ query: String) -> String {
        return query.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
    }
    
    /// 가장 오래된 항목들 제거 (LRU 방식)
    private func removeOldestItems() {
        let sortedItems = cache.sorted { $0.value.timestamp < $1.value.timestamp }
        let itemsToRemove = sortedItems.prefix(cache.count - Self.maxItems + 10) // 10개 여유분
        
        for (key, _) in itemsToRemove {
            cache.removeValue(forKey: key)
        }
    }
    
    /// 메모리 사용량 추정 (바이트 단위)
    private func estimateMemoryUsage() -> Int {
        let baseSize = MemoryLayout<CacheItem>.size
        let stringSize = cache.keys.reduce(0) { $0 + $1.utf8.count }
        let resultsSize = cache.values.reduce(0) { total, item in
            total + item.results.count * MemoryLayout<YFSearchResult>.size
        }
        
        return cache.count * baseSize + stringSize + resultsSize
    }
}

/// 캐시 상태 정보
internal struct CacheStats {
    /// 전체 캐시 항목 수
    let totalItems: Int
    
    /// 만료된 항목 수
    let expiredItems: Int
    
    /// 유효한 항목 수
    let validItems: Int
    
    /// 추정 메모리 사용량 (바이트)
    let memoryUsage: Int
}