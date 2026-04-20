import Foundation

/// Decides a surcharge mode from a given time of day (Seoul defaults).
struct SurchargeClock {
    var calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        return cal
    }()

    /// Seoul night rules:
    ///  - 22:00 – 23:00    → +20%
    ///  - 23:00 – 02:00    → +40%
    ///  - 02:00 – 04:00    → +20%
    ///  - otherwise        → none
    func mode(for date: Date) -> SurchargeMode {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case 22: return .night20
        case 23, 0, 1: return .night40
        case 2, 3: return .night20
        default: return .none
        }
    }
}
