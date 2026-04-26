import SwiftUI
import SwiftData

#if canImport(FamilyControls)
import FamilyControls
#endif

struct FirstRunSetupView: View {
    enum Step: Int, CaseIterable {
        case notifications
        case screenTime
        case selection
        case limits

        var title: String {
            switch self {
            case .notifications:
                return "Stay on track"
            case .screenTime:
                return "Enable Screen Time"
            case .selection:
                return "Choose apps to block"
            case .limits:
                return "Set your limits"
            }
        }

        var subtitle: String {
            switch self {
            case .notifications:
                return "Turn on reminders so your new habit stays visible."
            case .screenTime:
                return "We use Screen Time to block distracting apps until you earn minutes."
            case .selection:
                return "Pick the apps and categories you want to block."
            case .limits:
                return "Decide how you'll earn your screen time."
            }
        }
    }

    @Environment(AppState.self) var appState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Environment(NotificationManager.self) var notificationManager
    @Environment(ScreenTimeManager.self) var screenTimeManager

    @Query private var allStats: [UserStats]
    private var stats: UserStats? { allStats.first }

    @State private var step: Step = .notifications
    @State private var isRequestingNotifications = false
    @State private var isRequestingScreenTime = false
    @State private var isPickerPresented = false
    @State private var dailyMinutesTarget: Double = Double(Constants.Defaults.dailyMinutesTarget)
    @AppStorage(Constants.UserDefaultsKeys.removeBlockAfterAllGoals, store: UserDefaults(suiteName: Constants.App.groupIdentifier)) private var removeBlockAfterAllGoals = true

