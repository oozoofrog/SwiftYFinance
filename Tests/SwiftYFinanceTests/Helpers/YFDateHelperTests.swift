import Testing
import Foundation
@testable import SwiftYFinance

struct YFDateHelperTests {
    
    @Test("YFDateHelper exists")
    func testYFDateHelperExists() {
        // Red: YFDateHelper 클래스가 존재해야 함
        let helper = YFDateHelper()
        #expect(helper != nil)
    }
    
    @Test("periodStart returns timestamp for one day")
    func testPeriodStartOneDay() {
        // Red: periodStart 메서드가 하루 전 timestamp를 반환해야 함
        let helper = YFDateHelper()
        let timestamp = helper.periodStart(for: .oneDay)
        
        let expectedDate = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let expectedTimestamp = String(Int(expectedDate.timeIntervalSince1970))
        
        // 타임스탬프가 대략적으로 맞는지 확인 (몇 초 차이는 허용)
        let timestampInt = Int(timestamp) ?? 0
        let expectedInt = Int(expectedTimestamp) ?? 0
        #expect(abs(timestampInt - expectedInt) < 60) // 60초 이내 차이 허용
    }
    
    @Test("periodEnd returns current timestamp")
    func testPeriodEnd() {
        // Red: periodEnd 메서드가 현재 timestamp를 반환해야 함
        let helper = YFDateHelper()
        let timestamp = helper.periodEnd()
        
        let currentTimestamp = String(Int(Date().timeIntervalSince1970))
        
        // 타임스탬프가 대략적으로 맞는지 확인
        let timestampInt = Int(timestamp) ?? 0
        let currentInt = Int(currentTimestamp) ?? 0
        #expect(abs(timestampInt - currentInt) < 2) // 2초 이내 차이 허용
    }
    
    @Test("periodToRangeString converts period to string")
    func testPeriodToRangeString() {
        // Red: periodToRangeString이 올바른 문자열을 반환해야 함
        let helper = YFDateHelper()
        
        #expect(helper.periodToRangeString(.oneDay) == "1d")
        #expect(helper.periodToRangeString(.oneWeek) == "5d")
        #expect(helper.periodToRangeString(.oneMonth) == "1mo")
        #expect(helper.periodToRangeString(.threeMonths) == "3mo")
        #expect(helper.periodToRangeString(.sixMonths) == "6mo")
        #expect(helper.periodToRangeString(.oneYear) == "1y")
        #expect(helper.periodToRangeString(.twoYears) == "2y")
        #expect(helper.periodToRangeString(.fiveYears) == "5y")
        #expect(helper.periodToRangeString(.tenYears) == "10y")
        #expect(helper.periodToRangeString(.max) == "max")
    }
    
    @Test("dateFromPeriod returns correct date")
    func testDateFromPeriod() {
        // Red: dateFromPeriod이 올바른 날짜를 반환해야 함
        let helper = YFDateHelper()
        let calendar = Calendar.current
        
        let oneDayAgo = helper.dateFromPeriod(.oneDay)
        let expectedOneDay = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        
        // 날짜가 대략적으로 맞는지 확인 (몇 초 차이는 허용)
        let difference = abs(oneDayAgo.timeIntervalSince(expectedOneDay))
        #expect(difference < 60) // 60초 이내 차이 허용
    }
}