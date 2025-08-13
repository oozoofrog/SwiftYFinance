import Testing
import Foundation
@testable import SwiftYFinance

struct QuoteSummaryTests {
    
    @Test
    func testQuoteSummaryResponse() throws {
        // Yahoo Finance quoteSummary API와 동일한 구조의 JSON 테스트 데이터
        let jsonData = """
        {
            "quoteSummary": {
                "result": [{
                    "price": {
                        "shortName": "Apple Inc.",
                        "regularMarketPrice": {
                            "raw": 150.25,
                            "fmt": "$150.25"
                        },
                        "regularMarketVolume": {
                            "raw": 50000000,
                            "fmt": "50.00M"
                        },
                        "marketCap": {
                            "raw": 2500000000000,
                            "fmt": "$2.50T"
                        },
                        "regularMarketTime": {
                            "raw": 1755028802,
                            "fmt": "4:00PM EST"
                        },
                        "regularMarketOpen": {
                            "raw": 149.80,
                            "fmt": "$149.80"
                        },
                        "regularMarketDayHigh": {
                            "raw": 151.50,
                            "fmt": "$151.50"
                        },
                        "regularMarketDayLow": {
                            "raw": 148.90,
                            "fmt": "$148.90"
                        },
                        "regularMarketPreviousClose": {
                            "raw": 149.50,
                            "fmt": "$149.50"
                        },
                        "postMarketPrice": {
                            "raw": 150.75,
                            "fmt": "$150.75"
                        },
                        "postMarketTime": {
                            "raw": 1755032402,
                            "fmt": "5:00PM EST"
                        },
                        "postMarketChangePercent": {
                            "raw": 0.33,
                            "fmt": "+0.33%"
                        }
                    },
                    "summaryDetail": {
                        "volume": {
                            "raw": 50000000,
                            "fmt": "50.00M"
                        }
                    }
                }],
                "error": null
            }
        }
        """.data(using: .utf8)!
        
        // JSON 파싱 테스트
        let parser = YFResponseParser()
        let quoteSummaryResponse = try parser.parse(jsonData, type: QuoteSummaryResponse.self)
        
        // 기본 구조 검증
        #expect(quoteSummaryResponse.quoteSummary.result != nil)
        #expect(quoteSummaryResponse.quoteSummary.error == nil)
        #expect(quoteSummaryResponse.quoteSummary.result!.count == 1)
        
        let result = quoteSummaryResponse.quoteSummary.result![0]
        #expect(result.price != nil)
        #expect(result.summaryDetail != nil)
        
        // PriceData 구조 검증
        let priceData = result.price!
        #expect(priceData.shortName == "Apple Inc.")
        #expect(priceData.regularMarketPrice?.raw == 150.25)
        #expect(priceData.regularMarketPrice?.fmt == "$150.25")
        #expect(priceData.regularMarketVolume?.raw == 50000000)
        #expect(priceData.marketCap?.raw == 2500000000000)
        #expect(priceData.regularMarketTime?.raw == 1755028802)
        
        // OHLC 데이터 검증
        #expect(priceData.regularMarketOpen?.raw == 149.80)
        #expect(priceData.regularMarketDayHigh?.raw == 151.50)
        #expect(priceData.regularMarketDayLow?.raw == 148.90)
        #expect(priceData.regularMarketPreviousClose?.raw == 149.50)
        
        // 시간외 거래 데이터 검증
        #expect(priceData.postMarketPrice?.raw == 150.75)
        #expect(priceData.postMarketTime?.raw == 1755032402)
        #expect(priceData.postMarketChangePercent?.raw == 0.33)
    }
    
    @Test
    func testQuoteSummaryErrorHandling() throws {
        // Yahoo Finance API 에러 응답 테스트
        let errorResponseJSON = """
        {
            "quoteSummary": {
                "result": null,
                "error": {
                    "code": "Not Found",
                    "description": "No data found, symbol may be delisted"
                }
            }
        }
        """.data(using: .utf8)!
        
        let parser = YFResponseParser()
        let errorResponse = try parser.parse(errorResponseJSON, type: QuoteSummaryResponse.self)
        
        // 에러 응답 구조 검증
        #expect(errorResponse.quoteSummary.result == nil)
        #expect(errorResponse.quoteSummary.error != nil)
        
        let error = errorResponse.quoteSummary.error!
        #expect(error.code == "Not Found")
        #expect(error.description == "No data found, symbol may be delisted")
    }
    
