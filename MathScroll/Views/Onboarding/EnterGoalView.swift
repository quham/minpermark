import SwiftUI

struct EnterGoalView: View {
    @Environment(AppState.self) var appState
    let onContinue: () -> Void

    @FocusState private var isInputFocused: Bool

    private var isValid: Bool {
        appState.onboardingGoal.isGoalValid
    }

    private var showValidation: Bool {
        !appState.onboardingGoal.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isValid
    }

    var body: some View {
        @Bindable var appState = appState
        VStack(spacing: 0) {
            Spacer()
                .frame(height: AppSpacing.xxxl)

            // Title section
            VStack(spacing: AppSpacing.sm) {
                Text(LocalizedStrings.enterGoalTitle)
                    .font(AppTypography.title)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(LocalizedStrings.enterGoalSubtitle)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, AppSpacing.lg)

            Spacer()
                .frame(height: AppSpacing.xxl)

            // Input field
            InputField(
                placeholder: "e.g. Get healthier, Learn Spanish, Feel more focused",
                text: $appState.onboardingGoal.title,
                isValid: isValid,
                focusState: $isInputFocused
            )
            .padding(.horizontal, AppSpacing.lg)

            if showValidation {
                Text("Goal should be at least 3 characters.")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.warning)
                    .padding(.top, AppSpacing.xs)
            }

            Spacer()

            // Continue button
            PrimaryButton(
                title: LocalizedStrings.continueButton,
                isEnabled: isValid
            ) {
                isInputFocused = false
                onContinue()
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xxl)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isInputFocused = false
        }
        .task {
            // A small delay ensures the TabView transition is complete
            // before requesting the keyboard.
            try? await Task.sleep(for: .milliseconds(600))
            isInputFocused = true
        }
    }
}

#Preview {
    ZStack {
        GradientBackgroundView()
        EnterGoalView(onContinue: {})
            .environment(AppState())
    }
}
