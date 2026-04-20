import SwiftUI

extension Color {
    // Deep metallic body — the plastic case of a 중앙산전 Pro-1
    static let meterBackground = Color(red: 0.035, green: 0.042, blue: 0.052)
    static let meterPanel      = Color(red: 0.020, green: 0.028, blue: 0.040)
    static let meterPanelEdge  = Color(red: 0.110, green: 0.135, blue: 0.160)

    // Signature VFD cyan — the color Korean taxi meters have burned into our retinas
    // Slightly shifted toward white for that high-intensity VFD phosphor glow.
    static let meterCyan       = Color(red: 0.560, green: 0.995, blue: 0.980)
    static let meterCyanDim    = Color(red: 0.130, green: 0.330, blue: 0.335)
    static let meterWhite      = Color(red: 0.950, green: 0.995, blue: 0.995)

    // Accents — used sparingly, only where the real meters light up differently
    static let taxiRed         = Color(red: 1.000, green: 0.176, blue: 0.125)
    static let taxiRedDim      = Color(red: 0.352, green: 0.066, blue: 0.031)
    static let taxiOrange      = Color(red: 1.000, green: 0.654, blue: 0.149)
    static let taxiGreen       = Color(red: 0.223, green: 1.000, blue: 0.533)
    static let taxiBlue        = Color(red: 0.110, green: 0.654, blue: 1.000)

    // Horse silhouette green — the galloping-horse indicator color on modern
    // TFT taxi meters (한국MTS / 코나아이 세대)
    static let horseGreen      = Color(red: 0.295, green: 0.880, blue: 0.395)

    // Ghost segment shown behind active digits (VFD "off" segment glow)
    static let meterOffGlyph   = Color(red: 0.068, green: 0.110, blue: 0.128)

    // Silver/metallic bezel tones that frame the real Pro-1 meter
    static let bezelOuter      = Color(red: 0.880, green: 0.882, blue: 0.895)
    static let bezelMid        = Color(red: 0.720, green: 0.722, blue: 0.740)
    static let bezelInner      = Color(red: 0.490, green: 0.495, blue: 0.520)

    // Yellow/amber physical button row at the bottom of the Pro-1
    static let physicalButton  = Color(red: 0.960, green: 0.770, blue: 0.165)
    static let physicalButtonDeep = Color(red: 0.640, green: 0.460, blue: 0.070)
    static let physicalButtonStop = Color(red: 0.970, green: 0.355, blue: 0.110)
}

// MARK: - Seven-segment digit
//
// Classic VFD segment layout:
//      a
//    ━━━━━
//   ┃     ┃
// f ┃     ┃ b
//   ┃  g  ┃
//    ━━━━━
//   ┃     ┃
// e ┃     ┃ c
//   ┃     ┃
//    ━━━━━
//      d
//

private enum Seg: Int, CaseIterable { case a, b, c, d, e, f, g }

private let segmentsForDigit: [Int: Set<Seg>] = [
    0: [.a, .b, .c, .d, .e, .f],
    1: [.b, .c],
    2: [.a, .b, .d, .e, .g],
    3: [.a, .b, .c, .d, .g],
    4: [.b, .c, .f, .g],
    5: [.a, .c, .d, .f, .g],
    6: [.a, .c, .d, .e, .f, .g],
    7: [.a, .b, .c],
    8: [.a, .b, .c, .d, .e, .f, .g],
    9: [.a, .b, .c, .d, .f, .g],
]

struct SevenSegmentDigit: View {
    let digit: Int?
    let color: Color
    var ghostColor: Color = .meterOffGlyph
    var thickness: CGFloat = 0.16  // as fraction of min(w,h)

    var body: some View {
        Canvas { ctx, size in
            let on = (digit.flatMap { segmentsForDigit[$0] }) ?? []
            let w = size.width
            let h = size.height
            let t = min(w, h) * thickness
            let g = t * 0.25
            let midY = h / 2

            let horiz: [(seg: Seg, y: CGFloat)] = [
                (.a, 0),
                (.g, midY - t / 2),
                (.d, h - t)
            ]
            for (seg, y) in horiz {
                let path = horizontalSegmentPath(x: 0, y: y, width: w, thickness: t, gap: g)
                ctx.fill(path, with: .color(ghostColor))
                if on.contains(seg) {
                    ctx.fill(path, with: .color(color))
                }
            }

            let vert: [(seg: Seg, x: CGFloat, y: CGFloat)] = [
                (.f, 0, 0),
                (.b, w - t, 0),
                (.e, 0, midY),
                (.c, w - t, midY),
            ]
            for (seg, x, y) in vert {
                let path = verticalSegmentPath(x: x, y: y, height: midY, thickness: t, gap: g)
                ctx.fill(path, with: .color(ghostColor))
                if on.contains(seg) {
                    ctx.fill(path, with: .color(color))
                }
            }
        }
        .shadow(color: color.opacity(digit != nil ? 0.85 : 0.0), radius: 3)
        .shadow(color: color.opacity(digit != nil ? 0.55 : 0.0), radius: 8)
        .shadow(color: color.opacity(digit != nil ? 0.25 : 0.0), radius: 16)
    }

