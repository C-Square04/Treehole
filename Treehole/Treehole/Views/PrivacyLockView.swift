import SwiftUI
import LocalAuthentication

// MARK: - Lock Gate (pre-unlock confirmation page)

struct PrivacyLockView: View {
    let lockType: PrivacyLockManager.LockType
    let title: String
    @Environment(PrivacyLockManager.self) private var lockManager
    @State private var showPasscodeEntry = false

    var body: some View {
        ZStack {
            TreeholeTheme.warmBackground.ignoresSafeArea()

            if showPasscodeEntry {
                PasscodeEntryView(lockType: lockType, title: title)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                // Gate page — user must tap to proceed
                VStack(spacing: TreeholeTheme.spacingXL) {
                    Spacer()

                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(TreeholeTheme.softPurple)
                        .symbolEffect(.pulse, options: .repeating)

                    VStack(spacing: TreeholeTheme.spacingTight) {
                        Text(title)
                            .font(.title2.bold())
                            .foregroundStyle(TreeholeTheme.textPrimary)

                        Text(L10n.t("This content is protected", "此内容已加密保护"))
                            .font(.subheadline)
                            .foregroundStyle(TreeholeTheme.textSecondary)
                    }

                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            showPasscodeEntry = true
                        }
                    } label: {
                        Label(L10n.t("Tap to Unlock", "点击解锁"), systemImage: "lock.open.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, TreeholeTheme.spacingMedium)
                            .background(TreeholeTheme.softPurple, in: RoundedRectangle(cornerRadius: TreeholeTheme.cornerLarge))
                    }
                    .padding(.horizontal, 40)

                    Spacer()
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Passcode Entry Screen

private struct PasscodeEntryView: View {
    let lockType: PrivacyLockManager.LockType
    let title: String
    @Environment(PrivacyLockManager.self) private var lockManager

    @State private var enteredDigits: [Int] = []
    @State private var shakeOffset: CGFloat = 0
    @State private var dotsRed: Bool = false
    @State private var isAuthenticating: Bool = false
    @State private var dotScales: [CGFloat] = [1.0, 1.0, 1.0, 1.0]

    private let passcodeLength = 4

    var body: some View {
        ZStack {
            TreeholeTheme.warmBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Icon + title
                VStack(spacing: TreeholeTheme.spacingMedium) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 80, weight: .regular))
                        .foregroundStyle(TreeholeTheme.softPurple)

                    VStack(spacing: 6) {
                        Text(L10n.t("Enter Passcode", "输入密码"))
                            .font(.title2.bold())
                            .foregroundStyle(TreeholeTheme.textPrimary)

                        Text(L10n.t("Enter your 4-digit passcode", "输入4位密码"))
                            .font(.subheadline)
                            .foregroundStyle(TreeholeTheme.textSecondary)
                    }
                }

                Spacer().frame(height: TreeholeTheme.spacingXL + 8)

                // 4 dots
                dotsRow
                    .offset(x: shakeOffset)

                Spacer().frame(height: TreeholeTheme.spacingXL + 16)

                // Number pad
                numberPad

                Spacer()
            }
            .padding(.horizontal, TreeholeTheme.spacingLarge)
        }
        .onAppear {
            if lockManager.isBiometricEnabled && lockManager.biometricType != .none {
                Task { await triggerBiometric() }
            }
        }
    }

    // MARK: - Dots Row

    private var dotsRow: some View {
        HStack(spacing: 20) {
            ForEach(0..<passcodeLength, id: \.self) { index in
                let isFilled = index < enteredDigits.count
                Circle()
                    .fill(isFilled
                          ? (dotsRed ? Color.red : TreeholeTheme.softPurple)
                          : TreeholeTheme.gentleLavender.opacity(0.5))
                    .overlay(
                        Circle()
                            .strokeBorder(
                                isFilled ? (dotsRed ? Color.red : TreeholeTheme.softPurple) : TreeholeTheme.gentleLavender,
                                lineWidth: 2
                            )
                    )
                    .frame(width: 18, height: 18)
                    .scaleEffect(dotScales[index])
                    .animation(.easeInOut(duration: 0.15), value: isFilled)
                    .animation(.easeInOut(duration: 0.15), value: dotsRed)
            }
        }
    }

    // MARK: - Number Pad

