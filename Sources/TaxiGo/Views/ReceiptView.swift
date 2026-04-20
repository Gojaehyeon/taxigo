import SwiftUI
import UIKit

struct ReceiptView: View {
    let trip: Trip
    let onSaved: () -> Void
    let onDismiss: () -> Void

    @State private var friendName: String = ""
    @State private var coffeePrice: Int = UserDefaults.standard.integer(forKey: "coffeePricePerCup")

    private let currency: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        return f
    }()

    private var effectiveCoffeePrice: Int {
        coffeePrice > 0 ? coffeePrice : 5_000
    }

    private func applyInputsToTrip() {
        trip.friendName = friendName.isEmpty ? nil : friendName
        trip.coffeePricePerCup = effectiveCoffeePrice
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 14) {
                    receiptCard
                        .padding(.horizontal, 18)

                    TextField("", text: $friendName, prompt: Text("친구 이름 (생략 가능)").foregroundStyle(.white.opacity(0.35)))
                        .textInputAutocapitalization(.never)
                        .padding(.horizontal, 14).padding(.vertical, 12)
                        .background(Rectangle().stroke(Color.white.opacity(0.25), lineWidth: 1))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)

                    HStack(spacing: 0) {
                        Text("커피 한 잔 가격")
                            .foregroundStyle(.white.opacity(0.6))
                        Spacer()
                        TextField("5000", value: $coffeePrice, formatter: NumberFormatter())
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 12)
                    .background(Rectangle().stroke(Color.white.opacity(0.25), lineWidth: 1))
                    .padding(.horizontal, 18)

                    HStack(spacing: 10) {
                        actionButton(title: "공유") {
                            applyInputsToTrip()
                            presentShare()
                        }
                        actionButton(title: "저장", primary: true) {
                            applyInputsToTrip()
                            UserDefaults.standard.set(effectiveCoffeePrice, forKey: "coffeePricePerCup")
                            onSaved()
                        }
                    }
                    .padding(.horizontal, 18)

                    Button("닫기 (저장하지 않음)") { onDismiss() }
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                        .padding(.bottom, 24)
                }
                .padding(.top, 20)
            }
        }
    }

    // MARK: - Receipt card

    private var receiptCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("TAXIGO / RECEIPT")
                    .font(.system(size: 13, weight: .heavy, design: .monospaced))
                    .tracking(3)
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding(.bottom, 10)
            dashedDivider
            row("일시",     value: formattedDate(trip.endedAt))
            row("거리",     value: String(format: "%.2f km", trip.distanceMeters / 1000))
            row("시간",     value: formattedDuration(trip.durationSeconds))
            row("할증",     value: trip.surcharge.label)
            dashedDivider
            row("기본요금", value: "\(formatWon(trip.baseFare)) 원")
            row("거리요금", value: "\(formatWon(trip.distanceFee)) 원")
            row("시간요금", value: "\(formatWon(trip.timeFee)) 원")
            dashedDivider
            HStack(alignment: .firstTextBaseline) {
                Text("총 요금")
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(.white)
                Spacer()
                Text("\(formatWon(trip.totalFare)) 원")
                    .font(.system(size: 24, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
            }
            .padding(.vertical, 8)
            dashedDivider
            VStack(alignment: .center, spacing: 6) {
                Text("커피 \(coffeesDisplay)잔")
                    .font(.system(size: 30, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
                Text("(\(formatWon(effectiveCoffeePrice))원/잔 기준)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.45))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            dashedDivider
            if !friendName.isEmpty {
                Text("→ \(friendName) 님, 커피 한 잔 부탁해요.")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
            }
        }
        .padding(18)
        .background(Color.black)
        .overlay(Rectangle().stroke(Color.white.opacity(0.55), lineWidth: 1))
    }

    private var coffeesDisplay: String {
        let price = effectiveCoffeePrice
        guard price > 0 else { return "-" }
        let cups = (Double(trip.totalFare) / Double(price) * 10).rounded() / 10
        return String(format: "%.1f", cups)
    }

    private func row(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.55))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
        }
        .padding(.vertical, 2)
    }

    private var dashedDivider: some View {
        GeometryReader { geo in
            let count = Int(geo.size.width / 6)
            HStack(spacing: 3) {
                ForEach(0..<max(0, count), id: \.self) { _ in
                    Rectangle().fill(Color.white.opacity(0.4)).frame(width: 3, height: 1)
                }
            }
        }
        .frame(height: 1)
        .padding(.vertical, 6)
    }

    private func actionButton(title: String, primary: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .black, design: .monospaced))
                .tracking(3)
                .foregroundStyle(primary ? .black : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    Rectangle()
                        .fill(primary ? Color.white : Color.black)
                )
                .overlay(Rectangle().stroke(Color.white, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        f.locale = Locale(identifier: "ko_KR")
        return f.string(from: date)
    }

    private func formattedDuration(_ t: TimeInterval) -> String {
        let total = Int(t)
        return String(format: "%02d:%02d:%02d", total / 3600, (total % 3600) / 60, total % 60)
    }

    private func formatWon(_ won: Int) -> String {
        currency.string(from: NSNumber(value: won)) ?? "\(won)"
    }

    // MARK: - Share

    @MainActor
    private func presentShare() {
        let renderer = ImageRenderer(content: receiptCard.frame(width: 360).padding(12).background(Color.black))
        renderer.scale = UIScreen.main.scale
        guard let image = renderer.uiImage else { return }
        let av = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController?
            .presentedViewController?
            .present(av, animated: true)
    }
}

#Preview {
    let breakdown = FareBreakdown(baseFare: 4800, distanceFee: 0, timeFee: 300, subtotal: 5100, surcharge: .none, total: 5100)
    let trip = Trip(
        startedAt: .now.addingTimeInterval(-35),
        endedAt: .now,
        distanceMeters: 0,
        durationSeconds: 35,
        breakdown: breakdown,
        friendName: "양시준"
    )
    return ReceiptView(trip: trip, onSaved: {}, onDismiss: {})
        .preferredColorScheme(.dark)
}
