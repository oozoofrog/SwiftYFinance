import Foundation

// MARK: - Option Type

public enum YFOptionType: String, Sendable {
    case call
    case put
}

// MARK: - Main Options Chain Model

public struct YFOptionsChain: Sendable, Decodable {
    public let underlyingSymbol: String
    public let expirationDates: [Date]
    public let strikes: [Double]
    public let hasMiniOptions: Bool
    public let quote: YFOptionsQuote?
    public let options: [YFOptionData]
    
    private enum CodingKeys: String, CodingKey {
        case optionChain
    }
    
    private enum OptionChainKeys: String, CodingKey {
        case result
    }
    
    private enum ResultKeys: String, CodingKey {
        case underlyingSymbol
        case expirationDates
        case strikes
        case hasMiniOptions
        case quote
        case options
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let optionChainContainer = try container.nestedContainer(keyedBy: OptionChainKeys.self, forKey: .optionChain)
        var resultArray = try optionChainContainer.nestedUnkeyedContainer(forKey: .result)
        
        guard !resultArray.isAtEnd else {
            throw DecodingError.dataCorruptedError(forKey: .result, in: optionChainContainer, debugDescription: "Result array is empty")
        }
        
        let resultContainer = try resultArray.nestedContainer(keyedBy: ResultKeys.self)
        
        self.underlyingSymbol = try resultContainer.decode(String.self, forKey: .underlyingSymbol)
        
        // Convert Unix timestamps to Dates
        let timestamps = try resultContainer.decode([Int].self, forKey: .expirationDates)
        self.expirationDates = timestamps.map { Date(timeIntervalSince1970: TimeInterval($0)) }
        
        self.strikes = try resultContainer.decode([Double].self, forKey: .strikes)
        self.hasMiniOptions = try resultContainer.decode(Bool.self, forKey: .hasMiniOptions)
        
        // Decode quote and set the symbol from underlyingSymbol
        if let quote = try resultContainer.decodeIfPresent(YFOptionsQuote.self, forKey: .quote) {
            self.quote = quote.withSymbol(self.underlyingSymbol)
        } else {
            self.quote = nil
        }
        
        // Decode options array
        let optionDataArray = try resultContainer.decode([OptionDataIntermediate].self, forKey: .options)
        self.options = optionDataArray.map { $0.toYFOptionData() }
    }
    
    public init(
        underlyingSymbol: String,
        expirationDates: [Date],
        strikes: [Double],
        hasMiniOptions: Bool,
        quote: YFOptionsQuote?,
        options: [YFOptionData]
    ) {
        self.underlyingSymbol = underlyingSymbol
        self.expirationDates = expirationDates
        self.strikes = strikes
        self.hasMiniOptions = hasMiniOptions
        self.quote = quote
        self.options = options
    }
}

// MARK: - Intermediate Decodable Structures

private struct OptionDataIntermediate: Decodable {
    let calls: [OptionContract]
    let puts: [OptionContract]
    
    func toYFOptionData() -> YFOptionData {
        // Get expiration date from the first available contract
        let expirationDate = calls.first?.expiration ?? puts.first?.expiration ?? Int(Date().timeIntervalSince1970)
        
        return YFOptionData(
            expirationDate: Date(timeIntervalSince1970: TimeInterval(expirationDate)),
            hasMiniOptions: false, // This field doesn't exist at option level in API response
            calls: calls.map { $0.toYFOption(type: .call) },
            puts: puts.map { $0.toYFOption(type: .put) }
        )
    }
}

private struct OptionContract: Decodable {
    let contractSymbol: String
    let strike: Double
    let currency: String
    let lastPrice: Double
    let bid: Double?
    let ask: Double?
    let volume: Int?
    let openInterest: Int?
    let impliedVolatility: Double?
    let inTheMoney: Bool
    let expiration: Int
    
    func toYFOption(type: YFOptionType) -> YFOption {
        YFOption(
            contractSymbol: contractSymbol,
            strike: strike,
            currency: currency,
            lastPrice: lastPrice,
            bid: bid,
            ask: ask,
            volume: volume,
            openInterest: openInterest ?? 0,
            impliedVolatility: impliedVolatility,
            inTheMoney: inTheMoney,
            expiration: Date(timeIntervalSince1970: TimeInterval(expiration)),
            type: type
        )
    }
}

