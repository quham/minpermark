import SwiftUI

struct SummaryView: View {
    enum ActionStyle {
        case holdToStart
        case primaryButton
    }

    @Environment(AppState.self) var appState
    let onStart: () -> Void
    var actionStyle: ActionStyle = .holdToStart
    var actionTitle: String = "Hold to start Day One"
    var actionNote: String? = "Hold for a second to commit"

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: AppSpacing.xl)

                // Title section
                VStack(spacing: AppSpacing.sm) {
                    Text(LocalizedStrings.summaryTitle)
                        .font(AppTypography.title)
                        .foregroundColor(AppColors.textPrimary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, AppSpacing.lg)

                Spacer()
                    .frame(height: AppSpacing.xl)

                // Commitment card
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    SummaryLine(
                        emoji: "🧱",
                        content: Text("I commit to ") + Text(appState.onboardingGoal.microHabit).bold()
                    )

                    SummaryLine(
                        emoji: anchorEmoji,
                        content: Text(anchorText).bold()
                    )

                    SummaryLine(
                        emoji: "📈",
                        content: Text("and will track my progress via ") + Text("\(proofText).").bold()
                    )

                    SummaryLine(
                        emoji: "🎯",
                        content: Text("I will ") + Text(appState.onboardingGoal.title).bold()
                    )

                    SummaryLine(
                        emoji: "❤️",
                        content: Text("because ") + Text(whyText).bold()
                    )
                }
                .font(AppTypography.title2)
                .foregroundColor(AppColors.textPrimary)
                .padding(AppSpacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: AppCornerRadius.large)
                        .fill(Color.white)
                        .shadow(color: AppColors.shadowColor, radius: 12, x: 0, y: 4)
                )
                .padding(.horizontal, AppSpacing.lg)

                Spacer()
                    .frame(height: AppSpacing.md)

                Text(LocalizedStrings.summarySubtitle)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.lg)

                Spacer()
                    .frame(minHeight: AppSpacing.xxxl)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: AppSpacing.xs) {
                switch actionStyle {
                case .holdToStart:
                    HoldToStartButton(title: actionTitle) {
                        onStart()
                    }
                    .frame(maxWidth: .infinity)
                case .primaryButton:
                    PrimaryButton(title: actionTitle) {
                        onStart()
                    }
                    .frame(maxWidth: .infinity)
                }

                if let actionNote {
                    Text(actionNote)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textMuted)
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

    private var anchorText: String {
        switch appState.onboardingGoal.triggerType {
        case .time:
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "At \(formatter.string(from: appState.onboardingGoal.triggerTime))"
        case .after:
            return "After \(appState.onboardingGoal.triggerValue)"
        case .location:
            return "When I get to \(appState.onboardingGoal.triggerValue)"
        }
    }

    private var anchorEmoji: String {
        switch appState.onboardingGoal.triggerType {
        case .time:
            return "⏰"
        case .after:
            return "➡️"
        case .location:
            return "📍"
        }
    }

    private var proofText: String {
        if appState.onboardingGoal.proofMethods.isEmpty {
            return "no proof"
        }
        return appState.onboardingGoal.proofMethods
            .map { $0.displayTitle }
            .joined(separator: ", ")
    }

    private var whyText: String {
        if !appState.onboardingGoal.why.isEmpty {
            return appState.onboardingGoal.why
        }
        return "it matters \(appState.onboardingGoal.importance)/10"
    }
}

struct SummaryLine: View {
    let emoji: String
    let content: Text

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Text(emoji)
                .font(.system(size: 18))
                .frame(width: 24, alignment: .center)

            content
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)
        }
    }
}

#Preview {
    ZStack {
        GradientBackgroundView()
        SummaryView(onStart: {})
            .environment({
                let state = AppState()
                state.onboardingGoal.title = "Get healthier"
                state.onboardingGoal.microHabit = "Do 10 pushups"
                state.onboardingGoal.triggerType = .time
                state.onboardingGoal.importance = 8
                state.onboardingGoal.proofMethods = [.camera, .reflection]
                state.onboardingGoal.why = "I want to feel more energetic and confident in my body."
                return state
            }())
    }
}
