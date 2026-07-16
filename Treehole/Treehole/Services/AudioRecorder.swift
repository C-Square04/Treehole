import Foundation
import AVFoundation
import Observation

@Observable
final class AudioRecorder: NSObject, AVAudioRecorderDelegate {

    // MARK: - Public State
    var isRecording: Bool = false
    var currentLevel: Float = 0.0
    var elapsed: TimeInterval = 0.0

    // MARK: - Private
    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    private var tempFileURL: URL?
    private let maxDuration: TimeInterval = 300 // 5 minutes

    // A take that hit the max-duration cap, finalized and held until the UI
    // calls stopRecording(). Without this, the capped take would be discarded
    // because isRecording is already false by the time the user taps stop.
    private var autoStoppedResult: (data: Data, duration: TimeInterval)?

    // MARK: - Notification name for max duration reached
    static let maxDurationReachedNotification = Notification.Name("AudioRecorder.maxDurationReached")

    // MARK: - Permission

    func requestPermission() async -> Bool {
        if #available(iOS 17.0, *) {
            return await AVAudioApplication.requestRecordPermission()
        } else {
            return await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    // MARK: - Recording

    func startRecording() throws {
        autoStoppedResult = nil
        let tmpDir = URL(fileURLWithPath: NSTemporaryDirectory())
        let fileURL = tmpDir.appendingPathComponent(UUID().uuidString + ".m4a")
        tempFileURL = fileURL

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, options: [.duckOthers])
        try session.setActive(true)

        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]

        let rec = try AVAudioRecorder(url: fileURL, settings: settings)
        rec.delegate = self
        rec.isMeteringEnabled = true
        rec.record()
        recorder = rec
        isRecording = true
        elapsed = 0.0

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.elapsed += 0.1
            self.recorder?.updateMeters()
            let power = self.recorder?.averagePower(forChannel: 0) ?? -60
            // Normalize from [-60, 0] dBFS to [0, 1]
            let normalized = max(0, min(1, (power + 60) / 60))
            self.currentLevel = normalized
            if self.elapsed >= self.maxDuration {
                self.autoStop()
            }
        }
    }

    func stopRecording() -> (data: Data, duration: TimeInterval)? {
        // A take that hit the 5-minute cap was already finalized — hand it
        // over instead of discarding it.
        if let result = autoStoppedResult {
            autoStoppedResult = nil
            return result
        }
        guard let rec = recorder, isRecording else { return nil }
        let duration = elapsed
        rec.stop()
        stopCleanup()
        guard let fileURL = tempFileURL,
              let data = try? Data(contentsOf: fileURL) else {
            cleanupTempFile()
            return nil
        }
        cleanupTempFile()
        return (data: data, duration: duration)
    }

    func cancelRecording() {
        autoStoppedResult = nil
        recorder?.stop()
        stopCleanup()
        cleanupTempFile()
    }

    // MARK: - Private Helpers

    private func autoStop() {
        let duration = elapsed
        recorder?.stop()
        stopCleanup()
        // Finalize the capped take now so it survives until the UI asks for it.
        if let fileURL = tempFileURL, let data = try? Data(contentsOf: fileURL) {
            autoStoppedResult = (data: data, duration: duration)
        }
        cleanupTempFile()
        NotificationCenter.default.post(name: AudioRecorder.maxDurationReachedNotification, object: nil)
    }

    private func stopCleanup() {
        timer?.invalidate()
        timer = nil
        isRecording = false
        currentLevel = 0.0
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func cleanupTempFile() {
        if let url = tempFileURL {
            try? FileManager.default.removeItem(at: url)
            tempFileURL = nil
        }
    }

    // MARK: - AVAudioRecorderDelegate

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            stopCleanup()
            cleanupTempFile()
        }
    }
}
