import SwiftUI
import SwiftData

/// Main meter screen — styled after the JIE JOONGANG Pro-1 fare display.
/// Silver bezel, cyan VFD inside, yellow pill buttons along the bottom.
struct MeterView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vm = MeterViewModel()
    @State private var showReceipt = false
    @AppStorage("autoSurcharge") private var autoSurcharge: Bool = true
    @AppStorage("soundEnabled") private var soundEnabled: Bool = true
    @AppStorage("hapticEnabled") private var hapticEnabled: Bool = true
    @State private var keypadEntry: String = ""
    @State private var passengerName: String = ""
    @State private var pendingName: String = ""
    @State private var showNamePrompt: Bool = false

    var body: some View {
        ZStack {
            Color(red: 0.11, green: 0.11, blue: 0.12).ignoresSafeArea()

            VStack(spacing: 10) {
                bezeledMeter
                PhysicalButtonGrid(
                    state: vm.state,
                    surcharge: vm.surcharge,
                    onStart: {
                        pendingName = passengerName
                        showNamePrompt = true
                    },
                    onStop: { vm.stop(); showReceipt = true },
                    onSurcharge: { vm.toggleSurcharge() }
                )
                .padding(.horizontal, 4)
                NumberKeypad(entry: $keypadEntry)
                    .padding(.horizontal, 8)
                StopCapsule(onReset: {
                    switch vm.state {
                    case .running:
                        vm.stop()
                        showReceipt = true
                    case .finished:
                        showReceipt = true
                    case .idle:
                        vm.reset()
                        keypadEntry = ""
                        passengerName = ""
                    }
                })
                .padding(.horizontal, 4)
            }
            .padding(.horizontal, 10)
            .padding(.top, 0)
            .padding(.bottom, 6)
        }
        .onAppear {
            vm.requestLocationPermission()
            vm.autoSurcharge = autoSurcharge
            SoundPlayer.shared.isEnabled = soundEnabled
            HapticEngine.shared.isEnabled = hapticEnabled
        }
        .onChange(of: autoSurcharge) { _, new in vm.autoSurcharge = new }
        .onChange(of: soundEnabled) { _, new in SoundPlayer.shared.isEnabled = new }
        .onChange(of: hapticEnabled) { _, new in HapticEngine.shared.isEnabled = new }
        .alert("손님 성함을 알려주세요", isPresented: $showNamePrompt) {
            TextField("예: 재현", text: $pendingName)
                .textInputAutocapitalization(.never)
            Button("운행 시작") {
                let trimmed = pendingName.trimmingCharacters(in: .whitespaces)
                passengerName = trimmed.isEmpty ? "손님" : trimmed
                vm.start()
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("안전운행 문구에 표시됩니다.")
        }
        .sheet(isPresented: $showReceipt) {
            if let trip = vm.makeTrip(friendName: passengerName.isEmpty ? nil : passengerName) {
                ReceiptView(trip: trip, onSaved: {
                    modelContext.insert(trip)
                    try? modelContext.save()
                    vm.reset()
                    showReceipt = false
                }, onDismiss: {
                    vm.reset()
                    showReceipt = false
                })
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Silver bezel + display

    private var bezeledMeter: some View {
        VStack(spacing: 0) {
            topBezelHeader
            displayPanel
            bottomLegend
        }
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color.bezelOuter,        location: 0.00),
                                .init(color: Color.bezelMid,          location: 0.08),
                                .init(color: Color.bezelOuter,        location: 0.18),
                                .init(color: Color.bezelMid,          location: 0.55),
                                .init(color: Color.bezelInner,        location: 0.85),
                                .init(color: Color.bezelMid,          location: 1.00),
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                // top highlight stripe — catches light on top edge
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.55), Color.white.opacity(0.0)],
                            startPoint: .top, endPoint: .center
                        ),
                        lineWidth: 1.2
                    )
                // brushed-metal striations
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

    private var topBezelHeader: some View {
        Group {
            if passengerName.isEmpty {
                HStack {
                    HStack(spacing: 4) {
                        Text("JIE")
                            .font(.system(size: 11, weight: .black, design: .serif).italic())
                            .foregroundStyle(.black)
                        Text("TAXIGO")
                            .font(.system(size: 11, weight: .heavy, design: .serif))
                            .foregroundStyle(.black)
                    }
                    Text("RECORDs")
                        .font(.system(size: 9, weight: .medium, design: .serif))
                        .foregroundStyle(.black.opacity(0.7))
                        .padding(.leading, 4)
                    Spacer()
                    Text("Pro-1")
                        .font(.system(size: 13, weight: .heavy, design: .serif).italic())
                        .foregroundStyle(.black)
                    Spacer()
                    Text("FARE")
                        .font(.system(size: 11, weight: .black, design: .serif))
                        .foregroundStyle(.black)
                }
            } else {
                HStack {
                    Spacer(minLength: 0)
                    Text("\(passengerName)님, 안전운행하겠습니다.")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(.black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 14)
    }

    // MARK: - Display panel

    private var displayPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                leftIndicatorColumn
                topRowDisplay
            }
            horseRow
            statusBandRow
            bottomSubRow
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


    private var leftIndicatorColumn: some View {
        VStack(alignment: .leading, spacing: 8) {
            IndicatorLabel(text: "VACANT", subscriptNum: 1, isActive: vm.state == .idle, color: .meterCyan)
            IndicatorLabel(text: "HIRED",  subscriptNum: 2, isActive: vm.state == .running, color: .meterCyan)
            IndicatorLabel(text: "NIGHT",  subscriptNum: 3, isActive: vm.surcharge == .night20 || vm.surcharge == .night40, color: .taxiOrange)
            IndicatorLabel(text: "STOP",   subscriptNum: 7, isActive: vm.state == .finished, color: .taxiRed)
        }
        .fixedSize()
    }

    private var topRowDisplay: some View {
        HStack(alignment: .top, spacing: 6) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top, spacing: 3) {
                    SegmentedText(
                        text: formattedClock(),
                        activeColor: .meterCyan,
                        digitWidth: 10, digitHeight: 18, spacing: 2
                    )
                    Text(ampmIndicator())
                        .font(.system(size: 7, weight: .black, design: .serif).italic())
                        .foregroundStyle(Color.meterCyan)
                        .shadow(color: Color.meterCyan.opacity(0.5), radius: 3)
                        .baselineOffset(2)
                }
                SegmentedText(
                    text: formattedElapsedRaw(vm.elapsed),
                    activeColor: .meterCyan,
                    digitWidth: 10, digitHeight: 18, spacing: 2
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            SegmentedNumber(
                value: vm.displayFare,
                digits: 5,
                activeColor: .meterCyan,
                digitWidth: 34, digitHeight: 72,
                spacing: 3
            )
        }
    }

    private var horseRow: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("PAID")
                    .font(.system(size: 9, weight: .black, design: .serif).italic())
                    .foregroundStyle(Color.meterCyan.opacity(0.6))
                SegmentedText(
                    text: String(format: "%04d", Int(max(0, vm.distanceKm * 100))),
                    activeColor: .meterCyan,
                    digitWidth: 12, digitHeight: 24, spacing: 2
                )
            }

            RunningHorseView(
                progress: min(1, vm.distanceMeters / vm.rule.baseDistanceMeters),
                isActive: vm.state == .running,
                showTrack: false,
                pixelColor: .meterCyan
            )
            .frame(height: 44)
            .frame(maxWidth: .infinity)

            VStack(alignment: .trailing, spacing: 2) {
                Text("TRIPs")
                    .font(.system(size: 9, weight: .black, design: .serif).italic())
                    .foregroundStyle(Color.meterCyan.opacity(0.6))
                SegmentedText(
                    text: String(format: "%02d", tripCount()),
                    activeColor: .meterCyan,
                    digitWidth: 12, digitHeight: 24, spacing: 2
                )
            }
        }
    }

    private var statusBandRow: some View {
        HStack {
            Text(statusPhrase)
                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                .tracking(3)
                .foregroundStyle(statusColor)
                .shadow(color: statusColor.opacity(0.5), radius: 4)
            Spacer()
            SegmentedText(
                text: vm.surcharge == .none ? "1.00X" : String(format: "%.2fX", vm.surcharge.multiplier),
                activeColor: vm.surcharge == .none ? Color.meterCyan.opacity(0.6) : .taxiOrange,
                digitWidth: 9, digitHeight: 18, spacing: 1
            )
        }
        .padding(.horizontal, 2)
    }

    private var bottomSubRow: some View {
        HStack(spacing: 14) {
            subCell(label: "TOTAL km",   value: String(format: "%.2f", vm.distanceKm),   color: .meterCyan)
            subCell(label: "UNITs",      value: String(format: "%03d", unitsCount()),    color: .meterCyan)
            subCell(label: "AMOUNT",     value: "\(formattedAmount(vm.displayFare))",    color: .taxiGreen)
        }
    }

    private func subCell(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 8, weight: .heavy, design: .serif).italic())
                .foregroundStyle(Color.meterCyan.opacity(0.5))
            SegmentedText(
                text: value,
                activeColor: color,
                digitWidth: 8, digitHeight: 16, spacing: 1
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statusPhrase: String {
        switch vm.state {
        case .idle: "▶︎ 대기 · 출발 누르세요"
        case .running: "● 주행 중"
        case .finished: "■ 운행 종료"
        }
    }

    private var statusColor: Color {
        switch vm.state {
        case .idle: Color.meterCyan.opacity(0.7)
        case .running: .taxiGreen
        case .finished: .taxiOrange
        }
    }

    private func unitsCount() -> Int {
        // 131m 당 1 unit — 실제 메터기가 보여주는 누적 유닛 수
        Int((vm.distanceMeters / vm.rule.distanceIncrementMeters).rounded(.down))
    }

    private func formattedAmount(_ won: Int) -> String {
        let s = String(won)
        guard s.count > 3 else { return s }
        var chars = Array(s)
        chars.insert(",", at: chars.count - 3)
        return String(chars)
    }

    private var bottomLegend: some View {
        HStack(spacing: 10) {
            Text("1.TOTALkm  2.PAIDkm  3.TRIPs  4.UNITs  5.AMOUNT")
                .font(.system(size: 8, weight: .medium, design: .serif))
                .foregroundStyle(.black.opacity(0.7))
            Spacer()
            Text("S.No: \(serialNumber())")
                .font(.system(size: 8, weight: .medium, design: .serif))
                .foregroundStyle(.black.opacity(0.7))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private func formattedClock() -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: Date())
    }

    private func ampmIndicator() -> String {
        Calendar.current.component(.hour, from: Date()) < 12 ? "AM" : "PM"
    }

    private func formattedElapsedRaw(_ t: TimeInterval) -> String {
        let total = Int(t)
        return String(format: "%02d:%02d:%02d", total / 3600, (total % 3600) / 60, total % 60)
    }

    private func tripCount() -> Int {
        (try? modelContext.fetchCount(FetchDescriptor<Trip>())) ?? 0
    }

    private func serialNumber() -> String {
        "001"
    }
}

