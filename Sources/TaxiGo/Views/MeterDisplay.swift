import SwiftUI

struct MeterDisplay: View {
    let fare: Int
    let label: String
    let glowing: Bool

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                SegmentedNumber(
                    value: fare,
                    digits: 5,
                    activeColor: .meterCyan,
                    digitWidth: 40,
                    digitHeight: 76,
                    spacing: 6
                )
                Text("원")
                    .font(.system(size: 30, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.meterCyan)
                    .shadow(color: Color.meterCyan.opacity(0.7), radius: 6)
            }
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .tracking(4)
                .foregroundStyle(Color.meterCyan.opacity(0.45))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.meterPanel)
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color.meterPanelEdge, lineWidth: 1.5)
                )
                .shadow(color: Color.meterCyan.opacity(glowing ? 0.25 : 0.0), radius: 28)
        )
    }
}

#Preview {
    ZStack {
        Color.meterBackground.ignoresSafeArea()
        MeterDisplay(fare: 4800, label: "FARE / 요금", glowing: true)
            .padding()
    }
    .preferredColorScheme(.dark)
}
