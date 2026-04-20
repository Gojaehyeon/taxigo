import Foundation

/// Pure, deterministic fare calculator.
/// Feed it ticks in order; it accumulates fare using the provided rule.
struct FareCalculator {
    let rule: FareRule

    private(set) var traveledMeters: Double = 0
    private(set) var baseFare: Int
    private(set) var distanceFee: Int = 0
    private(set) var timeFee: Int = 0
    private var distanceAccumulator: Double = 0
    private var timeAccumulator: TimeInterval = 0

    init(rule: FareRule = .seoul2026) {
        self.rule = rule
        self.baseFare = rule.baseFare
    }

    mutating func ingest(_ tick: MeterTick) {
        let dd = max(0, tick.deltaDistance)
        let dt = max(0, tick.deltaTime)
        let speed = max(0, tick.speed)

        traveledMeters += dd

        if traveledMeters <= rule.baseDistanceMeters {
            return
        }

        // Distance that actually counts against the meter this tick
        let excessBefore = max(0, (traveledMeters - dd) - rule.baseDistanceMeters)
        let excessAfter = traveledMeters - rule.baseDistanceMeters
        let billableDistance = max(0, excessAfter - max(0, excessBefore))

        if speed >= rule.lowSpeedThresholdMetersPerSecond {
            distanceAccumulator += billableDistance
            while distanceAccumulator >= rule.distanceIncrementMeters {
                distanceFee += rule.distanceIncrementFee
                distanceAccumulator -= rule.distanceIncrementMeters
            }
        } else {
            timeAccumulator += dt
            while timeAccumulator >= rule.timeIncrementSeconds {
                timeFee += rule.timeIncrementFee
                timeAccumulator -= rule.timeIncrementSeconds
            }
        }
    }

    func breakdown(surcharge: SurchargeMode = .none) -> FareBreakdown {
        let subtotal = baseFare + distanceFee + timeFee
        let total = Int((Double(subtotal) * surcharge.multiplier).rounded())
        return FareBreakdown(
            baseFare: baseFare,
            distanceFee: distanceFee,
            timeFee: timeFee,
            subtotal: subtotal,
            surcharge: surcharge,
            total: total
        )
    }

    /// Convenience for tests / one-shot calculation.
    static func calculate(
        ticks: [MeterTick],
        rule: FareRule = .seoul2026,
        surcharge: SurchargeMode = .none
    ) -> FareBreakdown {
        var calc = FareCalculator(rule: rule)
        for tick in ticks { calc.ingest(tick) }
        return calc.breakdown(surcharge: surcharge)
    }
}
