import Foundation

/// Yahoo Finance API metrics를 JSON 리소스에서 로딩하는 구조체
///
/// 재무제표 데이터 조회에 필요한 metrics 문자열들을 외부 JSON 파일에서 
/// 로딩하여 코드와 데이터를 분리합니다. 런타임 로딩으로 유연성을 제공하며,
/// metrics 변경 시 코드 수정 없이 JSON 파일만 업데이트하면 됩니다.
///
/// Sendable 프로토콜을 준수하여 concurrent 환경에서 안전하게 사용할 수 있습니다.
public struct YFMetricsLoader: Sendable {
    
    /// 재무제표 metrics 데이터 구조체
    public struct FundamentalsMetrics: Decodable, Sendable {
        /// 손익계산서 metrics
        public let incomeStatementMetrics: [String]
        /// 대차대조표 metrics  
        public let balanceSheetMetrics: [String]
        /// 현금흐름표 metrics
        public let cashFlowMetrics: [String]
        
        /// 모든 metrics를 하나의 배열로 결합
        public var allMetrics: [String] {
            return incomeStatementMetrics + balanceSheetMetrics + cashFlowMetrics
        }
    }
    
    /// 로딩된 metrics 캐시 (한 번 로딩 후 재사용)
    private static let _cachedMetrics: FundamentalsMetrics? = {
        do {
            return try loadMetricsFromBundle()
        } catch {
            // 런타임 에러 발생 시 로그 출력 후 nil 반환
            print("⚠️ Failed to load FundamentalsMetrics.json: \(error)")
            return nil
        }
    }()
    
    /// Fundamentals API에 필요한 모든 metrics 로딩
    ///
    /// JSON 리소스 파일에서 metrics를 로딩하고 실패 시 에러를 throw합니다.
    /// 최초 호출 시에만 파일을 읽고, 이후에는 캐시된 데이터를 반환합니다.
    ///
    /// - Returns: 로딩된 재무제표 metrics 데이터
    /// - Throws: 파일 로딩 또는 파싱 실패 시 YFError
    public static func loadFundamentalsMetrics() throws -> FundamentalsMetrics {
        guard let metrics = _cachedMetrics else {
            throw YFError.parsingErrorWithMessage("Failed to load FundamentalsMetrics.json resource file")
        }
        return metrics
    }
    
    /// Bundle에서 JSON 파일을 로딩하여 파싱
    ///
    /// - Returns: 파싱된 FundamentalsMetrics 데이터
    /// - Throws: 파일 로딩 또는 JSON 파싱 실패 시 에러
    private static func loadMetricsFromBundle() throws -> FundamentalsMetrics {
        // Bundle에서 JSON 파일 경로 찾기
        let bundle = Bundle.module
        
        guard let url = bundle.url(forResource: "FundamentalsMetrics", withExtension: "json") else {
            throw YFError.parsingErrorWithMessage("FundamentalsMetrics.json not found in bundle")
        }
        
        // JSON 파일 데이터 읽기
        let data = try Data(contentsOf: url)
        
        // JSON 파싱
        let decoder = JSONDecoder()
        return try decoder.decode(FundamentalsMetrics.self, from: data)
    }
}