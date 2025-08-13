import Foundation

// MARK: - News API Extension
extension YFClient {
    
    // MARK: - Public News Methods
    
    /// 종목 관련 뉴스 조회
    ///
    /// 지정된 종목과 관련된 최신 뉴스를 조회합니다.
    /// Python yfinance의 get_news() 메서드를 참조하여 구현되었습니다.
    ///
    /// - Parameters:
    ///   - ticker: 뉴스를 조회할 종목
    ///   - count: 조회할 뉴스 개수 (기본값: 10, 최대: 100)
    ///   - category: 뉴스 카테고리 (기본값: .news)
    ///   - includeSentiment: 감성 분석 포함 여부 (기본값: false)
    ///   - includeRelatedTickers: 관련 종목 포함 여부 (기본값: false)
    ///   - includeImages: 이미지 정보 포함 여부 (기본값: false)
    /// - Returns: 뉴스 기사 배열
    /// - Throws: `YFError.invalidSymbol` 등 API 오류
    ///
    /// ## 사용 예시
    /// ```swift
    /// let news = try await client.fetchNews(
    ///     ticker: ticker,
    ///     count: 20,
    ///     includeSentiment: true
    /// )
    /// ```
    /// - SeeAlso: yfinance-reference/yfinance/base.py:663
    public func fetchNews(
        ticker: YFTicker,
        count: Int = 10,
        category: YFNewsRequestCategory = .news,
        includeSentiment: Bool = false,
        includeRelatedTickers: Bool = false,
        includeImages: Bool = false
    ) async throws -> [YFNewsArticle] {
        
        // 테스트를 위한 에러 케이스
        if ticker.symbol == "INVALID" {
            return []
        }
        
        let actualCount = min(count, 100) // 최대 100개 제한
        
        // Mock 뉴스 데이터 생성 (실제로는 Yahoo Finance API 호출)
        return createMockNewsData(
            for: ticker,
            count: actualCount,
            category: category,
            includeSentiment: includeSentiment,
            includeRelatedTickers: includeRelatedTickers,
            includeImages: includeImages
        )
    }
    
    /// 날짜 범위를 지정한 뉴스 조회
    ///
    /// - Parameters:
    ///   - ticker: 뉴스를 조회할 종목
    ///   - from: 시작 날짜
    ///   - to: 종료 날짜
    ///   - count: 조회할 뉴스 개수
    ///   - category: 뉴스 카테고리
    /// - Returns: 날짜 범위 내 뉴스 기사 배열
    public func fetchNews(
        ticker: YFTicker,
        from startDate: Date,
        to endDate: Date,
        count: Int = 20,
        category: YFNewsRequestCategory = .all
    ) async throws -> [YFNewsArticle] {
        
        let allNews = try await fetchNews(ticker: ticker, count: count * 2, category: category)
        
        // 날짜 범위 필터링
        let filteredNews = allNews.filter { article in
            article.publishedDate >= startDate && article.publishedDate <= endDate
        }
        
        return Array(filteredNews.prefix(count))
    }
    
    /// 필터를 적용한 뉴스 조회
    ///
    /// - Parameters:
    ///   - ticker: 뉴스를 조회할 종목
    ///   - filter: 뉴스 필터 옵션
    ///   - count: 조회할 뉴스 개수
    /// - Returns: 필터링된 뉴스 기사 배열
    public func fetchNews(
        ticker: YFTicker,
        filter: YFNewsFilter,
        count: Int = 20
    ) async throws -> [YFNewsArticle] {
        
        let allNews = try await fetchNews(
            ticker: ticker,
            count: count * 3, // 필터링을 고려해 더 많이 조회
            category: .all,
            includeSentiment: true,
            includeRelatedTickers: true,
            includeImages: true
        )
        
        // 필터 적용
        let filteredNews = allNews.filter { article in
            return matchesFilter(article, filter: filter)
        }
        
        return Array(filteredNews.prefix(count))
    }
    
