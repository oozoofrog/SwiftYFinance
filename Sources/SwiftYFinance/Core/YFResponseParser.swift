import Foundation

public class YFResponseParser {
    private let decoder: JSONDecoder
    
    public init() {
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .secondsSince1970
    }
    
    public func parse<T: Decodable>(_ data: Data, type: T.Type) throws -> T {
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw YFError.parsingError
        }
    }
    
    public func parseError(_ data: Data) throws -> YFErrorResponse? {
        do {
            let errorWrapper = try decoder.decode(ErrorWrapper.self, from: data)
            return errorWrapper.chart?.error
        } catch {
            return nil
        }
    }
}

public struct YFErrorResponse: Codable {
    public let code: String
    public let description: String?
}

struct ErrorWrapper: Codable {
    let chart: ErrorChart?
}

struct ErrorChart: Codable {
    let error: YFErrorResponse?
}