// MARK: - Quote Information

public struct YFOptionsQuote: Sendable, Decodable {
    public let symbol: String
    public let regularMarketPrice: Double?
    public let currency: String?
    public let longName: String?
    public let regularMarketDayHigh: Double?
    public let regularMarketDayLow: Double?
    public let regularMarketVolume: Int?
    
    enum CodingKeys: String, CodingKey {
        case regularMarketPrice
        case currency
        case longName
        case regularMarketDayHigh
        case regularMarketDayLow
        case regularMarketVolume
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // symbol is not in the quote JSON, it will be set from underlyingSymbol
        self.symbol = ""
        self.regularMarketPrice = try container.decodeIfPresent(Double.self, forKey: .regularMarketPrice)
        self.currency = try container.decodeIfPresent(String.self, forKey: .currency)
        self.longName = try container.decodeIfPresent(String.self, forKey: .longName)
        self.regularMarketDayHigh = try container.decodeIfPresent(Double.self, forKey: .regularMarketDayHigh)
        self.regularMarketDayLow = try container.decodeIfPresent(Double.self, forKey: .regularMarketDayLow)
        self.regularMarketVolume = try container.decodeIfPresent(Int.self, forKey: .regularMarketVolume)
    }
    
    public init(
        symbol: String,
        regularMarketPrice: Double?,
        currency: String?,
        longName: String? = nil,
        regularMarketDayHigh: Double? = nil,
        regularMarketDayLow: Double? = nil,
        regularMarketVolume: Int? = nil
    ) {
        self.symbol = symbol
        self.regularMarketPrice = regularMarketPrice
        self.currency = currency
        self.longName = longName
        self.regularMarketDayHigh = regularMarketDayHigh
        self.regularMarketDayLow = regularMarketDayLow
        self.regularMarketVolume = regularMarketVolume
    }
    
    func withSymbol(_ symbol: String) -> YFOptionsQuote {
        YFOptionsQuote(
            symbol: symbol,
            regularMarketPrice: regularMarketPrice,
            currency: currency,
            longName: longName,
            regularMarketDayHigh: regularMarketDayHigh,
            regularMarketDayLow: regularMarketDayLow,
            regularMarketVolume: regularMarketVolume
        )
    }
}

// MARK: - Option Data Container

public struct YFOptionData: Sendable {
    public let expirationDate: Date
    public let hasMiniOptions: Bool
    public let calls: [YFOption]
    public let puts: [YFOption]
    
    public init(
        expirationDate: Date,
        hasMiniOptions: Bool,
        calls: [YFOption],
        puts: [YFOption]
    ) {
        self.expirationDate = expirationDate
        self.hasMiniOptions = hasMiniOptions
        self.calls = calls
        self.puts = puts
    }
}

// MARK: - Individual Option Contract

public struct YFOption: Sendable {
    public let contractSymbol: String
    public let strike: Double
    public let currency: String
    public let lastPrice: Double
    public let bid: Double?
    public let ask: Double?
    public let volume: Int?
    public let openInterest: Int
    public let impliedVolatility: Double?
    public let inTheMoney: Bool
    public let expiration: Date
    public let type: YFOptionType
    
    public init(
        contractSymbol: String,
        strike: Double,
        currency: String,
        lastPrice: Double,
        bid: Double?,
        ask: Double?,
        volume: Int?,
        openInterest: Int,
        impliedVolatility: Double?,
        inTheMoney: Bool,
        expiration: Date,
        type: YFOptionType
    ) {
        self.contractSymbol = contractSymbol
        self.strike = strike
        self.currency = currency
        self.lastPrice = lastPrice
        self.bid = bid
        self.ask = ask
        self.volume = volume
        self.openInterest = openInterest
        self.impliedVolatility = impliedVolatility
        self.inTheMoney = inTheMoney
        self.expiration = expiration
        self.type = type
    }
}