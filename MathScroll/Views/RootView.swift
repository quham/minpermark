import SwiftUI
import SwiftData

// MARK: - Root View

/// Root view that handles authentication state and routes to appropriate screens
struct RootView: View {
    @Environment(AppState.self) var appState
    @Query private var goals: [Goal]

    var body: some View {
        Group {
            if SupabaseManager.shared.isLoading {
                // Show splash while checking auth state
                SplashView()
            } else if !SupabaseManager.shared.isAuthenticated {
                // Not authenticated - show auth flow
                AuthContainerView()
            } else if !appState.hasCompletedOnboarding || goals.isEmpty {
                // Authenticated but needs onboarding
                OnboardingContainerView()
            } else {
                // Fully authenticated and onboarded
                HomeView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: SupabaseManager.shared.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: SupabaseManager.shared.isLoading)
        .animation(.easeInOut(duration: 0.3), value: appState.hasCompletedOnboarding)
    }
}

// MARK: - Splash View

/// Simple splash screen shown while checking authentication
struct SplashView: View {
    var body: some View {
        ZStack {
            GradientBackgroundView()

            VStack(spacing: AppSpacing.lg) {
                Image(systemName: "target")
                    .font(.system(size: 72, weight: .light))
                    .foregroundColor(AppColors.primary)

                Text(Constants.App.name)
                    .font(AppTypography.largeTitle)
                    .foregroundColor(AppColors.textPrimary)

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                    .scaleEffect(1.2)
                    .padding(.top, AppSpacing.lg)
            }
        }
    }
}

#Preview("Splash") {
    SplashView()
}

#Preview("Root - Authenticated") {
    RootView()
        .environment(AppState())
        .environment(VerificationStore())
        .modelContainer(for: [Goal.self, CompletionRecord.self, ProofItem.self, UserStats.self], inMemory: true)
}
