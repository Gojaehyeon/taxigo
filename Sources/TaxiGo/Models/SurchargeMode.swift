import Foundation

enum SurchargeMode: String, Codable, CaseIterable, Sendable {
    case none
    case night20
    case night40
    case outside20

    var multiplier: Double {
        switch self {
        case .none: 1.00
        case .night20, .outside20: 1.20
        case .night40: 1.40
        }
    }

    var label: String {
        switch self {
        case .none: "일반"
        case .night20: "심야+20%"
        case .night40: "심야+40%"
        case .outside20: "시외+20%"
        }
    }
}
