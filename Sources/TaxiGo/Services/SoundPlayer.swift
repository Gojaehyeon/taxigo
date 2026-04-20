import Foundation
import AVFoundation

/// Procedural sound effects — no audio files shipped.
/// Inspired by kikey's synthesis approach.
@MainActor
final class SoundPlayer {
    static let shared = SoundPlayer()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let sampleRate: Double = 44_100
    private var isPrepared = false
    var isEnabled: Bool = true

    private init() {}

    private func prepare() {
        guard !isPrepared else { return }
        engine.attach(player)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        engine.connect(player, to: engine.mainMixerNode, format: format)
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
            player.play()
            isPrepared = true
        } catch {
            isPrepared = false
        }
    }

    func tick() {
        guard isEnabled else { return }
        schedule(frequency: 1_800, durationMs: 35, shape: .square, gain: 0.10)
    }

    func surcharge() {
        guard isEnabled else { return }
        schedule(frequency: 900, durationMs: 90, shape: .triangle, gain: 0.14)
        schedule(frequency: 1_400, durationMs: 90, shape: .triangle, gain: 0.12, delayMs: 100)
    }

    func receipt() {
        guard isEnabled else { return }
        schedule(frequency: 2_200, durationMs: 60, shape: .saw, gain: 0.12)
        schedule(frequency: 1_100, durationMs: 100, shape: .saw, gain: 0.10, delayMs: 60)
        schedule(frequency: 550, durationMs: 180, shape: .saw, gain: 0.10, delayMs: 160)
    }

    // MARK: - Synth

    private enum Shape { case sine, square, triangle, saw }

    private func schedule(
        frequency: Double,
        durationMs: Int,
        shape: Shape,
        gain: Double,
        delayMs: Int = 0
    ) {
        prepare()
        guard isPrepared else { return }
        let frames = AVAudioFrameCount(sampleRate * Double(durationMs) / 1000.0)
        guard frames > 0,
              let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames),
              let chan = buffer.floatChannelData?[0] else { return }
        buffer.frameLength = frames

        let twoPi = 2.0 * Double.pi
        let fadeFrames = min(Int(sampleRate * 0.004), Int(frames) / 2) // 4ms fade
        for i in 0..<Int(frames) {
            let t = Double(i) / sampleRate
            let phase = (frequency * t).truncatingRemainder(dividingBy: 1.0)
            let sample: Double
            switch shape {
            case .sine:
                sample = sin(phase * twoPi)
            case .square:
                sample = phase < 0.5 ? 1.0 : -1.0
            case .triangle:
                sample = phase < 0.5 ? (4.0 * phase - 1.0) : (3.0 - 4.0 * phase)
            case .saw:
                sample = 2.0 * phase - 1.0
            }
            var env = 1.0
            if i < fadeFrames {
                env = Double(i) / Double(fadeFrames)
            } else if i > Int(frames) - fadeFrames {
                env = Double(Int(frames) - i) / Double(fadeFrames)
            }
            chan[i] = Float(sample * env * gain)
        }

        let sampleTime = AVAudioTime(
            sampleTime: AVAudioFramePosition(sampleRate * Double(delayMs) / 1000.0),
            atRate: sampleRate
        )
        let when = player.lastRenderTime.flatMap(player.playerTime(forNodeTime:)) ?? sampleTime
        let startAt = AVAudioTime(
            sampleTime: when.sampleTime + AVAudioFramePosition(sampleRate * Double(delayMs) / 1000.0),
            atRate: sampleRate
        )
        player.scheduleBuffer(buffer, at: startAt, options: [], completionHandler: nil)
    }
}
