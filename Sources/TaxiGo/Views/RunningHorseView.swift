import SwiftUI

/// Galloping horse indicator. Uses two bundled template PNGs (Horse1 / Horse2)
/// that alternate at 2 Hz — two frames per second — the same cadence as the
/// real dot-matrix animation on the JIE JOONGANG Pro-1.
struct RunningHorseView: View {
    let progress: Double  // 0 → 1, how far through the base distance
    let isActive: Bool
    var showTrack: Bool = true
    var pixelColor: Color = .meterCyan

    @State private var frameIndex = 0
    @State private var animationTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                if showTrack {
                    HStack(spacing: 4) {
                        ForEach(0..<max(1, Int(geo.size.width / 8)), id: \.self) { i in
                            Rectangle()
                                .fill(pixelColor.opacity(i.isMultiple(of: 3) ? 0.25 : 0.08))
                                .frame(width: 3, height: 2)
                        }
                    }
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 2)
                }

                Image("Horse\(frameIndex + 1)")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(pixelColor)
                    .shadow(color: pixelColor.opacity(isActive ? 0.55 : 0.0), radius: 4)
                    .shadow(color: pixelColor.opacity(isActive ? 0.30 : 0.0), radius: 10)
                    .frame(height: 56)
                    .opacity(isActive ? 1.0 : 0.35)
                    .offset(x: max(0, min(geo.size.width - 92, progress * (geo.size.width - 92))))
            }
        }
        .frame(height: 60)
        .onAppear { start() }
        .onDisappear { stop() }
        .onChange(of: isActive) { _, new in new ? start() : stop() }
    }

    private func start() {
        stop()
        guard isActive else { return }
        animationTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s = 2 Hz
                if Task.isCancelled { break }
                frameIndex = (frameIndex + 1) % 2
            }
        }
    }

    private func stop() {
        animationTask?.cancel()
        animationTask = nil
    }
}

#Preview {
    ZStack {
        Color.meterBackground.ignoresSafeArea()
        VStack(spacing: 18) {
            RunningHorseView(progress: 0.1, isActive: true)
            RunningHorseView(progress: 0.5, isActive: true)
            RunningHorseView(progress: 0.9, isActive: false)
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
