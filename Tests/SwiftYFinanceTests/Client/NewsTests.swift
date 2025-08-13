import Testing
import Foundation
@testable import SwiftYFinance

struct NewsTests {
    @Test
    func testFetchBasicNews() async throws {
        let client = YFClient()
        let ticker = try YFTicker(symbol: "AAPL")
        
        // 기본 뉴스 조회 (10개)
        let news = try await client.fetchNews(ticker: ticker)
        
        #expect(news.count > 0)
        #expect(news.count <= 10) // 기본 제한
        
        // 뉴스 항목 검증
        let article = news.first!
        #expect(!article.title.isEmpty)
        #expect(!article.summary.isEmpty)
        #expect(!article.link.isEmpty)
        #expect(article.publishedDate < Date()) // 과거 시점
        #expect(!article.source.isEmpty)
        
        // URL 형식 검증
        #expect(URL(string: article.link) != nil)
    }
    
    @Test
    func testFetchNewsWithLimit() async throws {
        let client = YFClient()
        let ticker = try YFTicker(symbol: "MSFT")
        
        // 제한된 개수 뉴스 조회
        let news = try await client.fetchNews(ticker: ticker, count: 5)
        
        #expect(news.count > 0)
        #expect(news.count <= 5)
        
        // 모든 뉴스가 유효한지 확인
        for article in news {
            #expect(!article.title.isEmpty)
            #expect(!article.source.isEmpty)
            #expect(article.publishedDate < Date())
        }
    }
    
    @Test
    func testFetchNewsByCategory() async throws {
        let client = YFClient()
        let ticker = try YFTicker(symbol: "GOOGL")
        
        // 카테고리별 뉴스 조회
        let allNews = try await client.fetchNews(ticker: ticker, category: .all)
        let latestNews = try await client.fetchNews(ticker: ticker, category: .news)
        let pressReleases = try await client.fetchNews(ticker: ticker, category: .pressReleases)
        
        #expect(allNews.count > 0)
        #expect(latestNews.count > 0)
        #expect(pressReleases.count >= 0) // 보도자료는 없을 수도 있음
        
        // all 카테고리가 가장 많은 결과를 가져야 함
        #expect(allNews.count >= latestNews.count)
        
        // 카테고리 분류 확인
        for article in pressReleases {
            #expect(article.category == .pressRelease)
        }
    }
    
    @Test
    func testNewsSentimentAnalysis() async throws {
        let client = YFClient()
        let ticker = try YFTicker(symbol: "TSLA")
        
        // 감성 분석이 포함된 뉴스 조회
        let news = try await client.fetchNews(ticker: ticker, includeSentiment: true)
        
        #expect(news.count > 0)
        
        // 감성 분석 결과 확인
        let articlesWithSentiment = news.filter { $0.sentiment != nil }
        #expect(articlesWithSentiment.count > 0)
        
        for article in articlesWithSentiment {
            let sentiment = article.sentiment!
            #expect(sentiment.score >= -1.0 && sentiment.score <= 1.0) // -1 ~ 1 범위
            #expect([.positive, .negative, .neutral].contains(sentiment.classification))
            #expect(sentiment.confidence >= 0.0 && sentiment.confidence <= 1.0) // 0 ~ 1 범위
        }
    }
    
    @Test
    func testRelatedStocksInNews() async throws {
        let client = YFClient()
        let ticker = try YFTicker(symbol: "AAPL")
        
        // 관련 종목 정보가 포함된 뉴스 조회
        let news = try await client.fetchNews(ticker: ticker, includeRelatedTickers: true)
        
        #expect(news.count > 0)
        
        // 관련 종목 정보 확인
        let articlesWithRelated = news.filter { !$0.relatedTickers.isEmpty }
        
        if !articlesWithRelated.isEmpty {
            let article = articlesWithRelated.first!
            #expect(article.relatedTickers.contains { $0.symbol == "AAPL" }) // 원본 종목 포함
            
            // 관련 종목 유효성 확인
            for relatedTicker in article.relatedTickers {
                #expect(!relatedTicker.symbol.isEmpty)
            }
        }
    }
    
    @Test
    func testNewsFiltering() async throws {
        let client = YFClient()
        let ticker = try YFTicker(symbol: "AMZN")
        
        // 날짜 범위로 뉴스 필터링
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate)!
        
        let recentNews = try await client.fetchNews(
            ticker: ticker,
            from: startDate,
            to: endDate,
            count: 20
        )
        
        #expect(recentNews.count > 0)
        
        // 날짜 범위 확인
        for article in recentNews {
            #expect(article.publishedDate >= startDate)
            #expect(article.publishedDate <= endDate)
        }
        
        // 최신 순 정렬 확인
        if recentNews.count >= 2 {
            for i in 0..<(recentNews.count - 1) {
                #expect(recentNews[i].publishedDate >= recentNews[i + 1].publishedDate)
            }
        }
    }
    
    @Test
    func testNewsCategories() async throws {
        let client = YFClient()
        let ticker = try YFTicker(symbol: "META")
        
        // 뉴스 카테고리 분류 확인
        let news = try await client.fetchNews(ticker: ticker, count: 15)
        
        #expect(news.count > 0)
        
        // 카테고리 분포 확인
        let categories = Set(news.map { $0.category })
        #expect(categories.isSubset(of: [.breaking, .earnings, .general, .pressRelease, .analyst, .insider]))
        
        // 각 카테고리별 특성 확인
        for article in news {
            switch article.category {
            case .breaking:
                #expect(article.isBreaking == true)
            case .earnings:
                #expect(article.title.lowercased().contains("earnings") || 
                       article.summary.lowercased().contains("earnings") ||
                       article.title.lowercased().contains("결실") ||
                       article.summary.lowercased().contains("실적"))
            case .pressRelease:
                #expect(article.source.lowercased().contains("pr") || 
                       article.source.lowercased().contains("press") ||
                       article.title.contains("보도자료"))
            default:
                break // 일반 뉴스는 특별한 조건 없음
            }
        }
    }
    
    @Test
    func testInvalidTickerNews() async throws {
        let client = YFClient()
        let ticker = try YFTicker(symbol: "INVALID")
        
        // 잘못된 티커에 대한 뉴스 조회
        do {
            let news = try await client.fetchNews(ticker: ticker)
            // 빈 결과가 와도 에러는 아님
            #expect(news.count == 0)
        } catch {
            // 또는 적절한 에러 처리
            #expect(error is YFError)
        }
    }
    
    @Test
    func testNewsImageHandling() async throws {
        let client = YFClient()
        let ticker = try YFTicker(symbol: "NFLX")
        
        // 이미지 정보가 포함된 뉴스 조회
        let news = try await client.fetchNews(ticker: ticker, includeImages: true)
        
        #expect(news.count > 0)
        
        // 이미지 정보 확인
        let articlesWithImages = news.filter { $0.imageURL != nil }
        
        if !articlesWithImages.isEmpty {
            let article = articlesWithImages.first!
            let imageURL = article.imageURL!
            
            // URL 형식 검증
            #expect(URL(string: imageURL) != nil)
            #expect(imageURL.lowercased().contains("http"))
            
            // 이미지 메타데이터 확인
            if let imageInfo = article.imageInfo {
                #expect(imageInfo.width > 0)
                #expect(imageInfo.height > 0)
            }
        }
    }
}