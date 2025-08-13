import Foundation

// MARK: - Yahoo Finance QuoteSummary API Response Models

struct QuoteSummaryResponse: Codable {
    let quoteSummary: QuoteSummary
}

struct QuoteSummary: Codable {
    let result: [QuoteSummaryResult]?
    let error: QuoteSummaryError?
}

struct QuoteSummaryError: Codable {
    let code: String
    let description: String
}

struct QuoteSummaryResult: Codable {
    let price: PriceData?
    let summaryDetail: SummaryDetail?
}

struct PriceData: Codable {
    let shortName: String?
    let regularMarketPrice: ValueContainer<Double>?
    let regularMarketVolume: ValueContainer<Int>?
    let marketCap: ValueContainer<Double>?
    let regularMarketTime: ValueContainer<Int>?
    let regularMarketOpen: ValueContainer<Double>?
    let regularMarketDayHigh: ValueContainer<Double>?
    let regularMarketDayLow: ValueContainer<Double>?
    let regularMarketPreviousClose: ValueContainer<Double>?
    let postMarketPrice: ValueContainer<Double>?
    let postMarketTime: ValueContainer<Int>?
    let postMarketChangePercent: ValueContainer<Double>?
    let preMarketPrice: ValueContainer<Double>?
    let preMarketTime: ValueContainer<Int>?
    let preMarketChangePercent: ValueContainer<Double>?
}

struct SummaryDetail: Codable {
    // 필요시 추가 필드들
}

struct ValueContainer<T: Codable>: Codable {
    let raw: T
    let fmt: String?
}