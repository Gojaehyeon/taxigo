import SwiftUI
import SwiftData

/// History screen styled to match the Pro-1 meter face: silver bezel,
/// dark VFD panel, cyan 7-segment digits, pill buttons.
struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Trip.endedAt, order: .reverse) private var trips: [Trip]
    @AppStorage("coffeePricePerCup") private var coffeePricePerCup: Int = 5_000

    private let currency: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f
    }()

    var body: some View {
        ZStack {
            Color(red: 0.11, green: 0.11, blue: 0.12).ignoresSafeArea()
            VStack(spacing: 10) {
                bezeledSummary
                tripListPanel
            }
            .padding(.horizontal, 10)
            .padding(.top, 0)
            .padding(.bottom, 6)
        }
    }

    // MARK: - Top bezel summary

    private var bezeledSummary: some View {
        VStack(spacing: 0) {
            header
            displayPanel
            bottomLegend
        }
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color.bezelOuter, location: 0.00),
                                .init(color: Color.bezelMid,   location: 0.08),
                                .init(color: Color.bezelOuter, location: 0.18),
                                .init(color: Color.bezelMid,   location: 0.55),
                                .init(color: Color.bezelInner, location: 0.85),
                                .init(color: Color.bezelMid,   location: 1.00),
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.55), Color.white.opacity(0.0)],
                            startPoint: .top, endPoint: .center
                        ),
                        lineWidth: 1.2
                    )
                Canvas { ctx, size in
                    for y in stride(from: 0, to: size.height, by: 1.5) {
                        let alpha = Double.random(in: 0.0...0.05)
                        let rect = CGRect(x: 0, y: y, width: size.width, height: 0.7)
                        ctx.fill(Path(rect), with: .color(.white.opacity(alpha)))
                    }
                }
                .mask(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .allowsHitTesting(false)
                .blendMode(.overlay)
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.bezelInner.opacity(0.7), lineWidth: 1)
            }
        )
        .shadow(color: .black.opacity(0.65), radius: 14, y: 6)
    }

    private var header: some View {
        HStack {
            HStack(spacing: 4) {
                Text("JIE")
                    .font(.system(size: 10, weight: .black, design: .serif).italic())
                    .foregroundStyle(.black)
                Text("TAXIGO")
                    .font(.system(size: 10, weight: .heavy, design: .serif))
                    .foregroundStyle(.black)
            }
            Text("TOTAL")
                .font(.system(size: 8, weight: .medium, design: .serif))
                .foregroundStyle(.black.opacity(0.7))
                .padding(.leading, 4)
            Spacer()
            Text("HISTORY")
                .font(.system(size: 12, weight: .heavy, design: .serif).italic())
                .foregroundStyle(.black)
            Spacer()
            Text("COFFEE")
                .font(.system(size: 10, weight: .black, design: .serif))
                .foregroundStyle(.black)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    private var displayPanel: some View {
        HStack(spacing: 14) {
            sideIndicators
            coffeeHero
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.black)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.black.opacity(0.9), lineWidth: 2)
                )
        )
        .padding(.horizontal, 8)
        .padding(.bottom, 2)
    }

    private var sideIndicators: some View {
        VStack(alignment: .leading, spacing: 8) {
            HistoryIndicator(label: "TRIPS", subscriptNum: 1, isActive: !trips.isEmpty)
            HistoryIndicator(label: "PAID",  subscriptNum: 2, isActive: !trips.isEmpty)
            HistoryIndicator(label: "MILES", subscriptNum: 3, isActive: !trips.isEmpty)
            HistoryIndicator(label: "DEBT",  subscriptNum: 7, isActive: !trips.isEmpty)
        }
        .fixedSize()
    }

    private var coffeeHero: some View {
        VStack(alignment: .trailing, spacing: 10) {
            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TRIPS")
                        .font(.system(size: 9, weight: .black, design: .serif).italic())
                        .foregroundStyle(Color.meterCyan.opacity(0.6))
                    SegmentedText(
                        text: String(format: "%03d", trips.count),
                        activeColor: .meterCyan,
                        digitWidth: 11, digitHeight: 22, spacing: 2
                    )
                }
                Spacer()
                VStack(alignment: .leading, spacing: 2) {
                    Text("CUPS")
                        .font(.system(size: 9, weight: .black, design: .serif).italic())
                        .foregroundStyle(Color.taxiOrange.opacity(0.7))
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        SegmentedText(
                            text: String(format: "%04d", Int(totalCoffees * 10)),
                            activeColor: .taxiOrange,
                            digitWidth: 22, digitHeight: 48, spacing: 3
                        )
                    }
                }
            }
            Rectangle()
                .fill(Color.meterCyan.opacity(0.2))
                .frame(height: 1)
            HStack {
                Text("TOTAL km")
                    .font(.system(size: 8, weight: .black, design: .serif).italic())
                    .foregroundStyle(Color.meterCyan.opacity(0.5))
                Spacer()
                SegmentedText(
                    text: String(format: "%05.1f", totalDistanceKm),
                    activeColor: .meterCyan,
                    digitWidth: 10, digitHeight: 20, spacing: 2
                )
                Spacer()
                Text("AMOUNT")
                    .font(.system(size: 8, weight: .black, design: .serif).italic())
                    .foregroundStyle(Color.taxiGreen.opacity(0.5))
                Spacer()
                SegmentedText(
                    text: formattedAmount(totalAmount),
                    activeColor: .taxiGreen,
                    digitWidth: 10, digitHeight: 20, spacing: 2
                )
            }
        }
    }

    private var bottomLegend: some View {
        HStack {
            Text("1.TRIPs 2.PAID 3.MILES 4.CUPS 5.AMOUNT")
                .font(.system(size: 8, weight: .medium, design: .serif))
                .foregroundStyle(.black.opacity(0.7))
            Spacer()
            Text("S.No: \(String(format: "%03d", trips.count))")
                .font(.system(size: 8, weight: .medium, design: .serif))
                .foregroundStyle(.black.opacity(0.7))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 4)
    }

    // MARK: - Trip list

    private var tripListPanel: some View {
        Group {
            if trips.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(trips) { trip in
                            tripRow(trip)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                }
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.black)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.meterPanelEdge, lineWidth: 1)
                        )
                )
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "car.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.meterCyan.opacity(0.25))
            Text("NO TRIPS LOGGED")
                .font(.system(size: 12, weight: .black, design: .monospaced))
                .tracking(3)
                .foregroundStyle(Color.meterCyan.opacity(0.4))
            Text("미터기에서 주행을 완료하면 여기 기록됩니다")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 60)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.black)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.meterPanelEdge, lineWidth: 1)
                )
        )
    }

    private func tripRow(_ trip: Trip) -> some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(trip.friendName?.uppercased() ?? "NO NAME")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .tracking(1.5)
                    .foregroundStyle(Color.meterCyan)
                Text(formattedDate(trip.endedAt))
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.meterCyan.opacity(0.45))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                SegmentedText(
                    text: formattedAmount(trip.totalFare),
                    activeColor: .taxiGreen,
                    digitWidth: 9, digitHeight: 16, spacing: 1
                )
                HStack(spacing: 4) {
                    Text("☕")
                        .font(.system(size: 10))
                    SegmentedText(
                        text: String(format: "%03d", Int(trip.coffeeCups * 10)),
                        activeColor: .taxiOrange,
                        digitWidth: 8, digitHeight: 14, spacing: 1
                    )
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.meterPanel)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.meterCyan.opacity(0.12), lineWidth: 0.7)
                )
        )
        .contextMenu {
            Button(role: .destructive) {
                modelContext.delete(trip)
                try? modelContext.save()
            } label: { Label("삭제", systemImage: "trash") }
        }
    }

    // MARK: - Computed values

    private var totalCoffees: Double {
        let price = max(1, coffeePricePerCup)
        let totalWon = trips.reduce(0) { $0 + $1.totalFare }
        return (Double(totalWon) / Double(price) * 10).rounded() / 10
    }

    private var totalDistanceKm: Double {
        trips.reduce(0) { $0 + $1.distanceMeters } / 1000
    }

    private var totalAmount: Int {
        trips.reduce(0) { $0 + $1.totalFare }
    }

    private func formattedAmount(_ won: Int) -> String {
        currency.string(from: NSNumber(value: won)) ?? "\(won)"
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f.string(from: date)
    }
}

// MARK: - Indicator label

private struct HistoryIndicator: View {
    let label: String
    let subscriptNum: Int
    let isActive: Bool

    var body: some View {
        HStack(spacing: 2) {
            Rectangle()
                .fill(isActive ? Color.meterCyan : Color.white.opacity(0.05))
                .frame(width: 7, height: 7)
                .shadow(color: isActive ? Color.meterCyan.opacity(0.7) : .clear, radius: 4)
            Text(label)
                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                .tracking(-0.5)
                .foregroundStyle(isActive ? Color.meterCyan : Color.white.opacity(0.22))
                .shadow(color: isActive ? Color.meterCyan.opacity(0.5) : .clear, radius: 3)
                .fixedSize()
            Text("\(subscriptNum)")
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundStyle(isActive ? Color.meterCyan.opacity(0.8) : Color.white.opacity(0.18))
                .baselineOffset(-3)
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: [Trip.self], inMemory: true)
        .preferredColorScheme(.dark)
}
