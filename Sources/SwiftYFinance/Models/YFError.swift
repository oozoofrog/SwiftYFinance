public enum YFError: Error, Equatable {
    case invalidSymbol
    case invalidDateRange
    case invalidRequest
    case parsingError
    case networkError
    case apiError(String)
}