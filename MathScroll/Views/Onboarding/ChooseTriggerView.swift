import SwiftUI

struct ChooseTriggerView: View {
    @Environment(AppState.self) var appState
    let onContinue: () -> Void

    @FocusState private var isInputFocused: Bool

    private var isValid: Bool {
        appState.onboardingGoal.isTriggerValid
    }

    private var showValidation: Bool {
        switch appState.onboardingGoal.triggerType {
        case .time:
            return false
        case .after, .location:
            return !appState.onboardingGoal.triggerValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isValid
        }
    }

    var body: some View {
        @Bindable var appState = appState
        ScrollView {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: AppSpacing.xl)

                // Title section
                VStack(spacing: AppSpacing.sm) {
                    Text(LocalizedStrings.triggerTitle)
                        .font(AppTypography.title)
                        .foregroundColor(AppColors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(LocalizedStrings.triggerSubtitle)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, AppSpacing.lg)

                Spacer()
                    .frame(height: AppSpacing.xl)

                // Trigger options
                VStack(spacing: AppSpacing.sm) {
                    // Time-based trigger
                    TriggerOptionCard(
                        title: "At a specific time",
                        icon: "clock.fill",
                        isSelected: appState.onboardingGoal.triggerType == .time,
                        onSelect: {
                            withAnimation {
                                appState.onboardingGoal.triggerType = .time
                            }
                        }
                    ) {
                        DatePicker(
                            "",
                            selection: $appState.onboardingGoal.triggerTime,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .environment(\.colorScheme, .light)
                        .frame(height: 120)
                    }

                    // After trigger
                    TriggerOptionCard(
                        title: "After I...",
                        icon: "arrow.right.circle.fill",
                        isSelected: appState.onboardingGoal.triggerType == .after,
                        onSelect: {
                            withAnimation {
                                appState.onboardingGoal.triggerType = .after
                                isInputFocused = true
                            }
                        }
                    ) {
                        ZStack(alignment: .leading) {
                            if appState.onboardingGoal.triggerValue.isEmpty {
                                Text("e.g., wake up, eat breakfast, brush teeth")
                                    .font(AppTypography.body)
                                    .foregroundColor(AppColors.textMuted)
                            }

                            TextField("", text: $appState.onboardingGoal.triggerValue)
                                .font(AppTypography.body)
                                .focused($isInputFocused)
                        }
                        .padding(AppSpacing.sm)
                        .background(AppColors.inputBackground)
                        .cornerRadius(AppCornerRadius.small)
                    }

                    // Location trigger
                    TriggerOptionCard(
                        title: "When I get to...",
                        icon: "mappin.circle.fill",
                        isSelected: appState.onboardingGoal.triggerType == .location,
                        onSelect: {
                            withAnimation {
                                appState.onboardingGoal.triggerType = .location
                                isInputFocused = true
                            }
                        }
                    ) {
                        ZStack(alignment: .leading) {
                            if appState.onboardingGoal.triggerValue.isEmpty {
                                Text("e.g., the gym, work, home")
                                    .font(AppTypography.body)
                                    .foregroundColor(AppColors.textMuted)
                            }

                            TextField("", text: $appState.onboardingGoal.triggerValue)
                                .font(AppTypography.body)
                                .focused($isInputFocused)
                        }
                        .padding(AppSpacing.sm)
                        .background(AppColors.inputBackground)
                        .cornerRadius(AppCornerRadius.small)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)

                if showValidation {
                    Text("Give this trigger a little more detail.")
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
                title: LocalizedStrings.soundsRight,
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
    }
}

struct TriggerOptionCard<Content: View>: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let onSelect: () -> Void
    @ViewBuilder let expandedContent: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: onSelect) {
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? AppColors.primary : AppColors.textSecondary)
                        .frame(width: 28)

                    Text(title)
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)

                    Spacer()

                    Circle()
                        .strokeBorder(isSelected ? AppColors.primary : AppColors.inputBorder, lineWidth: 2)
                        .background(
                            Circle()
                                .fill(isSelected ? AppColors.primary : Color.clear)
                                .padding(4)
                        )
                        .frame(width: 24, height: 24)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .opacity(isSelected ? 1 : 0)
                        )
                }
                .padding(AppSpacing.md)
            }
            .buttonStyle(.plain)

            // Expanded content
            if isSelected {
                expandedContent()
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, AppSpacing.md)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
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
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    ZStack {
        GradientBackgroundView()
        ChooseTriggerView(onContinue: {})
            .environment(AppState())
    }
}
