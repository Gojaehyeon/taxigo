import Foundation

struct FareRule: Codable, Equatable, Sendable {
    var baseFare: Int
    var baseDistanceMeters: Double
    var distanceIncrementMeters: Double
    var distanceIncrementFee: Int
    var timeIncrementSeconds: TimeInterval
    var timeIncrementFee: Int
    var lowSpeedThresholdMetersPerSecond: Double

    /// Length of the grace period (in seconds) during which only the base fare
    /// is charged in time‑based billing mode. After this elapses, the meter
    /// starts ticking up by `timeIncrementFee` every `timeIncrementSeconds`.
    var baseDurationSeconds: TimeInterval

    static let seoul2026 = FareRule(
        baseFare: 4_800,
        baseDistanceMeters: 1_600,
        distanceIncrementMeters: 131,
        distanceIncrementFee: 100,
        timeIncrementSeconds: 5,
        timeIncrementFee: 100,
        lowSpeedThresholdMetersPerSecond: 15.0 * 1000.0 / 3600.0,
        baseDurationSeconds: 20
    )

    /// Compute fare purely from elapsed seconds (time‑based mode).
    /// Fare stays at `baseFare` for `baseDurationSeconds`, then increments
    /// by `timeIncrementFee` every `timeIncrementSeconds`.
    func timeBasedFare(elapsed: TimeInterval) -> (base: Int, timeFee: Int) {
        let extra = max(0, elapsed - baseDurationSeconds)
        let ticks = Int((extra / timeIncrementSeconds).rounded(.down))
        return (base: baseFare, timeFee: ticks * timeIncrementFee)
    }
}
