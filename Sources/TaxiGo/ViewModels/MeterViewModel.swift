import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class MeterViewModel {
    // MARK: - Public state
    var state: MeterState = .idle
    var rule: FareRule = .seoul2026
    var surcharge: SurchargeMode = .none
    var autoSurcharge: Bool = true

    var startedAt: Date?
    var endedAt: Date?
    var elapsed: TimeInterval = 0
    var distanceMeters: Double = 0
    var currentSpeedKmh: Double = 0

    var lastBreakdown: FareBreakdown = .zero
    var completedTrip: Trip?

    // MARK: - Services
    private let locationService: LocationService
    private let clock: SurchargeClock
    private var calculator: FareCalculator
    private var tickerTask: Task<Void, Never>?
    private var previousFare: Int

    init(
        locationService: LocationService? = nil,
        clock: SurchargeClock = SurchargeClock()
    ) {
        self.locationService = locationService ?? LocationService()
        self.clock = clock
        self.calculator = FareCalculator(rule: .seoul2026)
        self.previousFare = FareRule.seoul2026.baseFare
        self.lastBreakdown = self.calculator.breakdown(surcharge: .none)

        self.locationService.onTick = { [weak self] tick in
            self?.handle(tick: tick)
        }
    }

    // MARK: - Control

    func requestLocationPermission() {
        locationService.requestPermission()
    }

    func start() {
        guard state != .running else { return }
        calculator = FareCalculator(rule: rule)
        startedAt = Date()
        endedAt = nil
        elapsed = 0
        distanceMeters = 0
        previousFare = rule.baseFare
        updateSurchargeFromClock()
        state = .running
        // Time‑based billing: no GPS required.
        runTimer()
        HapticEngine.shared.tick()
    }

    func stop() {
        guard state == .running else { return }
        endedAt = Date()
        state = .finished
        locationService.stop()
        tickerTask?.cancel()
        tickerTask = nil
        refreshTimeBasedFare()
        SoundPlayer.shared.receipt()
        HapticEngine.shared.receipt()
    }

    func reset() {
        tickerTask?.cancel()
        tickerTask = nil
        locationService.stop()
        state = .idle
        startedAt = nil
        endedAt = nil
        elapsed = 0
        distanceMeters = 0
        calculator = FareCalculator(rule: rule)
        previousFare = rule.baseFare
        lastBreakdown = calculator.breakdown(surcharge: .none)
        completedTrip = nil
    }

    func toggleSurcharge() {
        autoSurcharge = false
        surcharge = switch surcharge {
        case .none: .night20
        case .night20: .night40
        case .night40: .outside20
        case .outside20: .none
        }
        refreshBreakdown()
    }

    // MARK: - Derived view helpers

    var indicators: Set<MeterIndicator> {
        switch state {
        case .idle:
            return [.empty]
        case .running:
            var set: Set<MeterIndicator> = [.running]
            if surcharge != .none { set.insert(.surcharge) }
            return set
        case .finished:
            var set: Set<MeterIndicator> = [.paid]
            if surcharge != .none { set.insert(.surcharge) }
            return set
        }
    }

    var displayFare: Int { lastBreakdown.total }
    var distanceKm: Double { distanceMeters / 1_000 }

    var isInBaseDistance: Bool {
        distanceMeters < rule.baseDistanceMeters
    }

    // MARK: - Internal

    private func runTimer() {
        tickerTask?.cancel()
        tickerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 250_000_000)
                await MainActor.run {
                    guard let self, self.state == .running, let startedAt = self.startedAt else { return }
                    self.elapsed = Date().timeIntervalSince(startedAt)
                    self.updateSurchargeFromClock()
                    self.refreshTimeBasedFare()
                }
            }
        }
    }

    private func refreshTimeBasedFare() {
        let (base, timeFee) = rule.timeBasedFare(elapsed: elapsed)
        let subtotal = base + timeFee
        let total = Int((Double(subtotal) * surcharge.multiplier).rounded())
        let breakdown = FareBreakdown(
            baseFare: base,
            distanceFee: 0,
            timeFee: timeFee,
            subtotal: subtotal,
            surcharge: surcharge,
            total: total
        )
        if breakdown.total > previousFare {
            SoundPlayer.shared.tick()
            HapticEngine.shared.tick()
        }
        previousFare = breakdown.total
        lastBreakdown = breakdown
    }

    private func handle(tick: MeterTick) {
        // Time‑based billing ignores GPS ticks. Kept for API compatibility.
    }

    private func refreshBreakdown() {
        let next = calculator.breakdown(surcharge: surcharge)
        if next.total > previousFare {
            SoundPlayer.shared.tick()
            HapticEngine.shared.tick()
        }
        previousFare = next.total
        lastBreakdown = next
    }

    private func updateSurchargeFromClock() {
        guard autoSurcharge else { return }
        let auto = clock.mode(for: Date())
        if auto != surcharge {
            if auto != .none { SoundPlayer.shared.surcharge(); HapticEngine.shared.surcharge() }
            surcharge = auto
        }
    }

    // MARK: - Trip persistence

    func makeTrip(friendName: String?, coffeePricePerCup: Int = 5_000) -> Trip? {
        guard let startedAt, let endedAt else { return nil }
        let (base, timeFee) = rule.timeBasedFare(elapsed: endedAt.timeIntervalSince(startedAt))
        let subtotal = base + timeFee
        let total = Int((Double(subtotal) * surcharge.multiplier).rounded())
        let breakdown = FareBreakdown(
            baseFare: base, distanceFee: 0, timeFee: timeFee,
            subtotal: subtotal, surcharge: surcharge, total: total
        )
        let trip = Trip(
            startedAt: startedAt,
            endedAt: endedAt,
            distanceMeters: distanceMeters,
            durationSeconds: endedAt.timeIntervalSince(startedAt),
            breakdown: breakdown,
            friendName: friendName,
            coffeePricePerCup: coffeePricePerCup
        )
        completedTrip = trip
        return trip
    }
}
