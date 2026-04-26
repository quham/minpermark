import SwiftUI

struct GoalCardView: View {
    let goal: Goal
    var onComplete: () -> Void

    @State private var isAnimating = false

    var body: some View {
        HStack(alignment: .center, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                // Microhabit title
                Text(goal.microHabit)
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
                    .strikethrough(goal.todaysCompletionStatus == .passed, color: AppColors.textMuted)
                    .opacity(goal.todaysCompletionStatus == .passed ? 0.6 : 1)

                // Trigger info
                HStack(spacing: AppSpacing.xxs) {
                    Image(systemName: triggerIcon)
                        .font(.system(size: 12))
                    Text(goal.triggerDisplayText)
                        .font(AppTypography.caption)
                }
                .foregroundColor(AppColors.textMuted)
            }

            Spacer()

            // Action button
            if goal.isCompletedToday {
                verificationStateButton
            } else {
                actionButton
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.large)
                .fill(Color.white)
                .shadow(color: AppColors.shadowColor, radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.large)
                .strokeBorder(
                    borderColor,
                    lineWidth: 2
                )
        )
        .scaleEffect(isAnimating ? 0.98 : 1.0)
    }

    private var triggerIcon: String {
        switch goal.triggerType {
        case .time: return "clock"
        case .after: return "arrow.right"
        case .location: return "mappin"
        }
    }

    private var borderColor: Color {
        guard goal.isCompletedToday else { return Color.clear }

        let status = goal.todaysCompletionStatus ?? .passed
        switch status {
        case .pending, .uncertain:
            return AppColors.warning.opacity(0.3)
        case .passed:
            return AppColors.success.opacity(0.3)
        case .failed:
            return AppColors.error.opacity(0.3)
        }
    }

    private var actionButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isAnimating = true
            }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(100))
                withAnimation {
                    isAnimating = false
                }
                onComplete()
            }
        }) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 16, weight: .medium))
                Text("Check in")
                    .font(AppTypography.callout.weight(.medium))
            }
            .foregroundColor(AppColors.primary)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(
                Capsule()
                    .fill(AppColors.primary.opacity(0.1))
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    @ViewBuilder
    private var verificationStateButton: some View {
        let status = goal.todaysCompletionStatus ?? .passed

        switch status {
        case .pending:
            // Bouncing orange dots while verifying
            BouncingDotsView()
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(
                    Capsule()
                        .fill(AppColors.warning.opacity(0.1))
                )

        case .passed:
            // Green "Done" indicator
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                Text("Done")
                    .font(AppTypography.callout.weight(.medium))
            }
            .foregroundColor(AppColors.success)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(
                Capsule()
                    .fill(AppColors.success.opacity(0.1))
            )

        case .failed:
            // Red "Try again" button - tappable
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isAnimating = true
                }
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(100))
                    withAnimation {
                        isAnimating = false
                    }
                    onComplete()
                }
            }) {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 16, weight: .medium))
                    Text("Try again")
                        .font(AppTypography.callout.weight(.medium))
                }
                .foregroundColor(AppColors.error)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(
                    Capsule()
                        .fill(AppColors.error.opacity(0.1))
                )
            }
            .buttonStyle(ScaleButtonStyle())

        case .uncertain:
            // Orange "Under review" indicator
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "clock")
                    .font(.system(size: 16, weight: .medium))
                Text("Under review")
                    .font(AppTypography.callout.weight(.medium))
            }
            .foregroundColor(AppColors.warning)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(
                Capsule()
                    .fill(AppColors.warning.opacity(0.1))
            )
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        GoalCardView(
            goal: Goal(
                title: "Get healthier",
                microHabit: "Do 10 pushups",
                triggerType: .time,
                triggerValue: "7:00 AM"
            )
        ) {
            print("Completed")
        }

        GoalCardView(
            goal: {
                let goal = Goal(
                    title: "Learn Spanish",
                    microHabit: "Practice Duolingo for 5 minutes",
                    triggerType: .after,
                    triggerValue: "breakfast"
                )
                goal.lastCompletedAt = Date()
                return goal
            }()
        ) {
            print("Completed")
        }
    }
    .padding()
    .background(GradientBackgroundView())
}
