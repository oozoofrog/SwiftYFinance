import Testing
import Foundation
@testable import SwiftYFinance

struct TimestampParsingTests {
    @Test
    func testParseTimestamps() throws {
        // Unix timestamp 배열 (Python yfinance와 동일한 방식)
        let timestamps: [Int64] = [1234567890, 1234567950, 1234568010]
        
        // Swift에서 Unix timestamp를 Date로 변환
        let dates = timestamps.map { timestamp in
            Date(timeIntervalSince1970: TimeInterval(timestamp))
        }
        
        // 변환 결과 검증
        #expect(dates.count == 3)
        
        // 첫 번째 timestamp 검증 (1234567890 = 2009-02-13 23:31:30 UTC)
        let date1 = dates[0]
        let calendar = Calendar(identifier: .gregorian)
        let utcTimeZone = TimeZone(identifier: "UTC")!
        let components1 = calendar.dateComponents(in: utcTimeZone, from: date1)
        
        #expect(components1.year == 2009)
        #expect(components1.month == 2)
        #expect(components1.day == 13)
        #expect(components1.hour == 23)
        #expect(components1.minute == 31)
        #expect(components1.second == 30)
        
        // 두 번째 timestamp 검증 (1234567950 = 2009-02-13 23:32:30 UTC)
        let date2 = dates[1]
        let components2 = calendar.dateComponents(in: utcTimeZone, from: date2)
        
        #expect(components2.year == 2009)
        #expect(components2.month == 2)
        #expect(components2.day == 13)
        #expect(components2.hour == 23)
        #expect(components2.minute == 32)
        #expect(components2.second == 30)
        
        // 시간 순서 검증 (timestamps는 순차적으로 증가해야 함)
        for i in 1..<dates.count {
            #expect(dates[i] > dates[i-1])
        }
        
        // 시간 간격 검증 (60초 간격)
        let interval1to2 = dates[1].timeIntervalSince(dates[0])
        let interval2to3 = dates[2].timeIntervalSince(dates[1])
        
        #expect(interval1to2 == 60.0)
        #expect(interval2to3 == 60.0)
    }
}