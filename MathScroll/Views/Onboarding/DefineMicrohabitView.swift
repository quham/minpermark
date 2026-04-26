import SwiftUI

struct DefineMicrohabitView: View {
    @Environment(AppState.self) var appState
    let onContinue: () -> Void

    @FocusState private var isInputFocused: Bool

    private var isValid: Bool {
        appState.onboardingGoal.isMicroHabitValid
    }

    private var showValidation: Bool {
        !appState.onboardingGoal.microHabit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isValid
    }

    // Pre-defined suggestions based on common goals
    private var defaultSuggestions: [String] {
        let goal = appState.onboardingGoal.title.lowercased()

        if goal.contains("health") || goal.contains("fit") || goal.contains("exercise") {
            return ["Do 5 pushups", "Walk for 5 minutes", "Drink a glass of water", "Stretch for 2 minutes", "Take the stairs once"]
        } else if goal.contains("spanish") || goal.contains("language") || goal.contains("learn") {
            return ["Learn 1 new word", "Practice for 5 minutes", "Listen to 1 podcast", "Read 1 sentence aloud", "Write 3 words"]
        } else if goal.contains("read") || goal.contains("book") {
            return ["Read 1 page", "Read for 5 minutes", "Read 1 paragraph", "Open my book", "Highlight 1 quote"]
        } else if goal.contains("meditat") || goal.contains("mindful") || goal.contains("focus") {
            return ["Breathe deeply 5 times", "Sit quietly for 1 minute", "Notice 3 things around me", "Close eyes for 30 seconds"]
        } else if goal.contains("write") || goal.contains("journal") {
            return ["Write 1 sentence", "Journal for 2 minutes", "Write 3 words", "Open my notebook", "Describe my mood"]
        } else {
            return ["Do it for 2 minutes", "Take the first small step", "Start and stop if needed", "Do the bare minimum version"]
        }
    }

    private var displayedSuggestions: [String] {
        appState.cachedMicrohabitSuggestions.isEmpty ? defaultSuggestions : appState.cachedMicrohabitSuggestions
    }

    var body: some View {
        @Bindable var appState = appState
        ScrollView {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: AppSpacing.xl)

                // Title section
                VStack(spacing: AppSpacing.sm) {
                    Text(LocalizedStrings.microHabitTitle)
                        .font(AppTypography.title)
                        .foregroundColor(AppColors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(LocalizedStrings.microHabitSubtitle)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, AppSpacing.lg)

                Spacer()
                    .frame(height: AppSpacing.xl)

                // Suggestion chips
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Suggestions")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textMuted)
                        .padding(.horizontal, AppSpacing.lg)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppSpacing.xs) {
                            ForEach(displayedSuggestions, id: \.self) { suggestion in
                                ChipView(text: suggestion) {
                                    withAnimation {
                                        appState.onboardingGoal.microHabit = suggestion
                                    }
                                    AnalyticsService.shared.capture(Constants.AnalyticsEvents.microHabitSuggestionUsed)
                                }
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                    }
                }

                Spacer()
                    .frame(height: AppSpacing.lg)

                // Input field
                InputField(
                    placeholder: "e.g. Do 10 pushups every morning",
                    text: $appState.onboardingGoal.microHabit,
                    isValid: isValid,
                    focusState: $isInputFocused
                )
                .padding(.horizontal, AppSpacing.lg)

                if showValidation {
                    Text("Micro-habit should be at least 3 characters.")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.warning)
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.top, AppSpacing.xs)
                }

                Spacer()
                    .frame(minHeight: AppSpacing.xxxl)
            }
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(
                title: LocalizedStrings.lockThisIn,
                isEnabled: isValid
            ) {
                isInputFocused = false
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
        DefineMicrohabitView(onContinue: {})
            .environment({
                let state = AppState()
                state.onboardingGoal.title = "Get healthier"
                return state
            }())
    }
}
