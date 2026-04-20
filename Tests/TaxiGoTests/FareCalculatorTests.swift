import XCTest
@testable import TaxiGo

final class FareCalculatorTests: XCTestCase {
    func test_baseFareOnly_whenUnderBaseDistance() {
        let tick = MeterTick(timestamp: .now, deltaDistance: 1_500, speed: 20, deltaTime: 60)
        let out = FareCalculator.calculate(ticks: [tick])
        XCTAssertEqual(out.baseFare, 4_800)
        XCTAssertEqual(out.distanceFee, 0)
        XCTAssertEqual(out.timeFee, 0)
        XCTAssertEqual(out.total, 4_800)
    }

    func test_exactlyAtBaseDistance_staysAtBase() {
        let tick = MeterTick(timestamp: .now, deltaDistance: 1_600, speed: 20, deltaTime: 60)
        let out = FareCalculator.calculate(ticks: [tick])
        XCTAssertEqual(out.total, 4_800)
    }

    func test_distanceBilling_oneIncrementAfterBase() {
        // Go 1,600m base then 131m extra — should add 100 won.
        let base = MeterTick(timestamp: .now, deltaDistance: 1_600, speed: 20, deltaTime: 60)
        let over = MeterTick(timestamp: .now, deltaDistance: 131, speed: 20, deltaTime: 5)
        let out = FareCalculator.calculate(ticks: [base, over])
        XCTAssertEqual(out.baseFare, 4_800)
        XCTAssertEqual(out.distanceFee, 100)
        XCTAssertEqual(out.total, 4_900)
    }

    func test_distanceBilling_multipleIncrements() {
        // 1,600 base + 131*5 = 655 extra meters → 500 won distance fee
        var ticks: [MeterTick] = [MeterTick(timestamp: .now, deltaDistance: 1_600, speed: 20, deltaTime: 60)]
        for _ in 0..<5 {
            ticks.append(MeterTick(timestamp: .now, deltaDistance: 131, speed: 20, deltaTime: 5))
        }
        let out = FareCalculator.calculate(ticks: ticks)
        XCTAssertEqual(out.distanceFee, 500)
        XCTAssertEqual(out.total, 5_300)
    }

    func test_timeBilling_whenBelowLowSpeedThreshold() {
        // After base distance, slow crawl for 30 seconds → 100 won
        let base = MeterTick(timestamp: .now, deltaDistance: 1_600, speed: 20, deltaTime: 60)
        let crawl = MeterTick(timestamp: .now, deltaDistance: 10, speed: 1.0, deltaTime: 30)
        let out = FareCalculator.calculate(ticks: [base, crawl])
        XCTAssertEqual(out.timeFee, 100)
        XCTAssertEqual(out.total, 4_900)
    }

    func test_surchargeMultiplier_night20() {
        let tick = MeterTick(timestamp: .now, deltaDistance: 1_500, speed: 20, deltaTime: 60)
        let out = FareCalculator.calculate(ticks: [tick], surcharge: .night20)
        XCTAssertEqual(out.total, 5_760) // 4800 * 1.2
    }

    func test_surchargeMultiplier_night40() {
        let tick = MeterTick(timestamp: .now, deltaDistance: 1_500, speed: 20, deltaTime: 60)
        let out = FareCalculator.calculate(ticks: [tick], surcharge: .night40)
        XCTAssertEqual(out.total, 6_720) // 4800 * 1.4
    }

    func test_ignoresNegativeDeltas() {
        let tick = MeterTick(timestamp: .now, deltaDistance: -50, speed: -10, deltaTime: -5)
        let out = FareCalculator.calculate(ticks: [tick])
        XCTAssertEqual(out.total, 4_800)
    }

    func test_breakdownSumsUp() {
        let base = MeterTick(timestamp: .now, deltaDistance: 1_600, speed: 20, deltaTime: 60)
        let over = MeterTick(timestamp: .now, deltaDistance: 400, speed: 20, deltaTime: 15)
        let crawl = MeterTick(timestamp: .now, deltaDistance: 2, speed: 1, deltaTime: 60)
        let out = FareCalculator.calculate(ticks: [base, over, crawl], surcharge: .none)
        XCTAssertEqual(out.subtotal, out.baseFare + out.distanceFee + out.timeFee)
        XCTAssertEqual(out.total, out.subtotal)
    }
}
