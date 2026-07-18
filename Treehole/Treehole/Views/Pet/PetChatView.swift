import SwiftUI
import SwiftData

struct PetChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    /// Newest 20 messages, newest first — chat history grows without bound,
    /// so the view must never materialize all of it. Reversed for display.
    @Query private var recentMessages: [ChatMessage]
    @Query private var pets: [Pet]

    init() {
        var descriptor = FetchDescriptor<ChatMessage>(
            sortBy: [SortDescriptor(\ChatMessage.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 20
        _recentMessages = Query(descriptor)
    }

    @State private var inputText = ""
    @State private var isThinking = false
    @State private var isSpeaking = false
    @State private var isListening = false
    @State private var micPermissionGranted = false
    @State private var voiceTranscript = ""
    @State private var ttsEnabled = true
    @State private var errorMessage: String?
    @State private var chatMode: ChatMode = .basic
    @State private var showClearConfirm = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var messages: [ChatMessage] {
        recentMessages.reversed()
    }

    private var pet: Pet? {
        pets.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                TreeholeTheme.cloudyBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    hungerBanner

                    // Voice/pet errors were silently swallowed before —
                    // surface them briefly at the top of the chat.
                    if let error = errorMessage {
                        ErrorBanner(message: error)
                            .padding(.top, 4)
                            .task(id: error) {
                                try? await Task.sleep(for: .seconds(3))
                                errorMessage = nil
                            }
                    }

                    chatScrollView

                    if isThinking {
                        typingIndicator
                    }

                    modeSwitcher

                    inputBar
                }
            }
            .navigationTitle(L10n.t("Chat with Companion 🐱", "与伴侣聊天 🐱"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.t("Done", "完成")) { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 8) {
                        NavigationLink {
                            VoiceSelectorView()
                        } label: {
                            Image(systemName: "waveform.circle")
                                .foregroundStyle(TreeholeTheme.softPurple)
                        }
                        .accessibilityLabel(L10n.t("Voice selection", "声线选择"))
                        Menu {
                            Button {
                                ttsEnabled.toggle()
                                if !ttsEnabled { PetVoiceService.stopSpeaking() }
                            } label: {
                                Label(
                                    ttsEnabled ? L10n.t("Mute Voice", "关闭语音") : L10n.t("Enable Voice", "开启语音"),
                                    systemImage: ttsEnabled ? "speaker.slash.fill" : "speaker.wave.2.fill"
                                )
                            }
                            Button(role: .destructive) {
                                showClearConfirm = true
                            } label: {
                                Label(L10n.t("Clear Chat", "清除聊天"), systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundStyle(TreeholeTheme.softPurple)
                        }
                        .accessibilityLabel(L10n.t("More options", "更多选项"))
                    }
                }
            }
            .onAppear {
                Task { await requestPermissions() }
                sendWelcomeIfNeeded()
            }
            .onDisappear {
                PetVoiceService.stopSpeaking()
                if isListening { PetVoiceService.stopListening() }
            }
            .confirmationDialog(L10n.t("Clear all chat history?", "清除所有聊天记录？"), isPresented: $showClearConfirm, titleVisibility: .visible) {
                Button(L10n.t("Clear", "清除"), role: .destructive) {
                    // The live query is capped at 20 — clearing must fetch
                    // the full history explicitly.
                    let all = (try? modelContext.fetch(FetchDescriptor<ChatMessage>())) ?? []
                    for msg in all {
                        modelContext.delete(msg)
                    }
                    try? modelContext.save()
                }
            }
        }
    }

    // MARK: - Subviews

    private var hungerBanner: some View {
        let hunger = pet?.hungerLevel ?? 0
        let isPremiumExpensive = chatMode == .premium && !appState.isSubscribed
        return HStack(spacing: 6) {
            Image(systemName: "fork.knife")
                .foregroundStyle(TreeholeTheme.coral)
            Text(isPremiumExpensive
                ? L10n.t("🍖 \(hunger)/100 (10 per msg)", "🍖 \(hunger)/100 (每条10)")
                : L10n.t("🍖 \(hunger)/100 (1 per msg)", "🍖 \(hunger)/100 (每条1)"))
                .font(.caption.bold())
                .foregroundStyle(hunger == 0 ? TreeholeTheme.coral : TreeholeTheme.textSecondary)
            Spacer()
            if hunger == 0 {
                Text(L10n.t("I'm hungry! Feed me to continue chatting 🍖", "我饿了！喂我才能继续聊天 🍖"))
                    .font(.caption)
                    .foregroundStyle(TreeholeTheme.coral)
            }
        }
        .padding(.horizontal, TreeholeTheme.spacingMedium)
        .padding(.vertical, TreeholeTheme.spacingTight)
        .background(.ultraThinMaterial)
    }

    private var chatScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: TreeholeTheme.spacingSmall) {
                    ForEach(messages) { message in
                        ChatBubbleView(message: message)
                            .id(message.id)
                    }

                    if isSpeaking {
                        speakingIndicator
                            .id("speaking")
                    }

                    // Spacer anchor for scroll-to-bottom
                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .padding(TreeholeTheme.spacingMedium)
            }
            // Keyed on the newest message id, not count — count pins at the
            // fetch limit once history exceeds it and would stop firing.
            .onChange(of: recentMessages.first?.id) { _, _ in
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .onChange(of: isSpeaking) { _, _ in
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .onAppear {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        }
    }

    private var typingIndicator: some View {
        HStack(spacing: TreeholeTheme.spacingTight) {
            Text("🐱")
                .font(.title3)
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(TreeholeTheme.softPurple)
                        .frame(width: 8, height: 8)
                        .scaleEffect(isThinking && !reduceMotion ? 1.2 : 0.8)
                        .animation(
                            reduceMotion ? nil : .easeInOut(duration: 0.5).repeatForever().delay(Double(i) * 0.15),
                            value: isThinking
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(TreeholeTheme.softPurple.opacity(0.15), in: RoundedRectangle(cornerRadius: 18))
            Spacer()
        }
        .padding(.horizontal, TreeholeTheme.spacingMedium)
        .padding(.bottom, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.t("Pet is typing", "宠物正在输入"))
    }

    private var speakingIndicator: some View {
        HStack(spacing: 6) {
            Image(systemName: "speaker.wave.2.fill")
                .foregroundStyle(TreeholeTheme.softPurple)
                .symbolEffect(.variableColor.iterative, isActive: !reduceMotion)
                .accessibilityHidden(true)
            Text(L10n.t("Pet is speaking...", "宠物正在说话..."))
                .font(.caption)
                .foregroundStyle(TreeholeTheme.textSecondary)
        }
        .padding(.horizontal, TreeholeTheme.spacingMedium)
        .padding(.vertical, TreeholeTheme.spacingTight)
        .background(TreeholeTheme.softPurple.opacity(0.1), in: Capsule())
    }

    private var modeSwitcher: some View {
        HStack(spacing: 8) {
            Button {
                chatMode = .basic
            } label: {
                Text(L10n.t("⚡ Basic", "⚡ 基础"))
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(chatMode == .basic ? TreeholeTheme.skyBlue.opacity(0.3) : Color.clear,
                                in: Capsule())
            }
            .accessibilityLabel(L10n.t("Basic mode", "基础模式"))
            .accessibilityAddTraits(chatMode == .basic ? [.isSelected] : [])

            Button {
                chatMode = .premium
            } label: {
                VStack(spacing: 1) {
                    Text(L10n.t("✨ Premium", "✨ 高级"))
                        .font(.caption.bold())
                    Text(appState.isSubscribed
                        ? L10n.t("1 🍖/msg", "1 🍖/条")
                        : L10n.t("10 🍖/msg", "10 🍖/条"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(chatMode == .premium ? TreeholeTheme.warmGold.opacity(0.3) : Color.clear,
                            in: Capsule())
            }
            .accessibilityLabel(L10n.t("Premium mode", "高级模式"))
            .accessibilityAddTraits(chatMode == .premium ? [.isSelected] : [])

            Spacer()
        }
        .foregroundStyle(TreeholeTheme.textPrimary)
        .padding(.horizontal)
        .padding(.vertical, 4)
    }

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: TreeholeTheme.spacingSmall) {
                // Microphone button
                Button {
                    Task { await toggleListening() }
                } label: {
                    ZStack {
                        Circle()
                            .fill(isListening ? TreeholeTheme.coral : TreeholeTheme.softPurple.opacity(0.2))
                            .frame(width: 40, height: 40)
                        Image(systemName: isListening ? "waveform" : "mic.fill")
                            .foregroundStyle(isListening ? .white : TreeholeTheme.softPurple)
                            .font(.system(size: 16))
                            .symbolEffect(.variableColor.iterative, isActive: isListening && !reduceMotion)
                    }
                }
                .disabled((pet?.hungerLevel ?? 0) == 0)
                .accessibilityLabel(isListening
                    ? L10n.t("Stop listening and send", "停止聆听并发送")
                    : L10n.t("Voice input", "语音输入"))

                // Text field
                ZStack(alignment: .leading) {
                    if inputText.isEmpty && voiceTranscript.isEmpty {
                        Text(L10n.t("Type a message...", "输入消息..."))
                            .foregroundStyle(TreeholeTheme.textLight)
                            .font(.subheadline)
                    }
                    TextField("", text: isListening ? $voiceTranscript : $inputText, axis: .vertical)
                        .font(.subheadline)
                        .lineLimit(4)
                        .disabled(isListening)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: TreeholeTheme.cornerMedium))

                // Send button
                Button {
                    Task { await sendMessage() }
                } label: {
                    Circle()
                        .fill(canSend ? TreeholeTheme.warmGold : TreeholeTheme.textLight.opacity(0.3))
                        .frame(width: 40, height: 40)
                        .overlay {
                            Image(systemName: "arrow.up")
                                .foregroundStyle(canSend ? TreeholeTheme.textPrimary : .white)
                                .font(.system(size: 16, weight: .bold))
                        }
                }
                .disabled(!canSend)
                .accessibilityLabel(L10n.t("Send message", "发送消息"))
            }
            .padding(.horizontal, TreeholeTheme.spacingMedium)
            .padding(.vertical, TreeholeTheme.spacingSmall)
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - Computed

    private var canSend: Bool {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        let hunger = pet?.hungerLevel ?? 0
        let cost: Int = chatMode == .premium && !appState.isSubscribed ? 10 : 1
        return !text.isEmpty && !isThinking && hunger >= cost
    }

    // MARK: - Actions

    private func requestPermissions() async {
        micPermissionGranted = await PetVoiceService.requestSTTPermission()
    }

    private func sendWelcomeIfNeeded() {
        guard recentMessages.isEmpty, let pet = pets.first else { return }
        let lang = appState.preferredLanguage
        let welcome = L10n.t(
            "Meow~ Hi there! I'm \(pet.name), so glad to see you 😊 How are you feeling today?",
            "喵~ 你好！我是\(pet.name)，很高兴见到你 😊 今天心情怎么样？"
        )
        let msg = ChatMessage(text: welcome, isFromUser: false)
        modelContext.insert(msg)
        try? modelContext.save()
        if ttsEnabled {
            // Welcome line always uses the premium "sweet girl" voice for warmth.
            PetVoiceService.speak(welcome, language: lang, mode: .premium, messageId: msg.id)
            isSpeaking = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) { isSpeaking = false }
        }
    }

    private func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let pet = pets.first else { return }

        // Determine hunger cost
        let cost: Int
        if chatMode == .premium {
            cost = appState.isSubscribed ? 1 : 10  // Subscribers pay 1 even for premium
        } else {
            cost = 1
        }

        guard pet.hungerLevel >= cost else { return }

        inputText = ""

        // Save user message
        let userMsg = ChatMessage(text: text, isFromUser: true)
        modelContext.insert(userMsg)

        // Decrease hunger
        pet.hungerLevel = max(0, pet.hungerLevel - cost)
        try? modelContext.save()
        AnalyticsService.track("pet_chatted")

        // Show typing indicator
        isThinking = true

        // Build history for context — newest-first query, so the last 10 in
        // chronological order are prefix(10) reversed.
        let history = recentMessages.prefix(10).reversed().map { msg -> (role: String, content: String) in
            (role: msg.isFromUser ? "user" : "assistant", content: msg.text)
        }

        // Get AI reply using current mode and app language
        let reply = await PetChatService.generateReply(
            userMessage: text,
            recentHistory: history,
            petMood: pet.mood.labelEN,
            petHunger: pet.hungerLevel,
            mode: chatMode,
            language: appState.preferredLanguage
        )

        isThinking = false

        // Save pet reply with mode label
        let petMsg = ChatMessage(text: reply, isFromUser: false)
        petMsg.modeRaw = chatMode == .premium ? "premium" : "basic"
        modelContext.insert(petMsg)
        try? modelContext.save()

        // TTS with mode — subscribers always get premium voice regardless of chat mode
        if ttsEnabled {
            isSpeaking = true
            let voiceMode: ChatMode = appState.isSubscribed ? .premium : chatMode
            PetVoiceService.speak(reply, language: appState.preferredLanguage, mode: voiceMode, messageId: petMsg.id)
            let estimatedDuration = Double(reply.count) * 0.08 + 1.0
            DispatchQueue.main.asyncAfter(deadline: .now() + estimatedDuration) {
                isSpeaking = false
            }
        }
    }

    private func toggleListening() async {
        if isListening {
            // Stop listening and send transcribed text
            PetVoiceService.stopListening()
            isListening = false
            let transcript = voiceTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
            voiceTranscript = ""
            if !transcript.isEmpty {
                inputText = transcript
                await sendMessage()
            }
        } else {
            guard micPermissionGranted else {
                micPermissionGranted = await PetVoiceService.requestSTTPermission()
                return
            }
            isListening = true
            voiceTranscript = ""
            do {
                let stream = try await PetVoiceService.startListening(language: appState.preferredLanguage)
                for await partial in stream {
                    voiceTranscript = partial
                }
                // Stream ended (final result)
                isListening = false
                let transcript = voiceTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
                voiceTranscript = ""
                if !transcript.isEmpty {
                    inputText = transcript
                    await sendMessage()
                }
            } catch {
                isListening = false
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Chat Bubble

struct ChatBubbleView: View {
    let message: ChatMessage
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isFromUser {
                Spacer(minLength: 60)
                Text(message.text)
                    .font(.subheadline)
                    .foregroundStyle(TreeholeTheme.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(TreeholeTheme.coral.opacity(0.2), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(TreeholeTheme.coral.opacity(0.3), lineWidth: 1)
                    )
            } else {
                Text("🐱")
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text(message.text)
                        .font(.subheadline)
                        .foregroundStyle(TreeholeTheme.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(TreeholeTheme.softPurple.opacity(0.15), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(TreeholeTheme.softPurple.opacity(0.3), lineWidth: 1)
                        )
                    HStack(spacing: 8) {
                        // Replay button - always show on pet messages
                        if !message.isFromUser {
                            Button {
                                if PetVoiceService.hasCachedAudio(messageId: message.id) {
                                    PetVoiceService.replay(messageId: message.id)
                                } else {
                                    PetVoiceService.speak(message.text, language: appState.preferredLanguage, mode: message.mode, messageId: message.id)
                                }
                            } label: {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(TreeholeTheme.softPurple)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(L10n.t("Play message audio", "播放消息语音"))
                        }
                        Spacer()
                        Text(L10n.t(message.mode.labelEN, message.mode.labelZH))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.trailing, 4)
                }
                Spacer(minLength: 60)
            }
        }
    }
}
