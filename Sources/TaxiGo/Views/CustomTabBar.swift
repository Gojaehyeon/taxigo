import SwiftUI

enum RootTab: Hashable, CaseIterable {
    case meter, history, settings

    var label: String {
        switch self {
        case .meter: "미터기"
        case .history: "이력"
        case .settings: "설정"
        }
    }

    var systemImage: String {
        switch self {
        case .meter: "gauge.open.with.lines.needle.33percent"
        case .history: "list.bullet.rectangle"
        case .settings: "gearshape"
        }
    }
}

struct CustomTabBar: View {
    @Binding var selected: RootTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(RootTab.allCases, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 10)
        .padding(.bottom, 22)
        .background(
            ZStack {
                Color(red: 0.07, green: 0.07, blue: 0.08)
                Rectangle()
                    .fill(Color.meterCyan.opacity(0.15))
                    .frame(height: 1)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
            .ignoresSafeArea(edges: .bottom)
        )
    }

    private func tabButton(_ tab: RootTab) -> some View {
        let isActive = selected == tab
        return Button {
            HapticEngine.shared.tick()
            selected = tab
        } label: {
            Image(systemName: tab.systemImage)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(isActive ? Color.meterCyan : Color.white.opacity(0.45))
                .shadow(color: isActive ? Color.meterCyan.opacity(0.7) : .clear, radius: 5)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    @Previewable @State var t: RootTab = .meter
    VStack {
        Spacer()
        CustomTabBar(selected: $t)
    }
    .background(Color.black)
}
