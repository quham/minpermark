import SwiftUI

struct GoalTransitionView: View {
    let onContinue: () -> Void
    @Environment(AppState.self) var appState

    @State private var shapeScale: CGFloat = 1.0
    @State private var apiCompleted = false
    @State private var minimumTimePassed = false

    private let geminiService: any GeminiServiceProtocol = GeminiService()
    private let minimumDuration: Double = 3.0
    private let maximumDuration: Double = 5.0

    var body: some View {
        VStack(spacing: AppSpacing.xxl) {
            Spacer()

            // Animated shape
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [AppColors.primaryLight, AppColors.primary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
                .scaleEffect(shapeScale)
                .shadow(color: AppColors.primary.opacity(0.3), radius: 20, x: 0, y: 10)

            // Copy text
            VStack(spacing: AppSpacing.sm) {
                Text("Big goals start with small steps.")
                    .font(AppTypography.title)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Something you can do, even on hard days.")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, AppSpacing.xl)

            Spacer()

            // Continue button shows only after API completion or timeout
            VStack {
                if apiCompleted && minimumTimePassed {
                    PrimaryButton(title: "Continue") {
                        proceedToNextStep()
                    }
                    .transition(.opacity.combined(with: .offset(y: 20)))
                }
            }
            .animation(.easeOut(duration: 0.6), value: apiCompleted && minimumTimePassed)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xxl)
        }
        .onAppear {
            // Reset state and start transition when view appears
            apiCompleted = false
            minimumTimePassed = false
            shapeScale = 1.0
            startTransition()
        }
    }

    private func startTransition() {
        let goalTitle = appState.onboardingGoal.title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If the goal title has changed since the last API submission, clear the cache
        if goalTitle != appState.lastSubmittedGoalTitle {
            appState.cachedMicrohabitSuggestions = []
            appState.lastSubmittedGoalTitle = goalTitle
        }

        // If suggestions are already cached, proceed faster
        let hasCachedSuggestions = !appState.cachedMicrohabitSuggestions.isEmpty
        
        // Start shape animation
        withAnimation(.easeInOut(duration: maximumDuration)) {
            shapeScale = 0.6
        }

        if hasCachedSuggestions {
            // If we already have suggestions, show the next button after a short delay
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(0.8 * 1_000_000_000))
                withAnimation(.easeIn(duration: 0.5)) {
                    apiCompleted = true
                    minimumTimePassed = true
                }
            }
        } else {
            // Start API call only if we don't have cached suggestions
            Task {
                await fetchSuggestions()
            }

            // Minimum time timer
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(minimumDuration * 1_000_000_000))
                withAnimation(.easeIn(duration: 0.5)) {
                    minimumTimePassed = true
                }
            }

            // Maximum time timer (fallback)
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(maximumDuration * 1_000_000_000))
                if !apiCompleted {
                    withAnimation(.easeIn(duration: 0.5)) {
                        apiCompleted = true
                        minimumTimePassed = true
                    }
                }
            }
        }
    }

    @MainActor
    private func fetchSuggestions() async {
        let goalTitle = appState.onboardingGoal.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard goalTitle.count >= 3 else {
            apiCompleted = true
            return
        }

        do {
            let suggestions = try await geminiService.suggestMicroHabits(goalTitle: goalTitle)
            // Only update if we got valid suggestions
            if !suggestions.isEmpty {
                appState.cachedMicrohabitSuggestions = suggestions
                AnalyticsService.shared.capture(Constants.AnalyticsEvents.microHabitSuggestionFetched, properties: ["suggestion_count": suggestions.count])
            }
            withAnimation(.easeIn(duration: 0.5)) {
                apiCompleted = true
            }
        } catch {
            // If it fails or times out, we don't set apiCompleted = true.
            // This ensures we wait for the 5-second maximumDuration fallback timer
            // to show the button, instead of jumping there immediately on error.
            print("Suggestions fetch failed or timed out: \(error)")
        }
    }

    private func proceedToNextStep() {
        onContinue()
    }
}

#Preview {
    ZStack {
        GradientBackgroundView()
        GoalTransitionView(onContinue: {})
            .environment({
                let state = AppState()
                state.onboardingGoal.title = "Get healthier"
                return state
            }())
    }
}
