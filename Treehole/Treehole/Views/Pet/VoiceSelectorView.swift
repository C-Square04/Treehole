import SwiftUI
import AVFoundation

// MARK: - Voice Option

struct VoiceOption: Identifiable {
    let id: String       // voice_id for MiniMax or "apple_default"
    let nameEN: String
    let nameZH: String
    let isPremium: Bool
    let previewTextEN: String
    let previewTextZH: String
}

// MARK: - Voice Options List

extension VoiceOption {
    static let all: [VoiceOption] = [
        VoiceOption(
            id: "apple_default",
            nameEN: "Apple Default",
            nameZH: "系统默认",
            isPremium: false,
            previewTextEN: "Hello, I'm here for you!",
            previewTextZH: "你好，我一直在这里！"
        ),
        VoiceOption(
            id: "female-tianmei",
            nameEN: "Sweet Girl",
            nameZH: "甜美少女",
            isPremium: true,
            previewTextEN: "Hi, I'm your companion!",
            previewTextZH: "你好，我是你的小伙伴！"
        ),
        VoiceOption(
            id: "English_Graceful_Lady",
            nameEN: "Graceful Lady",
            nameZH: "优雅女声",
            isPremium: true,
            previewTextEN: "I'm always here to listen.",
            previewTextZH: "我一直在这里倾听。"
        ),
        VoiceOption(
            id: "female-yujie",
            nameEN: "Calm & Mature",
            nameZH: "温柔知性",
            isPremium: true,
            previewTextEN: "Take a deep breath with me.",
            previewTextZH: "跟我一起深呼吸吧。"
        ),
        VoiceOption(
            id: "female-chengshu",
            nameEN: "Composed",
            nameZH: "沉稳女声",
            isPremium: true,
            previewTextEN: "Everything will be alright.",
            previewTextZH: "一切都会好起来的。"
        ),
    ]
}

// MARK: - Voice Selector View

struct VoiceSelectorView: View {
    @Environment(AppState.self) private var appState
    @State private var playingVoiceId: String? = nil
    @State private var audioCache: [String: Data] = [:]

    private var freeVoices: [VoiceOption] {
        VoiceOption.all.filter { !$0.isPremium }
    }

    private var premiumVoices: [VoiceOption] {
        VoiceOption.all.filter { $0.isPremium }
    }

    var body: some View {
        List {
            // Free Voices
            Section(L10n.t("Free Voices", "免费声线")) {
                ForEach(freeVoices) { voice in
                    VoiceRow(
                        voice: voice,
                        isSelected: appState.selectedVoiceId == voice.id,
                        isPlaying: playingVoiceId == voice.id,
                        onSelect: { appState.selectedVoiceId = voice.id },
                        onPreview: { Task { await previewVoice(voice) } }
                    )
                }
            }

            // Premium Voices
            Section {
                ForEach(premiumVoices) { voice in
                    VoiceRow(
                        voice: voice,
                        isSelected: appState.selectedVoiceId == voice.id,
                        isPlaying: playingVoiceId == voice.id,
                        onSelect: {
                            if appState.isSubscribed {
                                appState.selectedVoiceId = voice.id
                            }
                        },
                        onPreview: { Task { await previewVoice(voice) } },
                        isLocked: !appState.isSubscribed
                    )
                }
            } header: {
                HStack {
                    Text(L10n.t("Premium Voices", "高级声线"))
                    Image(systemName: "crown.fill")
                        .foregroundStyle(TreeholeTheme.warmGold)
                        .font(.caption)
                }
            } footer: {
                Text(appState.isSubscribed
                    ? L10n.t("Premium voices cost 1🍖/msg with your subscription.", "订阅后高级声线每条仅需1🍖。")
                    : L10n.t("⚠️ Premium voices cost 10🍖/msg (1🍖 with subscription)", "⚠️ 高级声线每条10🍖（订阅后仅需1🍖）"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(L10n.t("Voice Selection", "声线选择"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func previewVoice(_ voice: VoiceOption) async {
        let lang = appState.preferredLanguage
        let previewText = lang == "zh-Hans" ? voice.previewTextZH : voice.previewTextEN

        if voice.id == "apple_default" {
            // Play with Apple TTS
            playingVoiceId = voice.id
            let utterance = AVSpeechUtterance(string: previewText)
            utterance.voice = AVSpeechSynthesisVoice(language: lang == "zh-Hans" ? "zh-CN" : "en-US")
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
            utterance.pitchMultiplier = 1.2
            let synthesizer = AVSpeechSynthesizer()
            synthesizer.speak(utterance)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                playingVoiceId = nil
            }
        } else {
            // Check cache first
            if let cachedData = audioCache[voice.id] {
                playingVoiceId = voice.id
                await MainActor.run { PetVoiceService.playAudioPublic(cachedData) }
                let estimatedDuration = Double(previewText.count) * 0.1 + 1.5
                DispatchQueue.main.asyncAfter(deadline: .now() + estimatedDuration) {
                    playingVoiceId = nil
                }
                return
            }

            // Fetch from MiniMax
            playingVoiceId = voice.id
            if let audioData = await PetVoiceService.fetchMiniMaxTTS(
                text: previewText,
                language: lang,
                emotion: "calm",
                voiceId: voice.id
            ) {
                audioCache[voice.id] = audioData
                await MainActor.run { PetVoiceService.playAudioPublic(audioData) }
                let estimatedDuration = Double(previewText.count) * 0.1 + 1.5
                DispatchQueue.main.asyncAfter(deadline: .now() + estimatedDuration) {
                    playingVoiceId = nil
                }
            } else {
                playingVoiceId = nil
            }
        }
    }
}

// MARK: - Voice Row

private struct VoiceRow: View {
    let voice: VoiceOption
    let isSelected: Bool
    let isPlaying: Bool
    let onSelect: () -> Void
    let onPreview: () -> Void
    var isLocked: Bool = false

    @Environment(AppState.self) private var appState

    var body: some View {
        HStack(spacing: 12) {
            // Selection indicator
            Button(action: onSelect) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? TreeholeTheme.softPurple : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .disabled(isLocked)

            // Voice name
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(appState.preferredLanguage == "zh-Hans" ? voice.nameZH : voice.nameEN)
                        .font(.subheadline)
                        .foregroundStyle(isLocked ? .secondary : TreeholeTheme.textPrimary)
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(TreeholeTheme.warmGold)
                    }
                }
                if !voice.isPremium {
                    Text(L10n.t("Free", "免费"))
                        .font(.caption2)
                        .foregroundStyle(.green)
                } else if isLocked {
                    Text(L10n.t("Subscribe to unlock", "订阅解锁"))
                        .font(.caption2)
                        .foregroundStyle(TreeholeTheme.warmGold)
                } else {
                    Text(L10n.t("Premium", "高级"))
                        .font(.caption2)
                        .foregroundStyle(TreeholeTheme.warmGold)
                }
            }

            Spacer()

            // Preview button
            Button(action: onPreview) {
                ZStack {
                    Circle()
                        .fill(isPlaying ? TreeholeTheme.softPurple : TreeholeTheme.softPurple.opacity(0.2))
                        .frame(width: 34, height: 34)
                    Image(systemName: isPlaying ? "speaker.wave.2.fill" : "play.fill")
                        .foregroundStyle(isPlaying ? .white : TreeholeTheme.softPurple)
                        .font(.system(size: 13))
                        .symbolEffect(.variableColor.iterative, isActive: isPlaying)
                }
            }
            .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
    }
}
