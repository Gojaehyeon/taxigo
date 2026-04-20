import Foundation
#if canImport(UIKit)
import UIKit
#endif

@MainActor
final class HapticEngine {
    static let shared = HapticEngine()
    var isEnabled: Bool = true
    private init() {}

    func tick() {
        guard isEnabled else { return }
        #if canImport(UIKit)
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.prepare()
        gen.impactOccurred(intensity: 0.55)
        #endif
    }

    func surcharge() {
        guard isEnabled else { return }
        #if canImport(UIKit)
        let gen = UIImpactFeedbackGenerator(style: .medium)
        gen.prepare()
        gen.impactOccurred()
        #endif
    }

    func receipt() {
        guard isEnabled else { return }
        #if canImport(UIKit)
        let gen = UINotificationFeedbackGenerator()
        gen.prepare()
        gen.notificationOccurred(.success)
        #endif
    }
}
