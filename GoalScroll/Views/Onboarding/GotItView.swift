import SwiftUI

struct GotItView: View {
    let onStart: () -> Void
    let onAddGoal: () -> Void

    var body: some View {
        ZStack {
            GradientBackgroundView()

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: AppSpacing.xl)

                VStack(spacing: AppSpacing.sm) {
                    Text("Got it.")
                        .font(AppTypography.largeTitle)
                        .foregroundColor(AppColors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("We've made a plan. Now it's time to execute.")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, AppSpacing.lg)

                Spacer()
                    .frame(height: AppSpacing.xl)

                Spacer()
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: AppSpacing.sm) {
                PrimaryButton(title: "Start Day One") {
                    onStart()
                }
                .frame(maxWidth: .infinity)

                SecondaryButton(title: "Add another goal") {
                    onAddGoal()
                }
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
    }
}

#Preview {
    GotItView(onStart: {}, onAddGoal: {})
        .background(GradientBackgroundView())
}