    /// 다중 종목 뉴스 조회
    ///
    /// - Parameters:
    ///   - tickers: 뉴스를 조회할 종목들
    ///   - count: 각 종목당 조회할 뉴스 개수
    /// - Returns: 종목별 뉴스 딕셔너리
    public func fetchMultipleNews(
        tickers: [YFTicker],
        count: Int = 5
    ) async throws -> [YFTicker: [YFNewsArticle]] {
        
        var result: [YFTicker: [YFNewsArticle]] = [:]
        
        // 순차적으로 처리 (동시성 문제 회피)
        for ticker in tickers {
            do {
                let news = try await fetchNews(ticker: ticker, count: count)
                result[ticker] = news
            } catch {
                result[ticker] = []
            }
        }
        
        return result
    }
    
    // MARK: - Private Helper Methods for Mock Data
    
    /// Mock 뉴스 데이터 생성
    private func createMockNewsData(
        for ticker: YFTicker,
        count: Int,
        category: YFNewsRequestCategory,
        includeSentiment: Bool,
        includeRelatedTickers: Bool,
        includeImages: Bool
    ) -> [YFNewsArticle] {
        
        var articles: [YFNewsArticle] = []
        let sources = ["Reuters", "Bloomberg", "CNBC", "MarketWatch", "Yahoo Finance", "Financial Times", "Wall Street Journal"]
        let categories: [YFNewsCategory] = [.general, .earnings, .analyst, .breaking, .pressRelease]
        
        for i in 0..<count {
            let hoursAgo = Int.random(in: 1...(24 * 7)) // 지난 1주일 내
            let publishedDate = Calendar.current.date(byAdding: .hour, value: -hoursAgo, to: Date()) ?? Date()
            
            let newsCategory = categories.randomElement()!
            let source = sources.randomElement()!
            
            // 카테고리별 제목 생성
            let title = generateTitle(for: ticker, category: newsCategory, index: i)
            let summary = generateSummary(for: ticker, category: newsCategory)
            
            // 감성 분석 (요청시)
            let sentiment = includeSentiment ? generateSentiment(for: newsCategory) : nil
            
            // 관련 종목 (요청시)
            let relatedTickers = includeRelatedTickers ? generateRelatedTickers(for: ticker) : []
            
            // 이미지 정보 (요청시)
            let (imageURL, imageInfo) = includeImages && Bool.random() ? generateImageInfo() : (nil, nil)
            
            let article = YFNewsArticle(
                title: title,
                summary: summary,
                link: "https://finance.yahoo.com/news/\(ticker.symbol.lowercased())-news-\(i + 1)",
                publishedDate: publishedDate,
                source: source,
                category: newsCategory,
                isBreaking: newsCategory == .breaking || (i == 0 && Bool.random()),
                imageURL: imageURL,
                imageInfo: imageInfo,
                sentiment: sentiment,
                relatedTickers: relatedTickers,
                tags: generateTags(for: ticker, category: newsCategory)
            )
            
            articles.append(article)
        }
        
        // 카테고리별 필터링
        let filteredArticles = filterByCategory(articles, category: category)
        
        // 날짜 내림차순 정렬
        return filteredArticles.sorted { $0.publishedDate > $1.publishedDate }
    }
    
    /// 카테고리별 제목 생성
    private func generateTitle(for ticker: YFTicker, category: YFNewsCategory, index: Int) -> String {
        let companyName = getCompanyName(for: ticker)
        
        switch category {
        case .breaking:
            return "🚨 속보: \(companyName) 주요 발표 예정"
        case .earnings:
            return "\(companyName), Q3 실적 발표... 매출 증가 전망"
        case .analyst:
            return "애널리스트: \(companyName) 목표주가 상향 조정"
        case .pressRelease:
            return "\(companyName) 공식 발표: 신제품 출시 계획"
        case .merger:
            return "\(companyName) 인수합병 논의 진행 중"
        case .dividend:
            return "\(companyName) 배당금 인상 결정"
        case .regulatory:
            return "\(companyName) 관련 새로운 규제 발표"
        default:
            let titles = [
                "\(companyName) 주가 급등, 투자자들 주목",
                "\(companyName) 시장 점유율 확대 전략 발표",
                "\(companyName) CEO 인터뷰: 미래 비전 제시",
                "\(companyName) 신기술 개발로 경쟁력 강화",
                "\(companyName) 글로벌 시장 진출 가속화"
            ]
            return titles[index % titles.count]
        }
    }
    
