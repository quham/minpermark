import SwiftUI

struct NamePromptView: View {
    @Environment(AppState.self) var appState
    let onContinue: () -> Void

    @FocusState private var isInputFocused: Bool

    private var trimmedName: String {
        appState.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isValid: Bool {
        !trimmedName.isEmpty
    }

    var body: some View {
        @Bindable var appState = appState
        VStack(spacing: 0) {
            Spacer()
                .frame(height: AppSpacing.xxxl)

            // Title section
            VStack(spacing: AppSpacing.sm) {
                Text(LocalizedStrings.namePromptTitle)
                    .font(AppTypography.title)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(LocalizedStrings.namePromptSubtitle)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, AppSpacing.lg)

            Spacer()
                .frame(height: AppSpacing.xxl)

            // Input field
            InputField(
                placeholder: "e.g. Alex",
                text: $appState.displayName,
                isValid: isValid,
                maxLength: 40,
                showCharacterCount: false,
                focusState: $isInputFocused
            )
            .padding(.horizontal, AppSpacing.lg)

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
        NamePromptView(onContinue: {})
            .environment(AppState())
    }
}
