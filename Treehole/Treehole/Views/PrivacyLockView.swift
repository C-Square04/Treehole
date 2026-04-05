import SwiftUI
import LocalAuthentication

struct PrivacyLockView: View {
    let lockType: PrivacyLockManager.LockType
    let title: String  // "My Clouds" or "Journal"
    @Environment(PrivacyLockManager.self) private var lockManager
    @State private var pinInput: String = ""
    @State private var showPINField: Bool = false
    @State private var authError: String?
    @State private var isAuthenticating: Bool = false
    @State private var lockScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            TreeholeTheme.warmBackground.ignoresSafeArea()

            VStack(spacing: TreeholeTheme.spacingLarge) {
                Spacer()

                // Lock icon (animated)
                Image(systemName: "lock.fill")
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(TreeholeTheme.softPurple)
                    .scaleEffect(lockScale)
                    .animation(
                        .easeInOut(duration: 1.8).repeatForever(autoreverses: true),
                        value: lockScale
                    )
                    .onAppear { lockScale = 1.08 }

                // Title
                VStack(spacing: TreeholeTheme.spacingTight) {
                    Text(L10n.t("This content is locked", "此内容已锁定"))
                        .font(.title3.bold())
                        .foregroundStyle(TreeholeTheme.textPrimary)
                    Text(title)
                        .font(.subheadline)
                        .foregroundStyle(TreeholeTheme.textSecondary)
                }

                // Error message
                if let error = authError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, TreeholeTheme.spacingSmall)
                        .padding(.vertical, 6)
                        .background(.red.opacity(0.8), in: Capsule())
                        .transition(.opacity)
                }

                // FaceID/TouchID button (primary)
                Button {
                    Task { await authenticate() }
                } label: {
                    HStack(spacing: TreeholeTheme.spacingSmall) {
                        Image(systemName: biometricIcon)
                            .font(.title3)
                        Text(biometricLabel)
                            .font(.headline.weight(.semibold))
                        if isAuthenticating {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(TreeholeTheme.textPrimary)
                        }
                    }
                    .foregroundStyle(TreeholeTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, TreeholeTheme.spacingMedium)
                }
                .disabled(isAuthenticating)
                .glassCard()
                .padding(.horizontal)

                // "Use PIN" button (secondary, if PIN is set)
                if lockManager.lockPIN != nil {
                    Button {
                        withAnimation { showPINField.toggle() }
                        authError = nil
                    } label: {
                        Text(showPINField
                             ? L10n.t("Hide PIN", "隐藏 PIN")
                             : L10n.t("Use PIN", "使用 PIN"))
                            .font(.subheadline)
                            .foregroundStyle(TreeholeTheme.softPurple)
                    }

                    // PIN input field
                    if showPINField {
                        VStack(spacing: TreeholeTheme.spacingSmall) {
                            SecureField(L10n.t("Enter PIN", "输入 PIN"), text: $pinInput)
                                .keyboardType(.numberPad)
                                .textContentType(.oneTimeCode)
                                .font(.title2)
                                .multilineTextAlignment(.center)
                                .padding(TreeholeTheme.spacingSmall)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: TreeholeTheme.cornerMedium))
                                .frame(maxWidth: 200)

                            Button {
                                verifyPIN()
                            } label: {
                                Text(L10n.t("Confirm", "确认"))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, TreeholeTheme.spacingLarge)
                                    .padding(.vertical, TreeholeTheme.spacingSmall)
                                    .background(TreeholeTheme.softPurple, in: Capsule())
                            }
                            .disabled(pinInput.isEmpty)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.horizontal)
                    }
                }

                Spacer()
            }
            .padding()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            lockManager.lock()
        }
    }

    // MARK: - Helpers

    private var biometricIcon: String {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            return context.biometryType == .faceID ? "faceid" : "touchid"
        }
        return "faceid"
    }

    private var biometricLabel: String {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            return context.biometryType == .faceID
                ? L10n.t("Unlock with Face ID", "使用面容 ID 解锁")
                : L10n.t("Unlock with Touch ID", "使用指纹 ID 解锁")
        }
        return L10n.t("Unlock with Biometrics", "使用生物识别解锁")
    }

    private func authenticate() async {
        isAuthenticating = true
        authError = nil
        let success = await lockManager.authenticate(for: lockType)
        if !success {
            withAnimation {
                authError = L10n.t("Authentication failed. Try again.", "认证失败，请重试。")
            }
        }
        isAuthenticating = false
    }

    private func verifyPIN() {
        let success = lockManager.authenticateWithPIN(pinInput, for: lockType)
        if success {
            pinInput = ""
            authError = nil
        } else {
            withAnimation {
                authError = L10n.t("Incorrect PIN. Try again.", "PIN 不正确，请重试。")
            }
            pinInput = ""
        }
    }
}

// MARK: - PIN Settings View

struct PINSettingsView: View {
    let lockManager: PrivacyLockManager
    @Environment(\.dismiss) private var dismiss
    @State private var newPIN: String = ""
    @State private var confirmPIN: String = ""
    @State private var errorMessage: String?
    @State private var successMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                TreeholeTheme.warmBackground.ignoresSafeArea()
                Form {
                    Section {
                        SecureField(L10n.t("New PIN (4–6 digits)", "新 PIN（4–6 位数字）"), text: $newPIN)
                            .keyboardType(.numberPad)
                        SecureField(L10n.t("Confirm PIN", "确认 PIN"), text: $confirmPIN)
                            .keyboardType(.numberPad)
                    } header: {
                        Text(L10n.t("Set PIN Code", "设置 PIN 码"))
                    } footer: {
                        Text(L10n.t(
                            "PIN is used as a fallback when biometrics are unavailable.",
                            "PIN 用于生物识别不可用时的备用方案。"
                        ))
                    }

                    if let error = errorMessage {
                        Section {
                            Text(error).foregroundStyle(.red).font(.caption)
                        }
                    }
                    if let success = successMessage {
                        Section {
                            Text(success).foregroundStyle(.green).font(.caption)
                        }
                    }

                    Section {
                        Button(L10n.t("Save PIN", "保存 PIN")) {
                            savePIN()
                        }
                        .disabled(newPIN.isEmpty)

                        if lockManager.lockPIN != nil {
                            Button(L10n.t("Remove PIN", "删除 PIN"), role: .destructive) {
                                lockManager.lockPIN = nil
                                successMessage = L10n.t("PIN removed.", "PIN 已删除。")
                                newPIN = ""
                                confirmPIN = ""
                            }
                        }
                    }
                }
            }
            .navigationTitle(L10n.t("PIN Code", "PIN 码"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.t("Done", "完成")) { dismiss() }
                }
            }
        }
    }

    private func savePIN() {
        errorMessage = nil
        successMessage = nil
        let trimmed = newPIN.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 4, trimmed.count <= 6, trimmed.allSatisfy(\.isNumber) else {
            errorMessage = L10n.t("PIN must be 4–6 digits.", "PIN 必须是 4–6 位数字。")
            return
        }
        guard trimmed == confirmPIN else {
            errorMessage = L10n.t("PINs do not match.", "两次输入的 PIN 不匹配。")
            return
        }
        lockManager.lockPIN = trimmed
        successMessage = L10n.t("PIN saved.", "PIN 已保存。")
        newPIN = ""
        confirmPIN = ""
    }
}