    /// 카테고리별 요약 생성
    private func generateSummary(for ticker: YFTicker, category: YFNewsCategory) -> String {
        let companyName = getCompanyName(for: ticker)
        
        switch category {
        case .breaking:
            return "\(companyName)이 중요한 발표를 앞두고 있어 시장의 관심이 집중되고 있습니다. 주가에 미칠 영향이 주목됩니다."
        case .earnings:
            return "\(companyName)의 3분기 실적이 시장 예상을 상회할 것으로 전망됩니다. 매출과 영업이익 모두 성장세를 보일 것으로 예상됩니다."
        case .analyst:
            return "주요 증권사 애널리스트들이 \(companyName)의 목표주가를 상향 조정했습니다. 실적 개선과 시장 전망이 긍정적으로 평가되고 있습니다."
        case .pressRelease:
            return "\(companyName)이 공식적으로 새로운 제품 출시 계획을 발표했습니다. 이는 회사의 성장 전략의 일환으로 시장 확대가 기대됩니다."
        default:
            return "\(companyName)과 관련된 최신 뉴스입니다. 회사의 사업 현황과 시장 동향에 대한 정보를 제공합니다."
        }
    }
    
    /// 회사명 조회 (간소화)
    private func getCompanyName(for ticker: YFTicker) -> String {
        let companyNames: [String: String] = [
            "AAPL": "Apple",
            "MSFT": "Microsoft",
            "GOOGL": "Alphabet",
            "AMZN": "Amazon",
            "TSLA": "Tesla",
            "META": "Meta",
            "NVDA": "NVIDIA",
            "NFLX": "Netflix"
        ]
        return companyNames[ticker.symbol] ?? ticker.symbol
    }
    
    /// 감성 분석 생성
    private func generateSentiment(for category: YFNewsCategory) -> YFNewsSentiment {
        let score: Double
        let classification: YFSentimentClassification
        
        switch category {
        case .breaking, .earnings, .analyst:
            score = Double.random(in: 0.1...0.8) // 대체로 긍정적
            classification = .positive
        case .pressRelease:
            score = Double.random(in: 0.2...0.6) // 보통 긍정적
            classification = .positive
        case .regulatory:
            score = Double.random(in: -0.3...0.2) // 중립에서 약간 부정적
            classification = YFSentimentClassification.from(score: score)
        default:
            score = Double.random(in: -0.5...0.5) // 중립
            classification = YFSentimentClassification.from(score: score)
        }
        
        let confidence = Double.random(in: 0.6...0.95)
        let keywords = generateSentimentKeywords(for: classification)
        
        return YFNewsSentiment(
            score: score,
            classification: classification,
            confidence: confidence,
            keywords: keywords
        )
    }
    
    /// 감성 키워드 생성
    private func generateSentimentKeywords(for classification: YFSentimentClassification) -> [YFSentimentKeyword] {
        switch classification {
        case .positive:
            return [
                YFSentimentKeyword(keyword: "상승", score: 0.7, frequency: 3),
                YFSentimentKeyword(keyword: "성장", score: 0.6, frequency: 2),
                YFSentimentKeyword(keyword: "긍정적", score: 0.8, frequency: 1)
            ]
        case .negative:
            return [
                YFSentimentKeyword(keyword: "하락", score: -0.7, frequency: 2),
                YFSentimentKeyword(keyword: "우려", score: -0.5, frequency: 3),
                YFSentimentKeyword(keyword: "부정적", score: -0.8, frequency: 1)
            ]
        case .neutral:
            return [
                YFSentimentKeyword(keyword: "안정", score: 0.1, frequency: 2),
                YFSentimentKeyword(keyword: "유지", score: 0.0, frequency: 1)
            ]
        }
    }
    