// MARK: - Indicator label

private struct IndicatorLabel: View {
    let text: String
    let subscriptNum: Int
    let isActive: Bool
    let color: Color

    var body: some View {
        HStack(spacing: 2) {
            Rectangle()
                .fill(isActive ? color : Color.white.opacity(0.05))
                .frame(width: 7, height: 7)
                .shadow(color: isActive ? color.opacity(0.7) : .clear, radius: 4)
            Text(text)
                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                .tracking(-0.5)
                .foregroundStyle(isActive ? color : Color.white.opacity(0.22))
                .shadow(color: isActive ? color.opacity(0.5) : .clear, radius: 3)
                .fixedSize()
            Text("\(subscriptNum)")
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundStyle(isActive ? color.opacity(0.8) : Color.white.opacity(0.18))
                .baselineOffset(-3)
        }
    }
}

// MARK: - Bottom physical button row

private struct PhysicalButtonGrid: View {
    let state: MeterState
    let surcharge: SurchargeMode
    let onStart: () -> Void
    let onStop: () -> Void
    let onSurcharge: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                button("빈차", isOn: state == .idle, action: {})
                button(primaryLabel, isOn: state == .running, action: primaryAction, isPrimary: true)
                button("심야", isOn: surcharge == .night20 || surcharge == .night40, action: onSurcharge)
            }
            HStack(spacing: 8) {
                button("할증", isOn: surcharge == .night40 || surcharge == .outside20, action: onSurcharge)
                button("호출", isOn: false, action: {})
                button("시외", isOn: surcharge == .outside20, action: onSurcharge)
            }
        }
    }

    private var primaryLabel: String {
        switch state {
        case .idle: "주행"
        case .running: "도착"
        case .finished: "영수증"
        }
    }

    private func primaryAction() {
        switch state {
        case .idle: onStart()
        case .running: onStop()
        case .finished: onStop()
        }
    }

    private func button(_ title: String, isOn: Bool, action: @escaping () -> Void, isPrimary: Bool = false) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: isPrimary
                                    ? [Color(red: 1, green: 0.98, blue: 0.6), Color.physicalButton, Color.physicalButtonDeep]
                                    : [Color(red: 1, green: 0.94, blue: 0.50), Color.physicalButton, Color.physicalButtonDeep],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .overlay(
                            Ellipse()
                                .stroke(Color.black.opacity(0.35), lineWidth: 0.8)
                        )
                        .overlay(
                            // glossy top highlight
                            Ellipse()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.55), Color.white.opacity(0.0)],
                                        startPoint: .top, endPoint: .center
                                    )
                                )
                                .padding(.horizontal, 6)
                                .padding(.top, 3)
                                .blendMode(.screen)
                                .allowsHitTesting(false)
                        )
                        .shadow(color: .black.opacity(0.5), radius: 3, y: 3)
                )
                .overlay(alignment: .top) {
                    if isOn {
                        Circle()
                            .fill(Color.meterCyan)
                            .frame(width: 6, height: 6)
                            .shadow(color: .meterCyan.opacity(0.9), radius: 4)
                            .offset(y: 3)
                    }
                }
        }
        .buttonStyle(.plain)
    }

}

private struct StopCapsule: View {
    let onReset: () -> Void
    var body: some View {
        Button(action: onReset) {
            Text("주행 종료")
                .font(.system(size: 17, weight: .black, design: .rounded))
                .tracking(3)
                .foregroundStyle(Color.meterCyan)
                .shadow(color: Color.meterCyan.opacity(0.5), radius: 3)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.14, green: 0.14, blue: 0.16), Color(red: 0.07, green: 0.07, blue: 0.09)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.meterCyan.opacity(0.35), lineWidth: 0.8)
                        )
                        .overlay(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.10), Color.white.opacity(0.0)],
                                        startPoint: .top, endPoint: .center
                                    )
                                )
                                .padding(.horizontal, 6)
                                .padding(.top, 3)
                                .allowsHitTesting(false)
                        )
                        .shadow(color: .black.opacity(0.5), radius: 3, y: 2)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MeterView()
        .preferredColorScheme(.dark)
        .modelContainer(for: [Trip.self], inMemory: true)
}
