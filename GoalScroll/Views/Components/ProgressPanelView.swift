import SwiftUI

struct ProgressPanelView: View {
    let todayMinutes: Int
    let targetMinutes: Int
    let completedGoals: Int
    let totalGoals: Int

    private var progress: Double {
        guard totalGoals > 0 else { return 0 }
        let value = Double(completedGoals) / Double(totalGoals)
        guard value.isFinite else { return 0 }
        return min(max(value, 0), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header
            HStack {
                Text("Today's Progress")
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.textPrimary)

                Spacer()

                Text("\(completedGoals) / \(totalGoals) goals")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.primary)
            }

            // Progress bar
            GeometryReader { geometry in
                let width = geometry.size.width.isFinite ? geometry.size.width : 0
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(AppColors.inputBackground)
                        .frame(height: 8)

                    // Progress fill
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [AppColors.primary, AppColors.primaryLight],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: width * progress, height: 8)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progress)
                }
            }
            .frame(height: 8)

            // Supporting text
            Text("You've completed \(completedGoals) of \(totalGoals) goals today.")
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.large)
                .fill(Color.white)
                .shadow(color: AppColors.shadowColor, radius: 8, x: 0, y: 2)
        )
    }
}

struct MinutesDisplayView: View {
    let minutes: Int
    let label: String
    var isHighlighted: Bool = false

    var body: some View {
        VStack(spacing: AppSpacing.xxs) {
            Text("\(minutes)")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(isHighlighted ? AppColors.primary : AppColors.textPrimary)

            Text(label)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    VStack(spacing: 20) {
        ProgressPanelView(
            todayMinutes: 32,
            targetMinutes: 40,
            completedGoals: 2,
            totalGoals: 4
        )

        HStack {
            MinutesDisplayView(minutes: 32, label: "Today", isHighlighted: true)
            MinutesDisplayView(minutes: 1240, label: "Lifetime")
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.large)
                .fill(Color.white)
                .shadow(color: AppColors.shadowColor, radius: 8, x: 0, y: 2)
        )
    }
    .padding()
    .background(GradientBackgroundView())
}