    var body: some View {
        @Bindable var screenTimeManager = screenTimeManager
        @Bindable var appState = appState
        NavigationStack {
            ZStack {
                GradientBackgroundView()

                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        VStack(spacing: AppSpacing.xs) {
                            Text(step.title)
                                .font(AppTypography.title)
                                .foregroundColor(AppColors.textPrimary)

                            Text(step.subtitle)
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, AppSpacing.xl)
                        .padding(.horizontal, AppSpacing.lg)

                        stepContent
                            .padding(.horizontal, AppSpacing.lg)

                        Spacer().frame(height: AppSpacing.xxl)
                    }
                }
            }
            .navigationTitle("Start Day One")
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled(true)
        #if canImport(FamilyControls)
        .familyActivityPicker(
            isPresented: $isPickerPresented,
            selection: $screenTimeManager.selectedApps
        )
        #endif
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            notificationManager.checkAuthorizationStatus()
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .notifications:
            notificationsStep
        case .screenTime:
            screenTimeStep
        case .selection:
            selectionStep
        case .limits:
            limitsStep
        }
    }

    private var notificationsStep: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 56))
                .foregroundColor(AppColors.primary)

            Text(notificationManager.isAuthorized
                ? "Notifications are enabled."
                : "You'll get friendly reminders based on your triggers.")
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            PrimaryButton(
                title: notificationManager.isAuthorized ? "Continue" : (notificationManager.isDenied ? "Continue anyway" : "Enable notifications"),
                isLoading: isRequestingNotifications
            ) {
                handleNotificationsContinue()
            }
            .frame(height: 56)
        }
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.large)
                .fill(Color.white)
                .shadow(color: AppColors.shadowColor, radius: 10, x: 0, y: 4)
        )
    }

    private var screenTimeStep: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "hourglass.circle.fill")
                .font(.system(size: 56))
                .foregroundColor(AppColors.primary)

            Text(screenTimeStatusText)
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            PrimaryButton(
                title: screenTimeButtonTitle,
                isEnabled: true,
                isLoading: isRequestingScreenTime
            ) {
                handleScreenTimeContinue()
            }
            .frame(height: 56)

            if !screenTimeManager.isAvailable {
                Text("Screen Time isn’t available on this device, so onboarding can’t finish here.")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textMuted)
                    .multilineTextAlignment(.center)
            } else if !screenTimeManager.isAuthorized {
                Text("Screen Time permission is required to finish onboarding.")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textMuted)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.large)
                .fill(Color.white)
                .shadow(color: AppColors.shadowColor, radius: 10, x: 0, y: 4)
        )
    }

    private var selectionStep: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 56))
                .foregroundColor(AppColors.primary)

            if screenTimeManager.isAvailable {
                if screenTimeManager.hasSelection {
                    #if canImport(FamilyControls)
                    SelectionSummaryCard(
                        appCount: screenTimeManager.selectedAppCount,
                        categoryCount: screenTimeManager.selectedCategoryCount
                    )
                    #endif
                }

                Button(action: { isPickerPresented = true }) {
                    HStack {
                        Image(systemName: "apps.iphone")
                            .font(.system(size: 20))
                        Text(screenTimeManager.hasSelection ? "Change selection" : "Select apps & categories")
                            .font(AppTypography.headline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(AppColors.primary)
                    .padding(AppSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                            .fill(AppColors.primary.opacity(0.1))
                    )
                }

                if !screenTimeManager.isAuthorized {
                    Text("Screen Time access is required to finish onboarding.")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textMuted)
                        .multilineTextAlignment(.center)
                } else if !screenTimeManager.hasSelection {
                    Text("Pick at least one app or category to enable blocking.")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textMuted)
                        .multilineTextAlignment(.center)
                }
            } else {
                Text("Screen Time isn’t available on this device, so onboarding can’t finish here.")
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            PrimaryButton(
                title: "Continue",
                isEnabled: canGoToLimits
            ) {
                goToNextStep()
            }
            .frame(height: 56)
        }
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.large)
                .fill(Color.white)
                .shadow(color: AppColors.shadowColor, radius: 10, x: 0, y: 4)
        )
    }

    private var limitsStep: some View {
        VStack(spacing: AppSpacing.lg) {
            VStack(alignment: .center, spacing: AppSpacing.md) {
                Text("Daily Break Budget")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)

                Picker("Maximum Minutes", selection: $dailyMinutesTarget) {
                    ForEach(Array(stride(from: 10, through: 240, by: 10)), id: \.self) { minutes in
                        Text("\(minutes) min").tag(Double(minutes))
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 120)
                .environment(\.colorScheme, .light)

                Text("Minutes earned will be split between each goal.")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.md)
            }
            .padding(.vertical, AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .fill(AppColors.primary.opacity(0.05))
            )

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Toggle(isOn: $removeBlockAfterAllGoals) {
                    Text("Done for the Day")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                }
                .tint(AppColors.primary)

                Text(removeBlockAfterAllGoals ? "When every goal is completed all apps are unlocked." : "Only unlock apps using minutes that are earned from break budget.")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(AppSpacing.md)

            PrimaryButton(
                title: "Finish",
                isEnabled: true
            ) {
                finishSetup()
            }
            .frame(height: 56)
        }
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.large)
                .fill(Color.white)
                .shadow(color: AppColors.shadowColor, radius: 10, x: 0, y: 4)
        )
    }

    private var screenTimeStatusText: String {
        if !screenTimeManager.isAvailable {
            return "Screen Time isn’t available on this device."
        }
        return screenTimeManager.isAuthorized
            ? "Screen Time is enabled."
            : "We’ll ask for permission to manage your app blocking."
    }

    private var screenTimeButtonTitle: String {
        if !screenTimeManager.isAvailable {
            return "Continue"
        }
        return screenTimeManager.isAuthorized ? "Continue" : "Enable Screen Time"
    }

    private var canGoToLimits: Bool {
        screenTimeManager.isAvailable
            && screenTimeManager.isAuthorized
            && screenTimeManager.hasSelection
    }

    private func handleNotificationsContinue() {
        if notificationManager.isAuthorized || notificationManager.isDenied {
            goToNextStep()
            return
        }

        Task {
            isRequestingNotifications = true
            let granted = await notificationManager.requestAuthorization()
            notificationManager.setupNotificationCategories()
            isRequestingNotifications = false
            
            // Go to next step regardless of whether they granted or denied
            // since we only ask once.
            goToNextStep()
            
            if !granted {
                notificationManager.checkAuthorizationStatus()
            }
        }
    }

    private func handleScreenTimeContinue() {
        guard screenTimeManager.isAvailable else {
            goToNextStep()
            return
        }

        if screenTimeManager.isAuthorized {
            goToNextStep()
            return
        }

        Task {
            isRequestingScreenTime = true
            let granted = await screenTimeManager.requestAuthorization()
            isRequestingScreenTime = false
            if granted {
                goToNextStep()
            }
        }
    }

    private func goToNextStep() {
        withAnimation {
            if let next = Step(rawValue: step.rawValue + 1) {
                step = next
            }
        }
    }

    private func finishSetup() {
        guard canGoToLimits else { return }
        
        if let stats = stats {
            stats.dailyMinutesTarget = Int(dailyMinutesTarget)
        } else {
            let newStats = UserStats(dailyMinutesTarget: Int(dailyMinutesTarget))
            modelContext.insert(newStats)
        }
        
        try? modelContext.save()

        if screenTimeManager.isAuthorized && screenTimeManager.hasSelection {
            screenTimeManager.enableBlocking()
        }
        appState.hasCompletedFirstRunSetup = true
        appState.completeOnboarding()
        appState.shouldShowStartNowPrompt = false
        dismiss()
    }
}

#Preview {
    FirstRunSetupView()
        .environment(AppState())
        .environment(VerificationStore())
        .environment(NotificationManager.shared)
        .environment(ScreenTimeManager.shared)
}
