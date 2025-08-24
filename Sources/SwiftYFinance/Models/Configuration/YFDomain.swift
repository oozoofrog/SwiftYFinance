import Foundation

/// Yahoo Finance Domain API 타입 정의
/// 
/// Yahoo Finance의 섹터, 산업, 시장 도메인 정보를 조회하는 API 타입입니다.
/// yfinance Python 라이브러리의 domain 모듈과 호환됩니다.
public enum YFDomainType: String, CaseIterable, Sendable {
    /// 섹터별 데이터
    case sector = "sectors"
    /// 산업별 데이터  
    case industry = "industries"
    /// 시장별 데이터
    case market = "markets"
}

/// Yahoo Finance 지원 섹터 목록
/// 
/// yfinance const.py의 SECTOR_INDUSTY_MAPPING 키값들과 동일합니다.
public enum YFSector: String, CaseIterable, Sendable {
    /// 기초소재
    case basicMaterials = "basic-materials"
    /// 통신서비스
    case communicationServices = "communication-services"
    /// 소비재 (경기민감)
    case consumerCyclical = "consumer-cyclical"
    /// 소비재 (경기방어)
    case consumerDefensive = "consumer-defensive"
    /// 에너지
    case energy = "energy"
    /// 금융서비스
    case financialServices = "financial-services"
    /// 의료
    case healthcare = "healthcare"
    /// 산업재
    case industrials = "industrials"
    /// 부동산
    case realEstate = "real-estate"
    /// 기술
    case technology = "technology"
    /// 유틸리티
    case utilities = "utilities"
    
    /// 섹터 한글명
    public var displayName: String {
        switch self {
        case .basicMaterials:
            return "기초소재"
        case .communicationServices:
            return "통신서비스"
        case .consumerCyclical:
            return "소비재(경기민감)"
        case .consumerDefensive:
            return "소비재(경기방어)"
        case .energy:
            return "에너지"
        case .financialServices:
            return "금융서비스"
        case .healthcare:
            return "의료"
        case .industrials:
            return "산업재"
        case .realEstate:
            return "부동산"
        case .technology:
            return "기술"
        case .utilities:
            return "유틸리티"
        }
    }
    
    /// 주요 산업군 (yfinance const.py 기반)
    public var majorIndustries: [String] {
        switch self {
        case .basicMaterials:
            return ["specialty-chemicals", "gold", "building-materials", "copper", "steel"]
        case .communicationServices:
            return ["internet-content-information", "telecom-services", "entertainment", "electronic-gaming-multimedia"]
        case .consumerCyclical:
            return ["internet-retail", "auto-manufacturers", "restaurants", "home-improvement-retail", "travel-services"]
        case .consumerDefensive:
            return ["discount-stores", "beverages-non-alcoholic", "household-personal-products", "packaged-foods", "tobacco"]
        case .energy:
            return ["oil-gas-integrated", "oil-gas-midstream", "oil-gas-e-p", "oil-gas-equipment-services"]
        case .financialServices:
            return ["banks-diversified", "credit-services", "asset-management", "insurance-diversified", "banks-regional"]
        case .healthcare:
            return ["drug-manufacturers-general", "healthcare-plans", "biotechnology", "medical-devices", "diagnostics-research"]
        case .industrials:
            return ["aerospace-defense", "specialty-industrial-machinery", "railroads", "building-products-equipment"]
        case .realEstate:
            return ["reit-specialty", "reit-industrial", "reit-retail", "reit-residential", "reit-healthcare-facilities"]
        case .technology:
            return ["software-infrastructure", "semiconductors", "consumer-electronics", "software-application", "information-technology-services"]
        case .utilities:
            return ["utilities-regulated-electric", "utilities-renewable", "utilities-diversified", "utilities-regulated-gas"]
        }
    }
}

/// Yahoo Finance 지원 시장 목록
/// 
/// 주요 글로벌 금융 시장들을 정의합니다.
public enum YFMarket: String, CaseIterable, Sendable {
    /// 미국 시장
    case us = "us"
    /// 캐나다 시장
    case canada = "ca"
    /// 유럽 시장
    case europe = "eu"
    /// 아시아태평양 시장
    case asiaPacific = "ap"
    /// 일본 시장
    case japan = "jp"
    /// 중국 시장
    case china = "cn"
    /// 인도 시장
    case india = "in"
    /// 브라질 시장
    case brazil = "br"
    
    /// 시장 한글명
    public var displayName: String {
        switch self {
        case .us:
            return "미국"
        case .canada:
            return "캐나다"
        case .europe:
            return "유럽"
        case .asiaPacific:
            return "아시아태평양"
        case .japan:
            return "일본"
        case .china:
            return "중국"
        case .india:
            return "인도"
        case .brazil:
            return "브라질"
        }
    }
}