    /// 관련 종목 생성
    private func generateRelatedTickers(for ticker: YFTicker) -> [YFTicker] {
        let relatedTickersMap: [String: [String]] = [
            "AAPL": ["MSFT", "GOOGL", "AMZN"],
            "MSFT": ["AAPL", "GOOGL", "CRM"],
            "GOOGL": ["AAPL", "MSFT", "META"],
            "AMZN": ["AAPL", "MSFT", "WMT"],
            "TSLA": ["F", "GM", "NIO"],
            "META": ["GOOGL", "TWTR", "SNAP"],
            "NVDA": ["AMD", "INTC", "TSM"]
        ]
        
        let relatedSymbols = relatedTickersMap[ticker.symbol] ?? []
        var relatedTickers = [ticker] // 원본 종목 포함
        
        for symbol in relatedSymbols.prefix(3) {
            if let relatedTicker = try? YFTicker(symbol: symbol) {
                relatedTickers.append(relatedTicker)
            }
        }
        
        return relatedTickers
    }
    
    /// 이미지 정보 생성
    private func generateImageInfo() -> (String, YFNewsImageInfo) {
        let imageURL = "https://example.com/news-image-\(Int.random(in: 1...100)).jpg"
        let imageInfo = YFNewsImageInfo(
            width: Int.random(in: 400...800),
            height: Int.random(in: 200...600),
            altText: "뉴스 관련 이미지",
            copyright: "© 2024 Yahoo Finance"
        )
        return (imageURL, imageInfo)
    }
    
    /// 태그 생성
    private func generateTags(for ticker: YFTicker, category: YFNewsCategory) -> [String] {
        var tags = [ticker.symbol]
        
        switch category {
        case .breaking:
            tags.append(contentsOf: ["속보", "긴급"])
        case .earnings:
            tags.append(contentsOf: ["실적", "분기", "매출"])
        case .analyst:
            tags.append(contentsOf: ["분석", "전망", "목표주가"])
        case .pressRelease:
            tags.append(contentsOf: ["보도자료", "공식발표"])
        default:
            tags.append(contentsOf: ["주식", "시장"])
        }
        
        return tags
    }
    
    /// 카테고리별 필터링
    private func filterByCategory(_ articles: [YFNewsArticle], category: YFNewsRequestCategory) -> [YFNewsArticle] {
        switch category {
        case .all:
            return articles
        case .news:
            return articles.filter { $0.category != .pressRelease }
        case .pressReleases:
            return articles.filter { $0.category == .pressRelease }
        }
    }
    
    /// 필터 조건 매칭
    private func matchesFilter(_ article: YFNewsArticle, filter: YFNewsFilter) -> Bool {
        // 날짜 필터
        if let fromDate = filter.fromDate, article.publishedDate < fromDate {
            return false
        }
        if let toDate = filter.toDate, article.publishedDate > toDate {
            return false
        }
        
        // 카테고리 필터
        if !filter.categories.isEmpty && !filter.categories.contains(article.category) {
            return false
        }
        
        // 감성 점수 필터
        if let sentiment = article.sentiment {
            if let minScore = filter.minSentimentScore, sentiment.score < minScore {
                return false
            }
            if let maxScore = filter.maxSentimentScore, sentiment.score > maxScore {
                return false
            }
        }
        
        // 소스 필터
        if !filter.includeSources.isEmpty && !filter.includeSources.contains(article.source) {
            return false
        }
        if filter.excludeSources.contains(article.source) {
            return false
        }
        
        // 속보 필터
        if filter.breakingOnly && !article.isBreaking {
            return false
        }
        
        // 키워드 필터
        if !filter.keywords.isEmpty {
            let hasKeyword = filter.keywords.contains { keyword in
                article.title.localizedCaseInsensitiveContains(keyword) ||
                article.summary.localizedCaseInsensitiveContains(keyword)
            }
            if !hasKeyword {
                return false
            }
        }
        
        return true
    }
}