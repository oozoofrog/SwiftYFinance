import Foundation

public class YFRequestBuilder {
    private let session: YFSession
    private var pathString: String?
    private var queryParameters: [String: String] = [:]
    private var additionalHeaders: [String: String] = [:]
    
    public init(session: YFSession) {
        self.session = session
    }
    
    public func path(_ path: String) -> YFRequestBuilder {
        self.pathString = path
        return self
    }
    
    public func queryParam(_ key: String, _ value: String) -> YFRequestBuilder {
        queryParameters[key] = value
        return self
    }
    
    public func queryParams(_ params: [String: String]) -> YFRequestBuilder {
        for (key, value) in params {
            queryParameters[key] = value
        }
        return self
    }
    
    public func header(_ key: String, _ value: String) -> YFRequestBuilder {
        additionalHeaders[key] = value
        return self
    }
    
    public func headers(_ headers: [String: String]) -> YFRequestBuilder {
        for (key, value) in headers {
            additionalHeaders[key] = value
        }
        return self
    }
    
    public func build() throws -> URLRequest {
        guard let path = pathString else {
            throw YFError.invalidRequest
        }
        
        guard var urlComponents = URLComponents(string: path) else {
            throw YFError.invalidRequest
        }
        
        if !queryParameters.isEmpty {
            urlComponents.queryItems = queryParameters.map { key, value in
                URLQueryItem(name: key, value: value)
            }
        }
        
        guard let url = urlComponents.url(relativeTo: session.baseURL) else {
            throw YFError.invalidRequest
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = session.timeout
        
        for (key, value) in session.defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        for (key, value) in additionalHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return request
    }
}