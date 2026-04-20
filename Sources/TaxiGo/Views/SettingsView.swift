import SwiftUI

struct SettingsView: View {
    @AppStorage("coffeePricePerCup") private var coffeePricePerCup: Int = 5_000
    @AppStorage("soundEnabled") private var soundEnabled: Bool = true
    @AppStorage("hapticEnabled") private var hapticEnabled: Bool = true
    @AppStorage("autoSurcharge") private var autoSurcharge: Bool = true

    var body: some View {
        NavigationStack {
            Form {
                Section("요율 (서울 2026 중형)") {
                    LabeledContent("기본요금", value: "4,800 원 / 1.6 km")
                    LabeledContent("거리 병산", value: "131 m 당 100 원")
                    LabeledContent("시간 병산", value: "30 초 당 100 원")
                    LabeledContent("저속 기준", value: "15 km/h 미만")
                }
                Section("재미 설정") {
                    Stepper(value: $coffeePricePerCup, in: 1_000...20_000, step: 500) {
                        LabeledContent("커피 한 잔") {
                            Text("\(coffeePricePerCup.formatted()) 원")
                                .foregroundStyle(.secondary)
                        }
                    }
                    Toggle("자동 심야 할증", isOn: $autoSurcharge)
                }
                Section("피드백") {
                    Toggle("효과음", isOn: $soundEnabled)
                        .onChange(of: soundEnabled) { _, new in SoundPlayer.shared.isEnabled = new }
                    Toggle("햅틱", isOn: $hapticEnabled)
                        .onChange(of: hapticEnabled) { _, new in HapticEngine.shared.isEnabled = new }
                }
                Section("앱") {
                    LabeledContent("버전", value: appVersion)
                    Link("개발자 GitHub", destination: URL(string: "https://github.com/Gojaehyeon")!)
                }
            }
            .navigationTitle("설정")
            .scrollContentBackground(.hidden)
            .background(Color.meterBackground)
        }
    }

    private var appVersion: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
        return "v\(v) (\(b))"
    }
}

#Preview {
    SettingsView().preferredColorScheme(.dark)
}
