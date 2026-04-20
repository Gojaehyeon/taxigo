import Foundation
import SwiftData

@Model
final class Trip {
    var id: UUID
    var startedAt: Date
    var endedAt: Date
    var distanceMeters: Double
    var durationSeconds: Double
    var baseFare: Int
    var distanceFee: Int
    var timeFee: Int
    var surchargeRaw: String
    var totalFare: Int
    var friendName: String?
    var coffeePricePerCup: Int
    var note: String?

    init(
        id: UUID = UUID(),
        startedAt: Date,
        endedAt: Date,
        distanceMeters: Double,
        durationSeconds: Double,
        breakdown: FareBreakdown,
        friendName: String? = nil,
        coffeePricePerCup: Int = 5_000,
        note: String? = nil
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.distanceMeters = distanceMeters
        self.durationSeconds = durationSeconds
        self.baseFare = breakdown.baseFare
        self.distanceFee = breakdown.distanceFee
        self.timeFee = breakdown.timeFee
        self.surchargeRaw = breakdown.surcharge.rawValue
        self.totalFare = breakdown.total
        self.friendName = friendName
        self.coffeePricePerCup = coffeePricePerCup
        self.note = note
    }

    var surcharge: SurchargeMode {
        SurchargeMode(rawValue: surchargeRaw) ?? .none
    }

    var coffeeCups: Double {
        guard coffeePricePerCup > 0 else { return 0 }
        return (Double(totalFare) / Double(coffeePricePerCup) * 10).rounded() / 10
    }
}
