import XCTest
@testable import TaxiGo

final class SurchargeClockTests: XCTestCase {
    private func date(hour: Int) -> Date {
        var comps = DateComponents()
        comps.year = 2026
        comps.month = 4
        comps.day = 20
        comps.hour = hour
        comps.minute = 30
        comps.timeZone = TimeZone(identifier: "Asia/Seoul")
        return Calendar(identifier: .gregorian).date(from: comps)!
    }

    func test_dayTime_isNone() {
        let clock = SurchargeClock()
        XCTAssertEqual(clock.mode(for: date(hour: 10)), .none)
        XCTAssertEqual(clock.mode(for: date(hour: 14)), .none)
        XCTAssertEqual(clock.mode(for: date(hour: 21)), .none)
    }

    func test_22Hour_isNight20() {
        XCTAssertEqual(SurchargeClock().mode(for: date(hour: 22)), .night20)
    }

    func test_23To01_isNight40() {
        let c = SurchargeClock()
        XCTAssertEqual(c.mode(for: date(hour: 23)), .night40)
        XCTAssertEqual(c.mode(for: date(hour: 0)), .night40)
        XCTAssertEqual(c.mode(for: date(hour: 1)), .night40)
    }

    func test_02To03_isNight20() {
        let c = SurchargeClock()
        XCTAssertEqual(c.mode(for: date(hour: 2)), .night20)
        XCTAssertEqual(c.mode(for: date(hour: 3)), .night20)
    }

    func test_04Hour_isNone() {
        XCTAssertEqual(SurchargeClock().mode(for: date(hour: 4)), .none)
    }
}
