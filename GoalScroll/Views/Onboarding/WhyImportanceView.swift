import SwiftUI

struct WhyImportanceView: View {
    @Environment(AppState.self) var appState
    let onContinue: () -> Void

    @FocusState private var isTextFieldFocused: Bool

    private var isValid: Bool {
        appState.onboardingGoal.why.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3
    }

    private var showValidation: Bool {
        !appState.onboardingGoal.why.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isValid
    }

    var body: some View {
        @Bindable var appState = appState
        ScrollView {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: AppSpacing.xl)

                // Title section
                VStack(spacing: AppSpacing.sm) {
                    Text(LocalizedStrings.whyTitle)
                        .font(AppTypography.title)
                        .foregroundColor(AppColors.textPrimary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, AppSpacing.lg)

                Spacer()
                    .frame(height: AppSpacing.xxl)

                // Importance slider
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    HStack {
                        Text("How important is this goal?")
                            .font(AppTypography.subheadline)
                            .foregroundColor(AppColors.textSecondary)

                        Spacer()

                        Text("\(appState.onboardingGoal.importance)/10")
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.primary)
                    }

                    // Custom slider
                    ImportanceSlider(value: $appState.onboardingGoal.importance)
                }
                .padding(.horizontal, AppSpacing.lg)

                Spacer()
                    .frame(height: AppSpacing.xl)

                // Why text area
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Tell us more")
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textSecondary)

                    TextAreaField(
                        placeholder: "What will achieving this goal mean for you?",
                        text: $appState.onboardingGoal.why,
                        minHeight: 120,
                        focusState: $isTextFieldFocused
                    )

                    if showValidation {
                        Text("Please share why this matters to you.")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.warning)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)

                Spacer()
                    .frame(minHeight: AppSpacing.xxxl)
            }
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(
                title: LocalizedStrings.saveThis,
                isEnabled: isValid
            ) {
                isTextFieldFocused = false
                onContinue()
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.lg)
            .background(
                LinearGradient(
                    colors: [Color.white.opacity(0), Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 100)
                .allowsHitTesting(false)
            )
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isTextFieldFocused = false
        }
        .task {
            // A small delay ensures the TabView transition is complete
            // before requesting the keyboard.
            try? await Task.sleep(for: .milliseconds(600))
            isTextFieldFocused = true
        }
    }
}

struct ImportanceSlider: View {
    @Binding var value: Int
    @State private var dragValue: Double = 1
    @State private var isEditing = false
    private let range: ClosedRange<Double> = 1...10

    private var message: String {
        switch value {
        case 1...2:
            return "Just exploring"
        case 3...4:
            return "Nice to have"
        case 5...6:
            return "I care about this"
        case 7...8:
            return "This really matters"
        default:
            return "This is a non-negotiable"
        }
    }

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            GeometryReader { geometry in
                let trackHeight: CGFloat = 6
                let thumbSize: CGFloat = 24
                let availableWidth = max(1, geometry.size.width - thumbSize)
                let progress = (dragValue - range.lowerBound) / (range.upperBound - range.lowerBound)
                let clampedProgress = min(max(progress, 0), 1)
                let thumbOffset = availableWidth * clampedProgress
                let gradient = LinearGradient(
                    colors: [AppColors.primaryLight, AppColors.primary, AppColors.primaryDark],
                    startPoint: .leading,
                    endPoint: .trailing
                )

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppColors.inputBackground)
                        .frame(height: trackHeight)

                    Capsule()
                        .fill(gradient)
                        .frame(width: thumbOffset + thumbSize / 2, height: trackHeight)

                    Circle()
                        .fill(Color.white)
                        .frame(width: thumbSize, height: thumbSize)
                        .overlay(
                            Circle()
                                .strokeBorder(AppColors.inputBorder, lineWidth: 1)
                        )
                        .shadow(color: AppColors.shadowColor, radius: 4, x: 0, y: 2)
                        .offset(x: thumbOffset)
                }
                .frame(height: max(thumbSize, trackHeight))
                .contentShape(Rectangle())
                .highPriorityGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            isEditing = true
                            let locationX = min(max(0, gesture.location.x - thumbSize / 2), availableWidth)
                            let percent = locationX / availableWidth
                            dragValue = range.lowerBound + percent * (range.upperBound - range.lowerBound)
                        }
                        .onEnded { _ in
                            isEditing = false
                            let rounded = Int(dragValue.rounded())
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                value = rounded
                                dragValue = Double(rounded)
                            }
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                        }
                )
            }
            .frame(height: 32)
            .onAppear {
                dragValue = Double(value)
            }
            .onChange(of: value) { _, newValue in
                if !isEditing {
                    dragValue = Double(newValue)
                }
            }

            Text(message)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textMuted)
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                .strokeBorder(AppColors.inputBorder, lineWidth: 1)
        )
    }
}

#Preview {
    ZStack {
        GradientBackgroundView()
        WhyImportanceView(onContinue: {})
            .environment(AppState())
    }
}
