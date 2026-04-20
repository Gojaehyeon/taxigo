import SwiftUI
import SwiftData

@main
struct TaxiGoApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [Trip.self])
    }
}

struct RootView: View {
    @State private var tab: RootTab = .meter

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                switch tab {
                case .meter:    MeterView()
                case .history:  HistoryView()
                case .settings: SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(nil, value: tab)
            .transaction { $0.animation = nil; $0.disablesAnimations = true }
            CustomTabBar(selected: $tab)
        }
        .background(Color(red: 0.07, green: 0.07, blue: 0.08))
        .ignoresSafeArea(edges: .bottom)
    }
}
