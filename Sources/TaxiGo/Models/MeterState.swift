import Foundation

enum MeterState: String, Sendable {
    case idle        // 빈차
    case running     // 주행
    case finished    // 지불
}

enum MeterIndicator: String, CaseIterable, Hashable, Sendable {
    case empty      // 빈차
    case running    // 주행
    case surcharge  // 할증
    case paid       // 지불
    case combined   // 복합

    var label: String {
        switch self {
        case .empty: "빈차"
        case .running: "주행"
        case .surcharge: "할증"
        case .paid: "지불"
        case .combined: "복합"
        }
    }
}

struct MeterTick: Sendable {
    let timestamp: Date
    /// meters moved since previous tick
    let deltaDistance: Double
    /// instantaneous speed, m/s (negative replaced with 0 by caller)
    let speed: Double
    /// total elapsed interval since previous tick, s
    let deltaTime: TimeInterval
}

struct FareBreakdown: Equatable, Sendable {
    var baseFare: Int
    var distanceFee: Int
    var timeFee: Int
    var subtotal: Int
    var surcharge: SurchargeMode
    var total: Int

    static let zero = FareBreakdown(
        baseFare: 0, distanceFee: 0, timeFee: 0,
        subtotal: 0, surcharge: .none, total: 0
    )
}
