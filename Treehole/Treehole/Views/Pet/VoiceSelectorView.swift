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
    let sampleFileName: String?  // nil for apple_default
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
            previewTextZH: "你好，我一直在这里！",
            sampleFileName: nil
        ),
        VoiceOption(
            id: "female-tianmei",
            nameEN: "Sweet Girl",
            nameZH: "甜美少女",
            isPremium: true,
            previewTextEN: "Hi, I'm your companion!",
            previewTextZH: "你好，我是你的小伙伴！",
            sampleFileName: "sweet_girl"
        ),
        VoiceOption(
            id: "English_Graceful_Lady",
            nameEN: "Graceful Lady",
            nameZH: "优雅女声",
            isPremium: true,
            previewTextEN: "I'm always here to listen.",
            previewTextZH: "我一直在这里倾听。",
            sampleFileName: "graceful_lady"
        ),
        VoiceOption(
            id: "female-yujie",
            nameEN: "Calm & Mature",
            nameZH: "温柔知性",
            isPremium: true,
            previewTextEN: "Take a deep breath with me.",
            previewTextZH: "跟我一起深呼吸吧。",
            sampleFileName: "calm_mature"
        ),
        VoiceOption(
            id: "female-chengshu",
            nameEN: "Composed",
            nameZH: "沉稳女声",
            isPremium: true,
            previewTextEN: "Everything will be alright.",
            previewTextZH: "一切都会好起来的。",
            sampleFileName: "composed"
        ),
    ]
}

// MARK: - Voice Selector View

struct VoiceSelectorView: View {
    @Environment(AppState.self) private var appState
    @State private var playingVoiceId: String? = nil

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

        if voice.sampleFileName == nil {
            // Apple TTS trial
            playingVoiceId = voice.id
            let demoText = lang == "zh-Hans" ? "你好，我一直在这里陪着你！" : "Hello, I'm always here for you!"
            PetVoiceService.speakTrial(demoText, language: lang)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                playingVoiceId = nil
            }
        } else {
            // Play from bundle sample file
            if let fileName = voice.sampleFileName,
               let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") {
                playingVoiceId = voice.id
                let data = try? Data(contentsOf: url)
                if let data {
                    await MainActor.run { PetVoiceService.playAudioPublic(data) }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                        playingVoiceId = nil
                    }
                } else {
                    playingVoiceId = nil
                }
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
