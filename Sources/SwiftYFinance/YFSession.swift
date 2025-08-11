import Foundation

public class YFSession {
    public let urlSession: URLSession
    public let baseURL: URL
    public let timeout: TimeInterval
    private let additionalHeaders: [String: String]
    
    public var defaultHeaders: [String: String] {
        var headers = [
            "User-Agent": "SwiftYFinance/1.0",
            "Accept": "application/json",
            "Content-Type": "application/json"
        ]
        
        for (key, value) in additionalHeaders {
            headers[key] = value
        }
        
        return headers
    }
    
    public init(
        baseURL: URL = URL(string: "https://query1.finance.yahoo.com")!,
        timeout: TimeInterval = 30.0,
        additionalHeaders: [String: String] = [:]
    ) {
        self.baseURL = baseURL
        self.timeout = timeout
        self.additionalHeaders = additionalHeaders
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout
        
        self.urlSession = URLSession(configuration: config)
    }
}