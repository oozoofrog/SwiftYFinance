import Testing
@testable import SwiftYFinance

/// YFNewsService의 TDD 기반 테스트
@Suite("YFNewsService Tests")
struct YFNewsServiceTests {
    
    let client = YFClient(debugEnabled: true)
    let testTicker = YFTicker(symbol: "AAPL")
    
    /// [Red] 첫 번째 실패 테스트: 기본 뉴스 조회 기능
    @Test("단일 종목 뉴스 조회 - 기본 기능")
    func testFetchNewsForSingleTicker() async throws {
        // Given: 유효한 종목 심볼
        let ticker = testTicker
        
        // When: 뉴스 서비스를 통해 뉴스 조회
        let news = try await client.news.fetchNews(ticker: ticker)
        
        // Then: 뉴스 데이터가 반환되어야 함
        #expect(!news.isEmpty, "뉴스 데이터가 비어있지 않아야 합니다")
        #expect(news.count <= 10, "기본 뉴스 개수는 10개 이하여야 합니다")
        
        // 첫 번째 뉴스 기사 검증
        let firstArticle = try #require(news.first)
        #expect(!firstArticle.title.isEmpty, "뉴스 제목이 비어있지 않아야 합니다")
        #expect(firstArticle.link.hasPrefix("http"), "뉴스 링크는 유효한 URL이어야 합니다")
        #expect(!firstArticle.source.isEmpty, "뉴스 소스가 비어있지 않아야 합니다")
    }
    
    /// [Red] 두 번째 실패 테스트: 다중 종목 뉴스 조회 기능
    @Test("다중 종목 뉴스 조회 - 기본 기능")
    func testFetchNewsForMultipleTickers() async throws {
        // Given: 여러 유효한 종목 심볼들
        let tickers = [
            YFTicker(symbol: "AAPL"),
            YFTicker(symbol: "MSFT"),
            YFTicker(symbol: "GOOGL")
        ]
        
        // When: 뉴스 서비스를 통해 다중 종목 뉴스 조회
        let newsResult = try await client.news.fetchMultipleNews(tickers: tickers, count: 5)
        
        // Then: 모든 종목에 대한 뉴스가 반환되어야 함
        #expect(newsResult.count == tickers.count, "모든 종목에 대한 뉴스가 반환되어야 합니다")
        
        // 각 종목별 뉴스 검증
        for ticker in tickers {
            let tickerNews = newsResult[ticker]
            #expect(tickerNews != nil, "\(ticker.symbol) 종목의 뉴스가 반환되어야 합니다")
            
            if let news = tickerNews {
                #expect(news.count <= 5, "\(ticker.symbol) 뉴스 개수는 5개 이하여야 합니다")
                
                // 뉴스가 있다면 첫 번째 기사 검증
                if let firstArticle = news.first {
                    #expect(!firstArticle.title.isEmpty, "\(ticker.symbol) 뉴스 제목이 비어있지 않아야 합니다")
                    #expect(firstArticle.link.hasPrefix("http"), "\(ticker.symbol) 뉴스 링크는 유효한 URL이어야 합니다")
                }
            }
        }
    }
}