    // Horizontal segment — hexagonal bar (pointed ends)
    private func horizontalSegmentPath(x: CGFloat, y: CGFloat, width: CGFloat, thickness t: CGFloat, gap g: CGFloat) -> Path {
        var p = Path()
        let half = t / 2
        p.move(to: CGPoint(x: x + g, y: y + half))
        p.addLine(to: CGPoint(x: x + half + g, y: y))
        p.addLine(to: CGPoint(x: x + width - half - g, y: y))
        p.addLine(to: CGPoint(x: x + width - g, y: y + half))
        p.addLine(to: CGPoint(x: x + width - half - g, y: y + t))
        p.addLine(to: CGPoint(x: x + half + g, y: y + t))
        p.closeSubpath()
        return p
    }

    // Vertical segment — hexagonal bar (pointed ends)
    private func verticalSegmentPath(x: CGFloat, y: CGFloat, height: CGFloat, thickness t: CGFloat, gap g: CGFloat) -> Path {
        var p = Path()
        let half = t / 2
        p.move(to: CGPoint(x: x + half, y: y + g))
        p.addLine(to: CGPoint(x: x + t, y: y + half + g))
        p.addLine(to: CGPoint(x: x + t, y: y + height - half - g))
        p.addLine(to: CGPoint(x: x + half, y: y + height - g))
        p.addLine(to: CGPoint(x: x, y: y + height - half - g))
        p.addLine(to: CGPoint(x: x, y: y + half + g))
        p.closeSubpath()
        return p
    }
}

/// Multi-digit 7-segment number. Leading zeros shown dim as "ghost 8" behind.
struct SegmentedNumber: View {
    let value: Int
    let digits: Int
    let activeColor: Color
    var ghostColor: Color = .meterOffGlyph
    var digitWidth: CGFloat = 44
    var digitHeight: CGFloat = 78
    var spacing: CGFloat = 6

    var body: some View {
        let text = String(format: "%0\(digits)d", max(0, value))
        let chars = Array(text)
        // Show leading zeros as ghosts — figure out the first non-zero index.
        let firstNonZero = chars.firstIndex(where: { $0 != "0" }) ?? (chars.count - 1)

        HStack(spacing: spacing) {
            ForEach(Array(chars.enumerated()), id: \.offset) { index, char in
                let isLeadingGhost = value > 0 && index < firstNonZero
                let digitValue = isLeadingGhost ? nil : Int(String(char))
                SevenSegmentDigit(digit: digitValue, color: activeColor, ghostColor: ghostColor)
                    .frame(width: digitWidth, height: digitHeight)
            }
        }
    }
}

/// Compact 7-seg for small readouts (거리, 시간 etc.).
/// Accepts a raw string — supports 0-9, space, '.', ':'.
struct SegmentedText: View {
    let text: String
    let activeColor: Color
    var digitWidth: CGFloat = 14
    var digitHeight: CGFloat = 26
    var spacing: CGFloat = 2

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(Array(text.enumerated()), id: \.offset) { _, ch in
                Group {
                    switch ch {
                    case " ":
                        Color.clear.frame(width: digitWidth, height: digitHeight)
                    case ".":
                        VStack {
                            Spacer()
                            Circle()
                                .fill(activeColor)
                                .frame(width: digitWidth * 0.22, height: digitWidth * 0.22)
                                .shadow(color: activeColor.opacity(0.7), radius: 3)
                        }
                        .frame(width: digitWidth * 0.4, height: digitHeight)
                    case ":":
                        VStack(spacing: digitHeight * 0.18) {
                            Circle().fill(activeColor).frame(width: digitWidth * 0.22, height: digitWidth * 0.22)
                            Circle().fill(activeColor).frame(width: digitWidth * 0.22, height: digitWidth * 0.22)
                        }
                        .shadow(color: activeColor.opacity(0.6), radius: 3)
                        .frame(width: digitWidth * 0.4, height: digitHeight)
                    default:
                        SevenSegmentDigit(
                            digit: Int(String(ch)),
                            color: activeColor
                        )
                        .frame(width: digitWidth, height: digitHeight)
                    }
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.meterBackground.ignoresSafeArea()
        VStack(spacing: 24) {
            SegmentedNumber(value: 4800, digits: 5, activeColor: .meterCyan)
            SegmentedNumber(value: 12345, digits: 5, activeColor: .meterCyan)
            SegmentedText(text: "12:34", activeColor: .meterCyan)
            SegmentedText(text: "3.14", activeColor: .meterCyan)
        }
    }
    .preferredColorScheme(.dark)
}