    @Test
    func testValueContainerStructure() throws {
        // ValueContainer<T> 구조체 개별 테스트
        let valueJSON = """
        {
            "raw": 150.25,
            "fmt": "$150.25"
        }
        """.data(using: .utf8)!
        
        let parser = YFResponseParser()
        let valueContainer = try parser.parse(valueJSON, type: ValueContainer<Double>.self)
        
        #expect(valueContainer.raw == 150.25)
        #expect(valueContainer.fmt == "$150.25")
    }
    
    @Test
    func testPartialData() throws {
        // 일부 데이터만 있는 경우 테스트 (nullable 필드들)
        let partialJSON = """
        {
            "quoteSummary": {
                "result": [{
                    "price": {
                        "shortName": "Test Stock",
                        "regularMarketPrice": {
                            "raw": 100.0,
                            "fmt": "$100.00"
                        }
                    }
                }]
            }
        }
        """.data(using: .utf8)!
        
        let parser = YFResponseParser()
        let response = try parser.parse(partialJSON, type: QuoteSummaryResponse.self)
        
        let priceData = response.quoteSummary.result![0].price!
        #expect(priceData.shortName == "Test Stock")
        #expect(priceData.regularMarketPrice?.raw == 100.0)
        
        // nullable 필드들이 nil인지 확인
        #expect(priceData.postMarketPrice == nil)
        #expect(priceData.preMarketPrice == nil)
        #expect(priceData.marketCap == nil)
    }
    
    @Test
    func testRealQuoteSummaryAPI() async throws {
        // 실제 Yahoo Finance quoteSummary API 호출 테스트
        let session = YFSession()
        let builder = YFRequestBuilder(session: session)
        let parser = YFResponseParser()
        
        // CSRF 인증 시도 (실패해도 계속 진행)
        do {
            try await session.authenticateCSRF()
        } catch {
            // CSRF 인증 실패시 기본 요청으로 진행
        }
        
        // quoteSummary API 요청 구성
        let isAuthenticated = await session.isCSRFAuthenticated
        let baseURL = isAuthenticated ? 
            "https://query2.finance.yahoo.com" : 
            "https://query1.finance.yahoo.com"
        
        var requestURL = URL(string: "\(baseURL)/v10/finance/quoteSummary/AAPL")!
        var components = URLComponents(url: requestURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "modules", value: "price"),
            URLQueryItem(name: "corsDomain", value: "finance.yahoo.com"),
            URLQueryItem(name: "formatted", value: "false")
        ]
        requestURL = components.url!
        
        // CSRF가 인증된 경우 crumb 추가
        if isAuthenticated {
            requestURL = await session.addCrumbIfNeeded(to: requestURL)
        }
        
        var request = URLRequest(url: requestURL, timeoutInterval: session.timeout)
        
        // 기본 헤더 설정
        for (key, value) in session.defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await session.urlSession.data(for: request)
        
        // HTTP 응답 확인
        let httpResponse = response as? HTTPURLResponse
        
        if httpResponse?.statusCode == 200 {
            // 성공적인 응답인 경우 파싱 테스트
            let quoteSummaryResponse = try parser.parse(data, type: QuoteSummaryResponse.self)
            
            if let result = quoteSummaryResponse.quoteSummary.result?.first,
               let priceData = result.price {
                #expect(priceData.shortName != nil)
                #expect(priceData.regularMarketPrice?.raw != nil)
                #expect(priceData.regularMarketPrice!.raw > 0)
            }
        } else if httpResponse?.statusCode == 401 || httpResponse?.statusCode == 403 {
            // 인증 실패 - 예상된 결과
            let responseText = String(data: data, encoding: .utf8) ?? ""
            #expect(responseText.contains("Unauthorized") || responseText.contains("Invalid"))
        } else {
            // 기타 HTTP 에러
            throw YFError.networkError
        }
    }
}