import SwiftUI

/// Physical-looking 4×3 numeric keypad — the one on the right side of a
/// JIE JOONGANG Pro-1. Tapping a key stores the last-entered string in
/// `entry` and plays a click / haptic.
struct NumberKeypad: View {
    @Binding var entry: String
    var maxLength: Int = 6

    private let keys: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["*", "0", "#"],
    ]

    var body: some View {
        VStack(spacing: 6) {
            ForEach(keys, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(row, id: \.self) { key in
                        KeypadKey(label: key) { handleTap(key) }
                    }
                }
            }
        }
    }

    private func handleTap(_ key: String) {
        HapticEngine.shared.tick()
        SoundPlayer.shared.tick()
        if key == "*" {
            // backspace
            if !entry.isEmpty { entry.removeLast() }
        } else if key == "#" {
            // clear
            entry = ""
        } else {
            if entry.count < maxLength { entry.append(key) }
        }
    }
}

private struct KeypadKey: View {
    let label: String
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 20, weight: .black, design: .monospaced))
                .foregroundStyle(Color.meterCyan.opacity(0.95))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: pressed
                                    ? [Color(red: 0.05, green: 0.05, blue: 0.07), Color(red: 0.02, green: 0.02, blue: 0.03)]
                                    : [Color(red: 0.14, green: 0.14, blue: 0.16), Color(red: 0.07, green: 0.07, blue: 0.09)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(Color.meterCyan.opacity(0.25), lineWidth: 0.8)
                        )
                        .shadow(color: .black.opacity(pressed ? 0.1 : 0.5), radius: pressed ? 1 : 3, y: pressed ? 1 : 2)
                )
                .overlay(alignment: .top) {
                    // subtle gloss
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.10), Color.white.opacity(0.0)],
                                startPoint: .top, endPoint: .center
                            )
                        )
                        .padding(.horizontal, 2)
                        .padding(.top, 1)
                        .allowsHitTesting(false)
                }
        }
        .buttonStyle(.plain)
        .scaleEffect(pressed ? 0.96 : 1.0)
        .animation(.easeOut(duration: 0.08), value: pressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded { _ in pressed = false }
        )
    }
}

#Preview {
    @Previewable @State var entry = "1234"
    ZStack {
        Color.meterBackground.ignoresSafeArea()
        VStack(spacing: 14) {
            Text("ENTRY: \(entry)")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.meterCyan)
            NumberKeypad(entry: $entry)
                .padding(.horizontal, 20)
        }
    }
    .preferredColorScheme(.dark)
}
