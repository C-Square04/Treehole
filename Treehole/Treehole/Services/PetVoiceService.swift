import Foundation
import AVFoundation
import Speech

enum PetVoiceService {
    // MARK: - Audio Player

    private static var audioPlayer: AVAudioPlayer?
    private static let synthesizer = AVSpeechSynthesizer() // Apple TTS fallback

    private static let minimaxAPIKey = "sk-cp-z4CQ1mXhW7zic_yooLH76BxPnerSaOfmrM4eaYiu1iP-ArmWhAjB8JLvZKQN67OLubHnV3Xy8QX7Mn2AOnDIQcONI4yaEPUgPqQvmivxwot3fMJJyNxBdLI"

    // MARK: - TTS: MiniMax first, Apple fallback

    static func speak(_ text: String, language: String = "en", emotion: String = "calm") {
        Task {
            // Activate audio session
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: .default, options: .duckOthers)
                try session.setActive(true)
            } catch {
                print("[TTS] Audio session error: \(error)")
            }

            // Try MiniMax TTS first (natural voice)
            if let audioData = await fetchMiniMaxTTS(text: text, language: language, emotion: emotion) {
                await MainActor.run { playAudio(audioData) }
                return
            }

            // Fallback: Apple TTS (robotic but offline)
            await MainActor.run { speakWithApple(text, language: language) }
        }
    }

    // MARK: - MiniMax T2A API

    private static func fetchMiniMaxTTS(text: String, language: String, emotion: String) async -> Data? {
        guard let url = URL(string: "https://api.minimaxi.com/v1/t2a_v2") else { return nil }

        // Pick voice based on language
        let voiceId = language == "zh-Hans" ? "female-tianmei" : "English_Graceful_Lady"

        let body: [String: Any] = [
            "model": "speech-2.8-hd",
            "text": text,
            "stream": false,
            "voice_setting": [
                "voice_id": voiceId,
                "speed": 1.0,
                "vol": 1.0,
                "emotion": emotion
            ],
            "audio_setting": [
                "format": "mp3",
                "sample_rate": 32000
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(minimaxAPIKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 15

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("[TTS] MiniMax API status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                return nil
            }

            // Parse hex-encoded audio from response
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let dataObj = json["data"] as? [String: Any],
               let hexString = dataObj["audio"] as? String {
                let audioData = Data(hexString: hexString)
                print("[TTS] MiniMax audio received: \(audioData?.count ?? 0) bytes")
                return audioData
            }
        } catch {
            print("[TTS] MiniMax error: \(error)")
        }
        return nil
    }

    // MARK: - Audio Playback

    private static func playAudio(_ data: Data) {
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.play()
            print("[TTS] Playing MiniMax audio")
        } catch {
            print("[TTS] Playback error: \(error)")
        }
    }

    // MARK: - Apple TTS Fallback

    private static func speakWithApple(_ text: String, language: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language == "zh-Hans" ? "zh-CN" : "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        utterance.pitchMultiplier = 1.2
        utterance.volume = 1.0
        synthesizer.stopSpeaking(at: .immediate)
        synthesizer.speak(utterance)
        print("[TTS] Apple TTS fallback")
    }

    static func stopSpeaking() {
        audioPlayer?.stop()
        audioPlayer = nil
        synthesizer.stopSpeaking(at: .immediate)
    }

    static var isSpeaking: Bool {
        (audioPlayer?.isPlaying ?? false) || synthesizer.isSpeaking
    }

    // MARK: - STT (Speech to Text)

    private static var audioEngine: AVAudioEngine?
    private static var recognitionTask: SFSpeechRecognitionTask?

    static func requestSTTPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

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
                    continuation.yield(result.bestTranscription.formattedString)
                    if result.isFinal { continuation.finish() }
                }
                if error != nil { continuation.finish() }
            }
            continuation.onTermination = { _ in self.stopListening() }
        }
    }

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
            case .notAvailable: "Speech recognition not available"
            case .permissionDenied: "Microphone permission denied"
            }
        }
    }
}

// MARK: - Hex String → Data

extension Data {
    init?(hexString: String) {
        let len = hexString.count
        guard len % 2 == 0 else { return nil }
        var data = Data(capacity: len / 2)
        var index = hexString.startIndex
        for _ in 0..<len / 2 {
            let nextIndex = hexString.index(index, offsetBy: 2)
            guard let byte = UInt8(hexString[index..<nextIndex], radix: 16) else { return nil }
            data.append(byte)
            index = nextIndex
        }
        self = data
    }
}
