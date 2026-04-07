import Foundation
import AVFoundation
import Speech

enum PetVoiceService {
    // MARK: - Audio Player

    private static var audioPlayer: AVAudioPlayer?
    private static let synthesizer = AVSpeechSynthesizer() // Apple TTS fallback

    // MARK: - Audio Cache (LRU, max 10)
    private static var audioCache: [(key: String, data: Data)] = []
    private static let cacheLimit = 10

    private static func cacheAudio(key: String, data: Data) {
        // Remove existing entry with same key
        audioCache.removeAll { $0.key == key }
        // Add to front (most recent)
        audioCache.insert((key: key, data: data), at: 0)
        // Evict oldest if over limit
        if audioCache.count > cacheLimit {
            audioCache.removeLast()
        }
    }

    private static func getCachedAudio(key: String) -> Data? {
        guard let index = audioCache.firstIndex(where: { $0.key == key }) else { return nil }
        // Move to front (LRU touch)
        let entry = audioCache.remove(at: index)
        audioCache.insert(entry, at: 0)
        return entry.data
    }

    /// Replay audio for a specific message (from cache)
    static func replay(messageId: String) {
        if let cached = getCachedAudio(key: messageId) {
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: .default, options: .duckOthers)
                try session.setActive(true)
            } catch {}
            playAudio(cached)
        }
    }

    /// Check if audio is cached for a message
    static func hasCachedAudio(messageId: String) -> Bool {
        audioCache.contains { $0.key == messageId }
    }


    // MARK: - Emoji Stripping

    private static func stripEmoji(_ text: String) -> String {
        text.unicodeScalars.filter { scalar in
            guard scalar.properties.isEmoji else { return true }
            // Keep ASCII characters (basic punctuation / numbers that report isEmoji)
            return scalar.value < 128
        }.map(String.init).joined()
    }

    // MARK: - TTS: Mode-aware

    static func speak(_ text: String, language: String = "en", emotion: String = "calm", mode: ChatMode = .basic, messageId: String? = nil) {
        let cleanText = stripEmoji(text)
        guard !cleanText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        if mode == .premium {
            // Premium: MiniMax natural voice, using user's selected voice if set
            let selectedVoice = UserDefaults.standard.string(forKey: "selectedVoiceId") ?? "apple_default"
            let voiceId: String? = selectedVoice != "apple_default" ? selectedVoice : nil
            Task {
                do {
                    let session = AVAudioSession.sharedInstance()
                    try session.setCategory(.playback, mode: .default, options: .duckOthers)
                    try session.setActive(true)
                } catch {
                    print("[TTS] Audio session error: \(error)")
                }
                if let audioData = await fetchMiniMaxTTS(text: cleanText, language: language, emotion: emotion, voiceId: voiceId) {
                    if let mid = messageId { cacheAudio(key: mid, data: audioData) }
                    await MainActor.run { playAudio(audioData) }
                } else {
                    await MainActor.run { speakWithApple(cleanText, language: language) }
                }
            }
        } else {
            // Basic: Apple TTS (free) — must run on main thread
            Task { @MainActor in
                do {
                    let session = AVAudioSession.sharedInstance()
                    try session.setCategory(.playback, mode: .default, options: .duckOthers)
                    try session.setActive(true)
                } catch {
                    print("[TTS] Audio session error: \(error)")
                }
                speakWithApple(cleanText, language: language)
            }
        }
    }

    // MARK: - MiniMax T2A API

    static func fetchMiniMaxTTS(text: String, language: String, emotion: String, voiceId: String? = nil) async -> Data? {
        let urlString = "\(SupabaseConfig.projectURL)/functions/v1/pet-tts"
        guard let url = URL(string: urlString) else { return nil }

        var body: [String: Any] = [
            "text": text,
            "language": language,
            "emotion": emotion
        ]
        if let voiceId { body["voiceId"] = voiceId }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 20

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("[TTS] pet-tts status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                return nil
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let hexString = json["audio"] as? String {
                let audioData = Data(hexString: hexString)
                print("[TTS] pet-tts audio received: \(audioData?.count ?? 0) bytes")
                return audioData
            }
        } catch {
            print("[TTS] pet-tts error: \(error)")
        }
        return nil
    }

    // MARK: - Audio Playback

    static func playAudioPublic(_ data: Data) {
        playAudio(data)
    }

    private static func playAudio(_ data: Data) {
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.play()
            print("[TTS] Playing MiniMax audio")
        } catch {
            print("[TTS] Playback error: \(error)")
        }
    }

    // MARK: - Apple TTS Trial (for voice selector preview)

    static func speakTrial(_ text: String, language: String) {
        Task { @MainActor in
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: .default, options: .duckOthers)
                try session.setActive(true)
            } catch {}
            speakWithApple(text, language: language)
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
            continuation.onTermination = { @Sendable _ in
                Task { await MainActor.run { self.stopListening() } }
            }
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
            case .notAvailable: L10n.t("Speech recognition not available", "语音识别不可用")
            case .permissionDenied: L10n.t("Microphone permission denied", "麦克风权限被拒绝")
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
