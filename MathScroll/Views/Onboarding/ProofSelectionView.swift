import SwiftUI

struct ProofSelectionView: View {
    @Environment(AppState.self) var appState
    let onContinue: () -> Void

    private var isValid: Bool {
        !appState.onboardingGoal.proofMethods.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: AppSpacing.xl)

                // Title section
                VStack(spacing: AppSpacing.sm) {
                    Text(LocalizedStrings.proofTitle)
                        .font(AppTypography.title)
                        .foregroundColor(AppColors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(LocalizedStrings.proofSubtitle)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, AppSpacing.lg)

                Spacer()
                    .frame(height: AppSpacing.xl)

                // Proof options (multi-select)
                VStack(spacing: AppSpacing.sm) {
                    ForEach(ProofMethod.allCases) { method in
                        let isEnabled = method != .friendVouch || Constants.Features.friendVouchEnabled
                        ProofOptionCard(
                            method: method,
                            isSelected: isEnabled && appState.onboardingGoal.proofMethods.contains(method),
                            isEnabled: isEnabled,
                            onToggle: {
                                withAnimation {
                                    if appState.onboardingGoal.proofMethods.contains(method) {
                                        appState.onboardingGoal.proofMethods.remove(method)
                                    } else {
                                        appState.onboardingGoal.proofMethods.insert(method)
                                    }
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, AppSpacing.lg)

                Spacer()
                    .frame(height: AppSpacing.lg)

                // Validation message
                if !isValid {
                    Text("Select at least one proof method")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.warning)
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.bottom, AppSpacing.xs)
                }

                // Privacy note
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                    Text(LocalizedStrings.privacyNote)
                        .font(AppTypography.caption)
                }
                .foregroundColor(AppColors.textMuted)
                .padding(.horizontal, AppSpacing.lg)

                Spacer()
                    .frame(minHeight: AppSpacing.xxxl)
            }
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(
                title: "Continue",
                isEnabled: isValid
            ) {
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
    }
}

struct ProofOptionCard: View {
    let method: ProofMethod
    let isSelected: Bool
    let isEnabled: Bool
    let onToggle: () -> Void
    private var isRecommended: Bool { method == .camera }
    private var isComingSoon: Bool { !isEnabled }
    private var badgeText: String? {
        if isComingSoon {
            return "Coming soon"
        }
        return isRecommended ? "Recommended" : nil
    }
    private var badgeForegroundColor: Color {
        isComingSoon ? AppColors.textMuted : AppColors.primary
    }
    private var badgeBackgroundColor: Color {
        isComingSoon ? AppColors.inputBackground : AppColors.primary.opacity(0.12)
    }

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: AppSpacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? AppColors.primary.opacity(0.15) : AppColors.inputBackground)
                        .frame(width: 44, height: 44)

                    Image(systemName: method.icon)
                        .font(.system(size: 18))
                        .foregroundColor(
                            isEnabled
                                ? (isSelected ? AppColors.primary : AppColors.textSecondary)
                                : AppColors.textMuted
                        )
                }

                // Text
                VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                    Text(method.displayTitle)
                        .font(AppTypography.headline)
                        .foregroundColor(isEnabled ? AppColors.textPrimary : AppColors.textMuted)

                    Text(method.description)
                        .font(AppTypography.caption)
                        .foregroundColor(isEnabled ? AppColors.textSecondary : AppColors.textMuted)
                }

                Spacer()

                if let badgeText = badgeText {
                    Text(badgeText)
                        .font(AppTypography.caption)
                        .foregroundColor(badgeForegroundColor)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xs)
                        .background(
                            Capsule()
                                .fill(badgeBackgroundColor)
                        )
                }

                // Checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(
                            isSelected ? AppColors.primary : AppColors.inputBorder,
                            lineWidth: 2
                        )
                        .frame(width: 24, height: 24)

                    if isSelected {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppColors.primary)
                            .frame(width: 18, height: 18)

                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .fill(isSelected ? AppColors.primary.opacity(0.05) : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .strokeBorder(
                        isSelected ? AppColors.primary : AppColors.inputBorder,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .disabled(!isEnabled)
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    ZStack {
        GradientBackgroundView()
        ProofSelectionView(onContinue: {})
            .environment(AppState())
    }
}
