import Foundation

// MARK: - Yahoo Finance Quote Main Model

/**
 모듈형 YFQuote 구조체입니다.
 
 ## 개요
 
 기존 YFQuote의 모든 기능을 유지하면서, 필요한 정보만 선택적으로 디코딩할 수 있도록 
 분류별 모델들로 구성된 복합 구조체입니다.
 
 ## 사용 예제
 
 ```swift
 // 기본 정보만 필요한 경우
 let basicInfo = try JSONDecoder().decode(YFQuoteBasicInfo.self, from: jsonData)
 print("Company: \(basicInfo.longName ?? "Unknown")")
 
 // 시세 정보만 필요한 경우  
 let marketData = try JSONDecoder().decode(YFQuoteMarketData.self, from: jsonData)
 if let price = marketData.regularMarketPrice {
     print("Price: $\(price)")
 }
 
 // 전체 정보가 필요한 경우
 let fullQuote = try JSONDecoder().decode(YFQuote.self, from: jsonData)
 print("Symbol: \(fullQuote.basicInfo.symbol ?? "N/A")")
 print("Price: $\(fullQuote.marketData.regularMarketPrice ?? 0)")
 ```
 
 ## 장점
 
 - **선택적 디코딩**: 필요한 정보만 파싱하여 성능 최적화
 - **타입 안전성**: 각 도메인별 특화된 타입 정의
 - **메모리 효율성**: 불필요한 필드 로딩 방지
 - **모듈화**: 각 정보 그룹의 독립적 관리
 - **하위 호환성**: 기존 YFQuote와 동일한 필드 제공
 */
public struct YFQuote: Decodable, Sendable {
    /// 기본 종목 정보
    public let basicInfo: YFQuoteBasicInfo
    
    /// 거래소 및 통화 정보
    public let exchangeInfo: YFQuoteExchangeInfo
    
    /// 현재 시세 정보
    public let marketData: YFQuoteMarketData
    
    /// 거래량 및 시장 정보
    public let volumeInfo: YFQuoteVolumeInfo
    
    /// 장전/장후 거래 정보
    public let extendedHours: YFQuoteExtendedHoursData
    
    /// 시간 및 메타데이터
    public let metadata: YFQuoteMetadata
    
    // MARK: - Custom Decoding
    
    /// 하나의 JSON 객체에서 모든 분류별 모델을 디코딩합니다
    public init(from decoder: Decoder) throws {
        // 같은 decoder를 사용하여 각 모델을 디코딩
        self.basicInfo = try YFQuoteBasicInfo(from: decoder)
        self.exchangeInfo = try YFQuoteExchangeInfo(from: decoder)
        self.marketData = try YFQuoteMarketData(from: decoder)
        self.volumeInfo = try YFQuoteVolumeInfo(from: decoder)
        self.extendedHours = try YFQuoteExtendedHoursData(from: decoder)
        self.metadata = try YFQuoteMetadata(from: decoder)
    }
}
