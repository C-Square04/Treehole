import Foundation
import AVFoundation
import Speech

enum PetVoiceService {
    // MARK: - TTS (Text to Speech)

    private static let synthesizer = AVSpeechSynthesizer()

    /// Speak text using Apple TTS (free, offline)
    static func speak(_ text: String, language: String = "en") {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language == "zh-Hans" ? "zh-CN" : "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9  // Slightly slower, more cute
        utterance.pitchMultiplier = 1.2  // Higher pitch for cute pet voice
        utterance.volume = 1.0

        synthesizer.stopSpeaking(at: .immediate)
        synthesizer.speak(utterance)
    }

    /// Stop speaking
    static func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    /// Is currently speaking
    static var isSpeaking: Bool {
        synthesizer.isSpeaking
    }

    // MARK: - STT (Speech to Text)

    private static var audioEngine: AVAudioEngine?
    private static var recognitionTask: SFSpeechRecognitionTask?

    /// Check if speech recognition is available
    static func requestSTTPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    /// Start listening and return transcribed text
    static func startListening(language: String = "en") async throws -> AsyncStream<String> {
        let locale = Locale(identifier: language == "zh-Hans" ? "zh-CN" : "en-US")
        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
            throw VoiceError.notAvailable
        }

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true

        let engine = AVAudioEngine()
        self.audioEngine = engine

        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        engine.prepare()
        try engine.start()

        return AsyncStream { continuation in
            self.recognitionTask = recognizer.recognitionTask(with: request) { result, error in
                if let result {
                    let text = result.bestTranscription.formattedString
                    continuation.yield(text)
                    if result.isFinal {
                        continuation.finish()
                    }
                }
                if error != nil {
                    continuation.finish()
                }
            }

            continuation.onTermination = { _ in
                self.stopListening()
            }
        }
    }

    /// Stop listening
    static func stopListening() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionTask?.cancel()
        audioEngine = nil
        recognitionTask = nil
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    enum VoiceError: Error, LocalizedError {
        case notAvailable
        case permissionDenied
        var errorDescription: String? {
            switch self {
            case .notAvailable: return "Speech recognition not available"
            case .permissionDenied: return "Microphone permission denied"
            }
        }
    }
}
