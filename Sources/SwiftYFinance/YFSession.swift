import Foundation

public class YFSession {
    public let urlSession: URLSession
    public let baseURL: URL
    public let timeout: TimeInterval
    public let proxy: [String: Any]?
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
        baseURL: URL = URL(string: "https://query2.finance.yahoo.com")!,
        timeout: TimeInterval = 30.0,
        additionalHeaders: [String: String] = [:],
        proxy: [String: Any]? = nil
    ) {
        self.baseURL = baseURL
        self.timeout = timeout
        self.additionalHeaders = additionalHeaders
        self.proxy = proxy
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout
        
        if let proxy = proxy {
            config.connectionProxyDictionary = proxy
        }
        
        self.urlSession = URLSession(configuration: config)
    }
}