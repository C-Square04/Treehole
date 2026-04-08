import SwiftUI
import AVFoundation

/// Inline audio player: play/pause button + scrubber + duration label
struct AudioPlayerView: View {
    let audioURL: URL
    let totalDuration: Double

    @State private var player: AVAudioPlayer?
    @State private var isPlaying: Bool = false
    @State private var progress: Double = 0.0
    @State private var playbackTimer: Timer?

    var body: some View {
        HStack(spacing: TreeholeTheme.spacingSmall) {
            Button {
                togglePlayback()
            } label: {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(TreeholeTheme.skyBlue)
            }

            ProgressView(value: progress, total: 1.0)
                .progressViewStyle(.linear)
                .tint(TreeholeTheme.skyBlue)

            Text(formatDuration(totalDuration))
                .font(.caption.monospacedDigit())
                .foregroundStyle(TreeholeTheme.textLight)
                .frame(width: 44, alignment: .trailing)
        }
        .onDisappear {
            stopPlayback()
        }
    }

    private func togglePlayback() {
        if isPlaying {
            stopPlayback()
        } else {
            startPlayback()
        }
    }

    private func startPlayback() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            let p = try AVAudioPlayer(contentsOf: audioURL)
            p.play()
            player = p
            isPlaying = true
            playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                guard let pl = player else { return }
                if pl.isPlaying {
                    let dur = pl.duration > 0 ? pl.duration : totalDuration
                    progress = dur > 0 ? pl.currentTime / dur : 0
                } else {
                    isPlaying = false
                    progress = 0.0
                    playbackTimer?.invalidate()
                    playbackTimer = nil
                }
            }
        } catch {
            isPlaying = false
        }
    }

    private func stopPlayback() {
        player?.stop()
        player = nil
        isPlaying = false
        progress = 0.0
        playbackTimer?.invalidate()
        playbackTimer = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func formatDuration(_ seconds: Double) -> String {
        let total = Int(max(0, seconds))
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }
}