    private var numberPad: some View {
        VStack(spacing: TreeholeTheme.spacingMedium) {
            ForEach([[1, 2, 3], [4, 5, 6], [7, 8, 9]], id: \.self) { row in
                HStack(spacing: TreeholeTheme.spacingLarge) {
                    ForEach(row, id: \.self) { digit in
                        DigitButton(label: "\(digit)") {
                            appendDigit(digit)
                        }
                    }
                }
            }

            // Bottom row: biometric | 0 | delete
            HStack(spacing: TreeholeTheme.spacingLarge) {
                // Left: biometric or empty
                if lockManager.isBiometricEnabled && lockManager.biometricType != .none {
                    DigitButton(icon: lockManager.biometricType.icon, iconColor: TreeholeTheme.softPurple) {
                        Task { await triggerBiometric() }
                    }
                    .opacity(isAuthenticating ? 0.5 : 1)
                } else {
                    Color.clear.frame(width: 72, height: 72)
                }

                DigitButton(label: "0") {
                    appendDigit(0)
                }

                DigitButton(icon: "delete.left", iconColor: TreeholeTheme.coral) {
                    deleteDigit()
                }
            }
        }
    }

    // MARK: - Actions

    private func appendDigit(_ digit: Int) {
        guard enteredDigits.count < passcodeLength else { return }
        let index = enteredDigits.count
        enteredDigits.append(digit)
        // Bounce animation
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
            dotScales[index] = 1.3
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                dotScales[index] = 1.0
            }
        }
        if enteredDigits.count == passcodeLength {
            checkPasscode()
        }
    }

    private func deleteDigit() {
        guard !enteredDigits.isEmpty else { return }
        enteredDigits.removeLast()
    }

    private func checkPasscode() {
        let input = enteredDigits.map { String($0) }.joined()
        let success = lockManager.authenticateWithPasscode(input, for: lockType)
        if !success {
            shakeDots()
        }
    }

    private func shakeDots() {
        dotsRed = true
        withAnimation(.easeOut(duration: 0.08)) { shakeOffset = 10 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.easeInOut(duration: 0.08)) { shakeOffset = -10 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.easeInOut(duration: 0.08)) { shakeOffset = 8 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            withAnimation(.easeInOut(duration: 0.08)) { shakeOffset = -8 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            withAnimation(.easeOut(duration: 0.08)) { shakeOffset = 0 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dotsRed = false
            enteredDigits = []
            dotScales = [1.0, 1.0, 1.0, 1.0]
        }
    }

    private func triggerBiometric() async {
        isAuthenticating = true
        _ = await lockManager.authenticateWithBiometric(for: lockType)
        isAuthenticating = false
    }
}

// MARK: - Digit Button

private struct DigitButton: View {
    var label: String? = nil
    var icon: String? = nil
    var iconColor: Color = TreeholeTheme.textPrimary
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                Circle()
                    .fill(TreeholeTheme.warmPeach.opacity(0.3))
                    .overlay(
                        Circle().stroke(TreeholeTheme.warmPeach.opacity(0.5), lineWidth: 0.8)
                    )
                    .frame(width: 72, height: 72)

                if let label = label {
                    Text(label)
                        .font(.title.weight(.regular))
                        .foregroundStyle(TreeholeTheme.textPrimary)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(iconColor)
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Passcode Setup View

struct PasscodeSetupView: View {
    @Environment(PrivacyLockManager.self) private var lockManager
    @Environment(\.dismiss) private var dismiss

    enum SetupStep { case enter, confirm }

    @State private var step: SetupStep = .enter
    @State private var firstPasscode: [Int] = []
    @State private var enteredDigits: [Int] = []
    @State private var shakeOffset: CGFloat = 0
    @State private var dotsRed: Bool = false
    @State private var mismatchError: Bool = false
    @State private var dotScales: [CGFloat] = [1.0, 1.0, 1.0, 1.0]

    var onComplete: (() -> Void)? = nil

    private let passcodeLength = 4

    var body: some View {
        ZStack {
            TreeholeTheme.warmBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: TreeholeTheme.spacingMedium) {
                    Image(systemName: "lock.badge.plus")
                        .font(.system(size: 80, weight: .regular))
                        .foregroundStyle(TreeholeTheme.softPurple)

                    VStack(spacing: 6) {
                        Text(step == .enter
                             ? L10n.t("Create a Passcode", "创建密码")
                             : L10n.t("Confirm Passcode", "确认密码"))
                            .font(.title2.bold())
                            .foregroundStyle(TreeholeTheme.textPrimary)

                        Text(step == .enter
                             ? L10n.t("Enter your 4-digit passcode", "输入4位密码")
                             : L10n.t("Re-enter your passcode", "再次输入密码"))
                            .font(.subheadline)
                            .foregroundStyle(TreeholeTheme.textSecondary)
                    }

                    if mismatchError {
                        Text(L10n.t("Passcodes do not match. Try again.", "密码不匹配，请重试。"))
                            .font(.caption)
                            .foregroundStyle(.red)
                            .transition(.opacity)
                    }
                }

                Spacer().frame(height: TreeholeTheme.spacingXL + 8)

                dotsRow
                    .offset(x: shakeOffset)

                Spacer().frame(height: TreeholeTheme.spacingXL + 16)

                numberPad

                Spacer()
            }
            .padding(.horizontal, TreeholeTheme.spacingLarge)
        }
        .navigationTitle(L10n.t("Set Passcode", "设置密码"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var dotsRow: some View {
        HStack(spacing: 20) {
            ForEach(0..<passcodeLength, id: \.self) { index in
                let isFilled = index < enteredDigits.count
                Circle()
                    .fill(isFilled
                          ? (dotsRed ? Color.red : TreeholeTheme.softPurple)
                          : TreeholeTheme.gentleLavender.opacity(0.5))
                    .overlay(
                        Circle()
                            .strokeBorder(
                                isFilled ? (dotsRed ? Color.red : TreeholeTheme.softPurple) : TreeholeTheme.gentleLavender,
                                lineWidth: 2
                            )
                    )
                    .frame(width: 18, height: 18)
                    .scaleEffect(dotScales[index])
                    .animation(.easeInOut(duration: 0.15), value: isFilled)
                    .animation(.easeInOut(duration: 0.15), value: dotsRed)
            }
        }
    }

    private var numberPad: some View {
        VStack(spacing: TreeholeTheme.spacingMedium) {
            ForEach([[1, 2, 3], [4, 5, 6], [7, 8, 9]], id: \.self) { row in
                HStack(spacing: TreeholeTheme.spacingLarge) {
                    ForEach(row, id: \.self) { digit in
                        DigitButton(label: "\(digit)") { appendDigit(digit) }
                    }
                }
            }
            HStack(spacing: TreeholeTheme.spacingLarge) {
                Color.clear.frame(width: 72, height: 72)
                DigitButton(label: "0") { appendDigit(0) }
                DigitButton(icon: "delete.left", iconColor: TreeholeTheme.coral) { deleteDigit() }
            }
        }
    }

    private func appendDigit(_ digit: Int) {
        guard enteredDigits.count < passcodeLength else { return }
        let index = enteredDigits.count
        enteredDigits.append(digit)
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
            dotScales[index] = 1.3
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                dotScales[index] = 1.0
            }
        }
        if enteredDigits.count == passcodeLength {
            handleComplete()
        }
    }

    private func deleteDigit() {
        guard !enteredDigits.isEmpty else { return }
        enteredDigits.removeLast()
    }

    private func handleComplete() {
        switch step {
        case .enter:
            firstPasscode = enteredDigits
            enteredDigits = []
            dotScales = [1.0, 1.0, 1.0, 1.0]
            withAnimation { step = .confirm }
            mismatchError = false

        case .confirm:
            if enteredDigits == firstPasscode {
                let passcode = firstPasscode.map { String($0) }.joined()
                lockManager.setPasscode(passcode)
                onComplete?()
                dismiss()
            } else {
                shakeDots()
            }
        }
    }

    private func shakeDots() {
        dotsRed = true
        withAnimation(.easeOut(duration: 0.08)) { shakeOffset = 10 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.easeInOut(duration: 0.08)) { shakeOffset = -10 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.easeInOut(duration: 0.08)) { shakeOffset = 8 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            withAnimation(.easeInOut(duration: 0.08)) { shakeOffset = -8 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            withAnimation(.easeOut(duration: 0.08)) { shakeOffset = 0 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dotsRed = false
            enteredDigits = []
            firstPasscode = []
            dotScales = [1.0, 1.0, 1.0, 1.0]
            withAnimation { step = .enter }
            withAnimation { mismatchError = true }
        }
    }
}

// MARK: - Passcode Change View

struct PasscodeChangeView: View {
    @Environment(PrivacyLockManager.self) private var lockManager
    @Environment(\.dismiss) private var dismiss

    enum ChangeStep { case verifyOld, enterNew, confirmNew }

    @State private var changeStep: ChangeStep = .verifyOld
    @State private var enteredDigits: [Int] = []
    @State private var newPasscode: [Int] = []
    @State private var shakeOffset: CGFloat = 0
    @State private var dotsRed: Bool = false
    @State private var errorText: String = ""
    @State private var dotScales: [CGFloat] = [1.0, 1.0, 1.0, 1.0]

    private let passcodeLength = 4

    var body: some View {
        ZStack {
            TreeholeTheme.warmBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: TreeholeTheme.spacingMedium) {
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 80, weight: .regular))
                        .foregroundStyle(TreeholeTheme.softPurple)

                    VStack(spacing: 6) {
                        Text(stepTitle)
                            .font(.title2.bold())
                            .foregroundStyle(TreeholeTheme.textPrimary)

                        Text(stepSubtitle)
                            .font(.subheadline)
                            .foregroundStyle(TreeholeTheme.textSecondary)
                    }

                    if !errorText.isEmpty {
                        Text(errorText)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .transition(.opacity)
                    }
                }

                Spacer().frame(height: TreeholeTheme.spacingXL + 8)

                dotsRow
                    .offset(x: shakeOffset)

                Spacer().frame(height: TreeholeTheme.spacingXL + 16)

                numberPad

                Spacer()
            }
            .padding(.horizontal, TreeholeTheme.spacingLarge)
        }
        .navigationTitle(L10n.t("Change Passcode", "更改密码"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var stepTitle: String {
        switch changeStep {
        case .verifyOld: return L10n.t("Enter Current Passcode", "输入当前密码")
        case .enterNew: return L10n.t("Enter New Passcode", "输入新密码")
        case .confirmNew: return L10n.t("Confirm New Passcode", "确认新密码")
        }
    }

    private var stepSubtitle: String {
        switch changeStep {
        case .verifyOld: return L10n.t("Enter your 4-digit passcode", "输入4位密码")
        case .enterNew: return L10n.t("Enter your 4-digit passcode", "输入4位密码")
        case .confirmNew: return L10n.t("Re-enter your new passcode", "再次输入新密码")
        }
    }

    private var dotsRow: some View {
        HStack(spacing: 20) {
            ForEach(0..<passcodeLength, id: \.self) { index in
                let isFilled = index < enteredDigits.count
                Circle()
                    .fill(isFilled
                          ? (dotsRed ? Color.red : TreeholeTheme.softPurple)
                          : TreeholeTheme.gentleLavender.opacity(0.5))
                    .overlay(
                        Circle()
                            .strokeBorder(
                                isFilled ? (dotsRed ? Color.red : TreeholeTheme.softPurple) : TreeholeTheme.gentleLavender,
                                lineWidth: 2
                            )
                    )
                    .frame(width: 18, height: 18)
                    .scaleEffect(dotScales[index])
                    .animation(.easeInOut(duration: 0.15), value: isFilled)
                    .animation(.easeInOut(duration: 0.15), value: dotsRed)
            }
        }
    }

    private var numberPad: some View {
        VStack(spacing: TreeholeTheme.spacingMedium) {
            ForEach([[1, 2, 3], [4, 5, 6], [7, 8, 9]], id: \.self) { row in
                HStack(spacing: TreeholeTheme.spacingLarge) {
                    ForEach(row, id: \.self) { digit in
                        DigitButton(label: "\(digit)") { appendDigit(digit) }
                    }
                }
            }
            HStack(spacing: TreeholeTheme.spacingLarge) {
                Color.clear.frame(width: 72, height: 72)
                DigitButton(label: "0") { appendDigit(0) }
                DigitButton(icon: "delete.left", iconColor: TreeholeTheme.coral) { deleteDigit() }
            }
        }
    }

    private func appendDigit(_ digit: Int) {
        guard enteredDigits.count < passcodeLength else { return }
        let index = enteredDigits.count
        enteredDigits.append(digit)
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
            dotScales[index] = 1.3
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                dotScales[index] = 1.0
            }
        }
        if enteredDigits.count == passcodeLength {
            handleComplete()
        }
    }

    private func deleteDigit() {
        guard !enteredDigits.isEmpty else { return }
        enteredDigits.removeLast()
    }

    private func handleComplete() {
        let input = enteredDigits.map { String($0) }.joined()

        switch changeStep {
        case .verifyOld:
            if lockManager.verifyPasscode(input) {
                enteredDigits = []
                dotScales = [1.0, 1.0, 1.0, 1.0]
                errorText = ""
                withAnimation { changeStep = .enterNew }
            } else {
                shakeDots(message: L10n.t("Incorrect passcode. Try again.", "密码不正确，请重试。"))
            }

        case .enterNew:
            newPasscode = enteredDigits
            enteredDigits = []
            dotScales = [1.0, 1.0, 1.0, 1.0]
            errorText = ""
            withAnimation { changeStep = .confirmNew }

        case .confirmNew:
            if enteredDigits == newPasscode {
                let newCode = newPasscode.map { String($0) }.joined()
                lockManager.setPasscode(newCode)
                dismiss()
            } else {
                shakeDots(message: L10n.t("Passcodes do not match. Try again.", "密码不匹配，请重试。"))
                newPasscode = []
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation { changeStep = .enterNew }
                }
            }
        }
    }

    private func shakeDots(message: String) {
        dotsRed = true
        withAnimation(.easeOut(duration: 0.08)) { shakeOffset = 10 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.easeInOut(duration: 0.08)) { shakeOffset = -10 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.easeInOut(duration: 0.08)) { shakeOffset = 8 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            withAnimation(.easeInOut(duration: 0.08)) { shakeOffset = -8 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            withAnimation(.easeOut(duration: 0.08)) { shakeOffset = 0 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dotsRed = false
            enteredDigits = []
            dotScales = [1.0, 1.0, 1.0, 1.0]
            withAnimation { errorText = message }
        }
    }
}
