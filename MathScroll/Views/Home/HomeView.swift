import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(AppState.self) var appState
    @Environment(VerificationStore.self) var verificationStore
    @Environment(NotificationManager.self) var notificationManager
    @AppStorage(Constants.UserDefaultsKeys.saveHabitLogs) private var saveHabitLogs = true

    @Query(
        filter: #Predicate<Goal> { !$0.isArchived },
        sort: [
            SortDescriptor(\Goal.importance, order: .reverse),
            SortDescriptor(\Goal.createdAt, order: .reverse)
        ]
    )
    private var goals: [Goal]

    @Query private var allStats: [UserStats]

    @AppStorage(Constants.UserDefaultsKeys.weeklyReviewDay) private var weeklyReviewDay = 1 // Sunday
    @AppStorage(Constants.UserDefaultsKeys.weeklyReviewTime) private var weeklyReviewTime: Double = 19 * 3600 // 7 PM

    @State private var selectedGoalForProof: Goal?
    @State private var showingUnlockSheet = false
    @State private var showingSettings = false
    @State private var showingAddGoal = false
    @State private var showingFirstRunSetup = false
    @State private var showingWeeklyReview = false

    private var stats: UserStats? {
        allStats.first
    }

    private var isWeeklyReviewDue: Bool {
        CalendarUtils.isWeeklyReviewDue(
            weeklyReviewDay: weeklyReviewDay,
            weeklyReviewTime: weeklyReviewTime,
            lastReviewDate: stats?.lastWeeklyReviewDate
        )
    }

    private var completedGoalsCount: Int {
        goals.filter { $0.todaysCompletionStatus == .passed }.count
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let baseGreeting: String
        switch hour {
        case 0..<12:
            baseGreeting = "Good morning"
        case 12..<17:
            baseGreeting = "Good afternoon"
        default:
            baseGreeting = "Good evening"
        }

        let trimmedName = appState.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            return baseGreeting
        }
        return "\(baseGreeting), \(trimmedName)"
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }

    /// Performs all initialization tasks when the home view appears.
    /// This consolidates lifecycle setup into a single entry point.
    private func initializeHomeView() {
        resetStatsForNewDayIfNeeded()
        updateDailyRewardsIfNeeded()
        updateBlockingStatus()
        NotificationManager.shared.scheduleWeeklyReviewNotification()
        scheduleGoalReminders()
        // Check if unlock has expired and re-enable blocking if needed
        ScreenTimeManager.shared.checkUnlockStatus()
        // Process any pending minute deduction from a break that ended while app was closed
        processPendingMinuteDeduction()
    }

    private func scheduleGoalReminders() {
        for goal in goals {
            NotificationManager.shared.scheduleGoalReminder(for: goal)
        }
    }

    var body: some View {
        ZStack {
            GradientBackgroundView()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // Header
                        headerSection

                        // Progress panel
                        ProgressPanelView(
                            todayMinutes: stats?.todayMinutesEarned ?? 0,
                            targetMinutes: stats?.dailyMinutesTarget ?? 40,
                            completedGoals: completedGoalsCount,
                            totalGoals: goals.count
                        )
                        .padding(.horizontal, AppSpacing.lg)

                        if isWeeklyReviewDue {
                            weeklyReviewCard
                        }

                        // Goals list
                        goalsSection

                        Spacer()
                            .frame(height: AppSpacing.xxl)
                    }
                    .padding(.top, AppSpacing.md)
                }

                unlockSection
            }
        }
        .sheet(item: $selectedGoalForProof) { goal in
            ProofCaptureView(goal: goal) { proofs in
                completeGoalWithProof(goal, proofs: proofs)
            }
        }
        .sheet(isPresented: $showingUnlockSheet) {
            UnlockTimerView(
                availableMinutes: stats?.todayMinutesEarned ?? 0,
                onDismiss: { showingUnlockSheet = false },
                onDeductMinutes: { minutes in
                    stats?.deductMinutes(minutes)
                    modelContext.safeSave()
                }
            )
            .presentationDetents([.large])
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingAddGoal) {
            AddGoalView()
        }
        .sheet(isPresented: $showingWeeklyReview) {
            WeeklyReviewView()
        }
        .fullScreenCover(isPresented: $showingFirstRunSetup) {
            FirstRunSetupView()
        }
        .onAppear {
            initializeHomeView()
        }
        .onChange(of: notificationManager.isAuthorized) { _, newValue in
            if newValue {
                scheduleGoalReminders()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                resetStatsForNewDayIfNeeded()
                ScreenTimeManager.shared.checkUnlockStatus()
                processPendingMinuteDeduction()
            }
        }
        .onChange(of: stats?.dailyMinutesTarget ?? 0) { _, _ in
            updateDailyRewardsIfNeeded()
        }
        .onChange(of: goals.map { $0.id }) { _, _ in
            updateDailyRewardsIfNeeded()
            scheduleGoalReminders()
            updateBlockingStatus()
        }
        .onChange(of: goals.map { $0.importance }) { _, _ in
            updateDailyRewardsIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            resetStatsForNewDayIfNeeded()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(greeting)
                    .font(AppTypography.title)
                    .foregroundColor(AppColors.textPrimary)

                Text(dateString)
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            HStack(spacing: AppSpacing.sm) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.orange)

                    Text("\(stats?.currentStreakDays ?? 0)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                }
                .padding(.horizontal, 10)
                .frame(height: 44)

                ShareLink(item: Constants.App.shareMessage) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 44, height: 44)
                }

                // Settings button
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 44, height: 44)
                }
            }
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    // MARK: - Goals Section

    private var goalsSection: some View {
        return VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Spacer()

                Button(action: { showingAddGoal = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppColors.primary)
                }
            }
            .padding(.horizontal, AppSpacing.lg)

            if goals.isEmpty {
                emptyGoalsState
            } else {
                LazyVStack(spacing: AppSpacing.sm) {
                    ForEach(goals) { goal in
                        GoalCardView(goal: goal) {
                            handleGoalCompletion(goal)
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
            }
        }
    }

    private var weeklyReviewCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Weekly review")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            Text("See which habits you completed each day.")
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.textSecondary)

            PrimaryButton(title: "Review week") {
                showingWeeklyReview = true
            }
            .frame(height: 50)
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .padding(.horizontal, AppSpacing.lg)
    }

    private var emptyGoalsState: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "target")
                .font(.system(size: 48))
                .foregroundColor(AppColors.textMuted)

            Text("No goals yet")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textSecondary)

            Text("Add your first goal to get started")
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.textMuted)

            PrimaryButton(title: "Add Goal") {
                showingAddGoal = true
            }
            .frame(width: 160)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xxl)
        .padding(.horizontal, AppSpacing.lg)
    }

    // MARK: - Unlock Section

    private var unlockSection: some View {
        VStack(spacing: AppSpacing.md) {
            PrimaryButton(
                title: "Unlock apps now",
                isEnabled: (stats?.todayMinutesEarned ?? 0) > 0
            ) {
                showingUnlockSheet = true
            }
            .frame(height: 62)
            .padding(.horizontal, AppSpacing.lg)

            HStack(spacing: AppSpacing.xxs) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 12))
                Text("Minutes available: \(stats?.todayMinutesEarned ?? 0)")
                    .font(AppTypography.caption)
            }
            .foregroundColor(AppColors.textMuted)
        }
        .padding(.vertical, AppSpacing.md)
        .background(
            Rectangle()
                .fill(Color.white.opacity(0.9))
                .shadow(color: AppColors.shadowColor, radius: 8, x: 0, y: -2)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - Stats Summary

    // MARK: - Actions

    private func handleGoalCompletion(_ goal: Goal) {
        // Always require proof capture before completion.
        selectedGoalForProof = goal
    }

    private func completeGoalWithProof(_ goal: Goal, proofs: [ProofItem]) {
        let minutesEarned = goal.dailyMinutesReward

        // Create completion record
        let record = CompletionRecord(
            minutesEarned: minutesEarned,
            verificationStatus: .pending,
            goal: goal
        )
        record.proofs = proofs

        // Update goal
        goal.lastCompletedAt = Date()
        updateStreakIfNeeded()

        if saveHabitLogs {
            // Insert and save
            modelContext.insert(record)
            for proof in proofs {
                modelContext.insert(proof)
            }
            modelContext.safeSave()

            verificationStore.verify(record: record, goal: goal, modelContext: modelContext, stats: stats)
        } else {
            modelContext.safeSave()
        }

        let proofTypes = proofs.map { $0.type.rawValue }
        AnalyticsService.shared.capture(Constants.AnalyticsEvents.proofSubmitted, properties: [
            Constants.AnalyticsProperties.goalId: goal.id.uuidString,
            Constants.AnalyticsProperties.proofMethods: proofTypes,
            "proof_count": proofs.count
        ])
        AnalyticsService.shared.capture(Constants.AnalyticsEvents.goalCompleted, properties: [
            Constants.AnalyticsProperties.goalId: goal.id.uuidString,
            Constants.AnalyticsProperties.minutesReward: minutesEarned,
            Constants.AnalyticsProperties.proofMethods: proofTypes,
            "today_minutes_earned": stats?.todayMinutesEarned ?? 0,
            "current_streak_days": stats?.currentStreakDays ?? 0
        ])

        // Haptic feedback
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)

        selectedGoalForProof = nil
    }

    private func updateStreakIfNeeded() {
        guard let stats, !goals.isEmpty else { return }
        if goals.allSatisfy({ $0.isCompletedToday }) {
            stats.markAllHabitsCompletedForToday()
        }
        updateBlockingStatus()
    }

    private func updateBlockingStatus() {
        guard !goals.isEmpty else { 
            ScreenTimeManager.shared.allGoalsCompleted = false
            return 
        }
        let allDone = goals.allSatisfy({ $0.isCompletedToday })
        ScreenTimeManager.shared.allGoalsCompleted = allDone
    }

    private func updateDailyRewardsIfNeeded() {
        guard let totalMinutes = stats?.dailyMinutesTarget else { return }
        let allocation = GoalRewardAllocator.allocation(for: goals, totalMinutes: totalMinutes)
        let didUpdate = GoalRewardAllocator.applyAllocation(allocation, to: goals)
        if didUpdate {
            modelContext.safeSave()
        }
    }

    private func resetStatsForNewDayIfNeeded() {
        guard let stats else { return }
        let previousResetDate = stats.lastResetDate
        stats.resetForNewDay()
        if stats.lastResetDate != previousResetDate {
            modelContext.safeSave()
        }
    }

    private func processPendingMinuteDeduction() {
        let pending = ScreenTimeManager.shared.getPendingDeduction()
        if pending > 0 {
            stats?.deductMinutes(pending)
            modelContext.safeSave()
            Log.data.info("Processed pending deduction: \(pending) minutes")
        }
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)

                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
            }

            Text(label)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                .fill(Color.white)
                .shadow(color: AppColors.shadowColor, radius: 4, x: 0, y: 2)
        )
    }
}

#Preview {
    HomeView()
        .environment(AppState())
        .environment(VerificationStore())
        .environment(NotificationManager.shared)
        .environment(ScreenTimeManager.shared)
        .modelContainer(for: [Goal.self, CompletionRecord.self, ProofItem.self, UserStats.self], inMemory: true)
}
