import Foundation

public struct YFTicker: CustomStringConvertible, Codable {
    public let symbol: String
    
    public var description: String {
        "YFTicker(symbol: \(symbol))"
    }
    
    public init(symbol: String) throws {
        let trimmed = symbol.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            throw YFError.invalidSymbol
        }
        
        guard trimmed.count <= 10 else {
            throw YFError.invalidSymbol
        }
        
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: ".-^"))
        guard trimmed.rangeOfCharacter(from: allowedCharacters.inverted) == nil else {
            throw YFError.invalidSymbol
        }
        
        self.symbol = trimmed.uppercased()
    }
}