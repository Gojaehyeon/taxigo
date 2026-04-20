import SwiftUI

struct IndicatorBar: View {
    let active: Set<MeterIndicator>
    let surchargePulse: Bool

    private let order: [MeterIndicator] = [.empty, .running, .surcharge, .paid, .combined]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(order, id: \.self) { indicator in
                IndicatorPill(
                    label: indicator.label,
                    isActive: active.contains(indicator),
                    color: color(for: indicator),
                    pulse: indicator == .surcharge && active.contains(.surcharge) && surchargePulse
                )
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.meterPanel)
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(Color.meterPanelEdge, lineWidth: 1)
                )
        )
    }

    private func color(for indicator: MeterIndicator) -> Color {
        switch indicator {
        case .empty:     .meterCyan
        case .running:   .meterCyan
        case .surcharge: .taxiRed
        case .paid:      .taxiOrange
        case .combined:  .meterCyan
        }
    }
}

private struct IndicatorPill: View {
    let label: String
    let isActive: Bool
    let color: Color
    let pulse: Bool

    var body: some View {
        Text(label)
            .font(.system(size: 13, weight: .black, design: .rounded))
            .tracking(1.5)
            .foregroundStyle(isActive ? .white : Color.white.opacity(0.25))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(isActive ? color : Color.white.opacity(0.03))
                    .shadow(color: isActive ? color.opacity(0.55) : .clear, radius: 10)
            )
            .opacity(pulse ? 0.45 : 1.0)
            .animation(
                pulse
                    ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true)
                    : .default,
                value: pulse
            )
    }
}

#Preview {
    ZStack {
        Color.meterBackground.ignoresSafeArea()
        IndicatorBar(active: [.running, .surcharge], surchargePulse: true)
            .padding()
    }
    .preferredColorScheme(.dark)
}
