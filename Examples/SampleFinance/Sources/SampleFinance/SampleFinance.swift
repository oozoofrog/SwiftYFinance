import Foundation
import SwiftYFinance

struct SampleFinance {
    static func runApp() async {
        print("=== SampleFinance CLI ===")
        print("티커 심볼을 입력하세요 (예: AAPL, TSLA): ", terminator: "")
        
        guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines),
              !input.isEmpty else {
            print("❌ 유효한 티커 심볼을 입력해주세요.")
            return
        }
        
        let client = YFClient()
        let ticker = YFTicker(symbol: input.uppercased())
        
        print("📊 \(ticker.symbol) 가격 정보를 조회 중...")
        
        // 디버깅: 인증 상태 확인
        print("🔐 인증 상태 확인 중...")
        let isAuthenticated = await client.isCSRFAuthenticated
        print("   - 현재 인증 상태: \(isAuthenticated)")
        
        if !isAuthenticated {
            print("🔐 CSRF 인증 시도 중...")
            do {
                try await client.authenticateCSRF()
                let newAuthState = await client.isCSRFAuthenticated
                print("   - 인증 결과: \(newAuthState ? "성공" : "실패")")
                
                if newAuthState {
                    let crumbToken = await client.crumbToken
                    print("   - Crumb 토큰: \(crumbToken != nil ? "획득" : "없음")")
                    if let token = crumbToken {
                        print("     토큰 값: \(token.prefix(20))...")
                    }
                    
                    let strategy = await client.cookieStrategy
                    print("   - 쿠키 전략: \(strategy)")
                }
            } catch {
                print("   - 인증 실패 에러: \(error)")
                if let yfError = error as? YFError {
                    print("   - YFError 타입: \(yfError)")
                }
                print("   - 기본 요청으로 진행합니다...")
            }
        }
        
        print("📈 시세 데이터 요청 중...")
        do {
            let quote = try await client.fetchQuote(ticker: ticker)
            
            print("\n✅ \(quote.ticker.symbol) 현재 시세:")
            print("   회사명: \(quote.shortName)")
            print("   현재가: $\(String(format: "%.2f", quote.regularMarketPrice))")
            
            // 전일대비 변동 계산
            let change = quote.regularMarketPrice - quote.regularMarketPreviousClose
            let changePercent = (change / quote.regularMarketPreviousClose) * 100
            let changeSymbol = change >= 0 ? "🟢" : "🔴"
            print("   변동: \(changeSymbol) $\(String(format: "%.2f", change)) (\(String(format: "%.2f", changePercent))%)")
            
            print("   시가총액: $\(formatLargeNumber(quote.marketCap))")
            print("   거래량: \(quote.regularMarketVolume.formatted())")
            print("   전일 종가: $\(String(format: "%.2f", quote.regularMarketPreviousClose))")
            
            // 장후 거래 정보 (있는 경우)
            if let postPrice = quote.postMarketPrice {
                print("   장후 거래가: $\(String(format: "%.2f", postPrice))")
            }
            
        } catch {
            print("❌ 에러가 발생했습니다: \(error)")
            
            if let yfError = error as? YFError {
                switch yfError {
                case .networkError:
                    print("💡 네트워크 연결을 확인해주세요.")
                case .apiError(let message):
                    print("💡 API 에러: \(message)")
                case .invalidRequest:
                    print("💡 올바른 티커 심볼인지 확인해주세요.")
                default:
                    print("💡 다시 시도해주세요.")
                }
            }
        }
    }
    
    private static func formatLargeNumber(_ number: Double) -> String {
        if number >= 1_000_000_000_000 {
            return String(format: "%.1fT", number / 1_000_000_000_000)
        } else if number >= 1_000_000_000 {
            return String(format: "%.1fB", number / 1_000_000_000)
        } else if number >= 1_000_000 {
            return String(format: "%.1fM", number / 1_000_000)
        } else {
            return String(format: "%.0f", number)
        }
    }
}

@main 
enum Main {
    static func main() async {
        await SampleFinance.runApp()
    }
}
