import SwiftUI

struct PrimaryButton: View {
    let title: String
    var isEnabled: Bool = true
    var isLoading: Bool = false
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            guard isEnabled && !isLoading else { return }
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            action()
        }) {
            ZStack {
                // Background
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: isEnabled
                                ? [AppColors.primary, AppColors.primaryDark]
                                : [Color.gray.opacity(0.5), Color.gray.opacity(0.4)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(
                        color: isEnabled ? AppColors.primary.opacity(0.3) : Color.clear,
                        radius: isPressed ? 4 : 8,
                        x: 0,
                        y: isPressed ? 2 : 4
                    )

                // Content
                HStack(spacing: AppSpacing.xs) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    }
                    Text(title)
                        .font(AppTypography.headline)
                        .foregroundColor(.white)
                }
                .padding(.vertical, AppSpacing.md)
            }
            .frame(height: 56)
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!isEnabled || isLoading)
    }
}

struct HoldToStartButton: View {
    let title: String
    var isEnabled: Bool = true
    var holdDuration: Double = 1.2
    let action: () -> Void

    @GestureState private var isPressing = false
    @State private var holdProgress: CGFloat = 0
    @State private var didTrigger = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: isEnabled
                                ? [AppColors.primary, AppColors.primaryDark]
                                : [Color.gray.opacity(0.5), Color.gray.opacity(0.4)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(
                        color: isEnabled ? AppColors.primary.opacity(0.3) : Color.clear,
                        radius: isPressing ? 4 : 8,
                        x: 0,
                        y: isPressing ? 2 : 4
                    )

                Capsule()
                    .fill(Color.white.opacity(isEnabled ? 0.18 : 0))
                    .frame(width: geometry.size.width * holdProgress)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .clipShape(Capsule())

                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: isPressing ? "hand.point.up.left.fill" : "hand.point.up.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text(isPressing ? "Keep holding..." : title)
                        .font(AppTypography.headline)
                }
                .foregroundColor(.white)
            }
        }
        .frame(height: 56)
        .contentShape(Capsule())
        .gesture(
            LongPressGesture(minimumDuration: holdDuration, maximumDistance: 24)
                .updating($isPressing) { value, state, _ in
                    state = value
                }
                .onEnded { _ in
                    guard isEnabled else { return }
                    didTrigger = true
                    let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                    impactFeedback.impactOccurred()
                    action()
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(200))
                        withAnimation(.easeOut(duration: 0.2)) {
                            holdProgress = 0
                        }
                        didTrigger = false
                    }
                }
        )
        .onChange(of: isPressing) { _, newValue in
            guard isEnabled else {
                holdProgress = 0
                return
            }

            if newValue {
                withAnimation(.linear(duration: holdDuration)) {
                    holdProgress = 1
                }
            } else if !didTrigger {
                withAnimation(.easeOut(duration: 0.2)) {
                    holdProgress = 0
                }
            }
        }
        .opacity(isEnabled ? 1 : 0.7)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: {
            guard isEnabled else { return }
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            action()
        }) {
            Text(title)
                .font(AppTypography.callout)
                .foregroundColor(isEnabled ? AppColors.textSecondary : AppColors.textMuted)
                .padding(.vertical, AppSpacing.sm)
                .padding(.horizontal, AppSpacing.md)
        }
        .disabled(!isEnabled)
    }
}

#Preview {
    VStack(spacing: 20) {
        PrimaryButton(title: "Continue", isEnabled: true) {
            print("Tapped")
        }

        PrimaryButton(title: "Continue", isEnabled: false) {
            print("Tapped")
        }

        PrimaryButton(title: "Loading...", isLoading: true) {
            print("Tapped")
        }

        SecondaryButton(title: "Skip for now") {
            print("Secondary tapped")
        }

        HoldToStartButton(title: "Hold to start") {
            print("Hold started")
        }
    }
    .padding()
    .background(GradientBackgroundView())
}
