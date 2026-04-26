import SwiftUI
import SwiftData

enum WeeklyFeeling: String, CaseIterable, Identifiable {
    case good
    case neutral
    case hard

    var id: String { rawValue }

    var label: String {
        switch self {
        case .good: return "Energizing"
        case .neutral: return "Neutral"
        case .hard: return "Draining"
        }
    }
}

struct WeeklyReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(
        filter: #Predicate<Goal> { !$0.isArchived },
        sort: [
            SortDescriptor(\Goal.importance, order: .reverse),
            SortDescriptor(\Goal.createdAt, order: .reverse)
        ]
    )
    private var goals: [Goal]

    @Query private var allStats: [UserStats]

    private let calendar = Calendar.current
    @State private var feelingsByGoal: [UUID: WeeklyFeeling] = [:]
    @State private var reflectionsByGoal: [UUID: String] = [:]
    @State private var selectedPage = 0
    @State private var selectedGoalForEdit: Goal?
    @State private var showingAddGoal = false
    @State private var showingLimitPicker = false
    @State private var selectedLimitMinutes = Constants.Defaults.dailyMinutesTarget
    @State private var showingAppSelection = false
    @Environment(ScreenTimeManager.self) var screenTimeManager
    @AppStorage(Constants.UserDefaultsKeys.removeBlockAfterAllGoals, store: UserDefaults(suiteName: Constants.App.groupIdentifier)) private var removeBlockAfterAllGoals = true

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackgroundView()

                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    headerSection

                    progressSection

                    TabView(selection: $selectedPage) {
                        ScrollView {
                            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                                weeklyChartCard
                                Spacer(minLength: AppSpacing.xl)
                            }
                            .padding(.horizontal, AppSpacing.lg)
                            .padding(.top, AppSpacing.xs)
                        }
                        .tag(0)

                        ForEach(Array(goals.enumerated()), id: \.element.id) { index, goal in
                            ScrollView {
                                WeeklyGoalReviewView(
                                    goal: goal,
                                    feeling: weeklyFeelingBinding(for: goal),
                                    reflection: reflectionBinding(for: goal)
                                )
                                .padding(.horizontal, AppSpacing.lg)
                                .padding(.top, AppSpacing.xs)
                            }
                            .tag(index + 1)
                        }

                        ScrollView {
                            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                                nextWeekSection
                                Spacer(minLength: AppSpacing.xl)
                            }
                            .padding(.horizontal, AppSpacing.lg)
                            .padding(.top, AppSpacing.xs)
                        }
                        .tag(goals.count + 1)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.lg)
            }
        }
        .sheet(item: $selectedGoalForEdit) { goal in
            GoalEditView(goal: goal) {
                selectedGoalForEdit = nil
            }
        }
        .sheet(isPresented: $showingAddGoal) {
            AddGoalView()
        }
        .sheet(isPresented: $showingAppSelection) {
#if canImport(FamilyControls)
            AppSelectionView()
#else
            Text("App blocking isn't available on this device.")
#endif
        }
        .onAppear {
            selectedLimitMinutes = dailyScreenTimeLimit
            AnalyticsService.shared.capture(Constants.AnalyticsEvents.weeklyReviewOpened, properties: ["goal_count": goals.count])
        }
        .onChange(of: selectedLimitMinutes) { _, newValue in
            guard newValue != dailyScreenTimeLimit else { return }
            updateDailyLimit()
        }
    }

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Weekly review")
                    .font(AppTypography.title)
                    .foregroundColor(AppColors.textPrimary)

                Text(weekRangeText)
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            Button(action: { dismiss() }) {
                Text("Done")
                    .font(AppTypography.callout)
                    .foregroundColor(AppColors.primary)
                    .padding(.vertical, AppSpacing.xxs)
                    .padding(.horizontal, AppSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: AppCornerRadius.full)
                            .fill(Color.white.opacity(0.9))
                    )
            }
        }
    }

    private var weeklyChartCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Habits this week")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)

                Spacer()
            }

            if goals.isEmpty {
                emptyState
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    Grid(horizontalSpacing: AppSpacing.md, verticalSpacing: AppSpacing.sm) {
                        GridRow {
                            Text("Day")
                                .font(AppTypography.callout)
                                .foregroundColor(AppColors.textMuted)
                                .frame(width: 72, alignment: .leading)
                                .gridColumnAlignment(.leading)

                            ForEach(goals) { goal in
                                Text(displayLabel(for: goal))
                                    .font(AppTypography.callout)
                                    .foregroundColor(AppColors.textPrimary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 96)
                            }
                        }

                        ForEach(weekDays) { day in
                            GridRow {
                                Text(day.label)
                                    .font(AppTypography.subheadline)
                                    .foregroundColor(AppColors.textSecondary)
                                    .frame(width: 72, alignment: .leading)
                                    .gridColumnAlignment(.leading)

                                ForEach(goals) { goal in
                                    let completionDays = completionDays(for: goal)
                                    completionCell(
                                        isCompleted: completionDays.contains(calendar.startOfDay(for: day.date)),
                                        isFuture: isFuture(day.date)
                                    )
                                }
                            }
                        }

                        GridRow {
                            Text("Total")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textMuted)
                                .frame(width: 72, alignment: .leading)
                                .gridColumnAlignment(.leading)

                            ForEach(goals) { goal in
                                Text("\(completionCount(for: goal))/7")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                                    .frame(width: 96)
                            }
                        }
                    }
                    .padding(.trailing, AppSpacing.md)
                }
            }
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var nextWeekSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("Any changes for next week?")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Text("Daily Break Budget")
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textSecondary)

                    Spacer()

                    Text("\(dailyScreenTimeLimit) min")
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textPrimary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedLimitMinutes = dailyScreenTimeLimit
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingLimitPicker.toggle()
                    }
                }

                if showingLimitPicker {
                    Picker("Minutes", selection: $selectedLimitMinutes) {
                        ForEach(Self.limitOptions, id: \.self) { value in
                            Text("\(value) min")
                                .tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .environment(\.colorScheme, .light)
                    .frame(height: 140)
                }
            }
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.large)
                    .fill(Color.white.opacity(0.9))
            )
            .shadow(color: AppColors.shadowColor, radius: 6, x: 0, y: 3)

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Toggle(isOn: $removeBlockAfterAllGoals) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Done for the Day")
                            .font(AppTypography.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                        Text(removeBlockAfterAllGoals ? "When every goal is completed all apps are unlocked." : "Only unlock apps using minutes that are earned from break budget.")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textMuted)
                    }
                }
                .tint(AppColors.primary)
                .onChange(of: removeBlockAfterAllGoals) { _, _ in
                    screenTimeManager.enforceBlockingState()
                }
            }
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.large)
                    .fill(Color.white.opacity(0.9))
            )
            .shadow(color: AppColors.shadowColor, radius: 6, x: 0, y: 3)

            appBlockingSection

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Text("Goals")
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textSecondary)

                    Spacer()

                    Button(action: { showingAddGoal = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(AppColors.primary)
                    }
                }

                ForEach(goals) { goal in
                    HStack(spacing: AppSpacing.sm) {
                        Text(displayLabel(for: goal))
                            .font(AppTypography.subheadline)
                            .foregroundColor(AppColors.textPrimary)
                            .lineLimit(1)

                        Spacer()

                        Button("Edit") {
                            selectedGoalForEdit = goal
                        }
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.primary)
                    }
                    .padding(.vertical, AppSpacing.xs)
                }
            }
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.large)
                    .fill(Color.white.opacity(0.9))
            )
            .shadow(color: AppColors.shadowColor, radius: 6, x: 0, y: 3)

            HoldToStartButton(title: "Hold to lock in next week") {
                if let stats = allStats.first {
                    stats.lastWeeklyReviewDate = Date()
                    modelContext.safeSave()
                }
                AnalyticsService.shared.capture(Constants.AnalyticsEvents.weeklyReviewCompleted, properties: [
                    "goals_reviewed": goals.count,
                    "feelings_submitted": feelingsByGoal.count,
                    "daily_limit_changed": selectedLimitMinutes != dailyScreenTimeLimit
                ])
                dismiss()
            }
            .frame(height: 58)
        }
    }

    private var appBlockingSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("App blocking")
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)

                Spacer()

                if screenTimeManager.isAvailable {
                    Button(action: { showingAppSelection = true }) {
                        Text(screenTimeManager.hasSelection ? "Change selection" : "Select apps")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.primary)
                    }
                }
            }

            if screenTimeManager.isAvailable, screenTimeManager.hasSelection {
                Text("\(screenTimeManager.selectedAppCount) apps, \(screenTimeManager.selectedCategoryCount) categories")
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textPrimary)
            } else if !screenTimeManager.isAvailable {
                Text("App blocking isn't available on this device.")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textMuted)
            } else {
                Text("No apps selected yet.")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textMuted)
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.large)
                .fill(Color.white.opacity(0.9))
        )
        .shadow(color: AppColors.shadowColor, radius: 6, x: 0, y: 3)
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Step \(selectedPage + 1) of \(totalSteps)")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textMuted)

            ProgressView(value: Double(selectedPage + 1), total: Double(max(totalSteps, 1)))
                .tint(AppColors.primary)
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.sm) {
            Text("No habits yet")
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.textSecondary)

            Text("Add a goal to start tracking your week.")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.md)
    }

    private func completionCell(isCompleted: Bool, isFuture: Bool) -> some View {
        let borderColor = isFuture ? AppColors.inputBorder.opacity(0.5) : AppColors.inputBorder
        let fillColor = isCompleted ? AppColors.primary : Color.clear

        return RoundedRectangle(cornerRadius: 6)
            .fill(fillColor)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isCompleted ? AppColors.primary : borderColor, lineWidth: 1)
            )
            .frame(width: 28, height: 28)
            .opacity(isFuture ? 0.6 : 1)
    }

    private var weekDays: [WeekDay] {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: Date()) else { return [] }
        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: interval.start) else { return nil }
            return WeekDay(
                date: date,
                label: Self.dayFullFormatter.string(from: date)
            )
        }
    }

    private var weekRangeText: String {
        let start = weekStart
        let end = calendar.date(byAdding: .day, value: 6, to: start) ?? start
        return "\(Self.rangeFormatter.string(from: start)) - \(Self.rangeFormatter.string(from: end))"
    }

    private var weekStart: Date {
        calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? calendar.startOfDay(for: Date())
    }

    private func completionDays(for goal: Goal) -> Set<Date> {
        guard let completions = goal.completions else { return [] }
        return Set(completions.map { calendar.startOfDay(for: $0.date) })
    }

    private func completionCount(for goal: Goal) -> Int {
        let completionDays = completionDays(for: goal)
        return weekDays.reduce(0) { count, day in
            completionDays.contains(calendar.startOfDay(for: day.date)) ? count + 1 : count
        }
    }

    private func displayLabel(for goal: Goal) -> String {
        let trimmedMicroHabit = goal.microHabit.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedMicroHabit.isEmpty {
            return trimmedMicroHabit
        }
        return goal.title
    }

    private func weeklyFeelingBinding(for goal: Goal) -> Binding<WeeklyFeeling> {
        Binding(
            get: { feelingsByGoal[goal.id] ?? .good },
            set: { feelingsByGoal[goal.id] = $0 }
        )
    }

    private func reflectionBinding(for goal: Goal) -> Binding<String> {
        Binding(
            get: { reflectionsByGoal[goal.id] ?? "" },
            set: { reflectionsByGoal[goal.id] = $0 }
        )
    }

    private var totalSteps: Int {
        max(1, 2 + goals.count)
    }

    private var dailyScreenTimeLimit: Int {
        allStats.first?.dailyMinutesTarget ?? Constants.Defaults.dailyMinutesTarget
    }

    private func updateDailyLimit() {
        guard let stats = allStats.first else { return }
        stats.dailyMinutesTarget = selectedLimitMinutes
        modelContext.safeSave()
    }

    private static let limitOptions = Array(stride(from: 10, through: 300, by: 10))

    private func isFuture(_ date: Date) -> Bool {
        calendar.startOfDay(for: date) > calendar.startOfDay(for: Date())
    }

    private struct WeekDay: Identifiable {
        let date: Date
        let label: String

        var id: Date { date }
    }

    private static let dayFullFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "EEE"
        return formatter
    }()

    private static let rangeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "MMM d"
        return formatter
    }()
}

private struct WeeklyGoalReviewView: View {
    let goal: Goal
    @Binding var feeling: WeeklyFeeling
    @Binding var reflection: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("How did this habit feel?")
                .font(AppTypography.title2)
                .foregroundColor(AppColors.textPrimary)

            Text(displayLabel)
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.textSecondary)

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("This week felt…")
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)

                HStack(spacing: AppSpacing.sm) {
                    ForEach(WeeklyFeeling.allCases) { option in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                feeling = option
                            }
                        }) {
                            Text(option.label)
                                .font(AppTypography.subheadline)
                                .fontWeight(feeling == option ? .semibold : .regular)
                                .foregroundColor(feeling == option ? .white : AppColors.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppSpacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                        .fill(feeling == option ? AppColors.primary : Color.white.opacity(0.6))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                        .stroke(feeling == option ? AppColors.primary : AppColors.inputBorder, lineWidth: 1)
                                )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
            }

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Reflection")
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)

                ZStack(alignment: .topLeading) {
                    TextEditor(text: $reflection)
                        .frame(minHeight: 140)
                        .padding(6)
                        .scrollContentBackground(.hidden)
                        .background(AppColors.inputBackground)
                        .cornerRadius(AppCornerRadius.medium)

                    if reflection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Write a quick reflection...")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textMuted)
                            .padding(.leading, 12)
                            .padding(.top, 12)
                    }
                }
            }

            Spacer(minLength: AppSpacing.xl)
        }
    }

    private var displayLabel: String {
        let trimmedMicroHabit = goal.microHabit.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedMicroHabit.isEmpty {
            return trimmedMicroHabit
        }
        return goal.title
    }
}

private struct GoalEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var goal: Goal
    @FocusState private var isTriggerInputFocused: Bool
    @State private var triggerTime: Date
    @State private var triggerValueInput: String
    @State private var selectedProofMethods: Set<ProofMethod>
    let onClose: () -> Void

    init(goal: Goal, onClose: @escaping () -> Void) {
        self.goal = goal
        self.onClose = onClose
        let trimmedValue = goal.triggerValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if goal.triggerType == .time, let date = Self.timeFormatter.date(from: trimmedValue) {
            _triggerTime = State(initialValue: date)
        } else {
            _triggerTime = State(initialValue: Date())
        }
        _triggerValueInput = State(initialValue: goal.triggerType == .time ? "" : goal.triggerValue)
        _selectedProofMethods = State(initialValue: Set(goal.proofMethods))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackgroundView()

                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    Text("Edit goal")
                        .font(AppTypography.title2)
                        .foregroundColor(AppColors.textPrimary)

                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Microhabit")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textMuted)

                        InputField(
                            placeholder: "Microhabit",
                            text: $goal.microHabit,
                            isValid: !goal.microHabit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                            maxLength: Constants.Validation.maxMicroHabitLength,
                            characterCountThreshold: Constants.Validation.characterCountThreshold
                        )
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("When")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textMuted)

                        VStack(spacing: AppSpacing.sm) {
                            TriggerOptionCard(
                                title: TriggerType.time.displayTitle,
                                icon: "clock.fill",
                                isSelected: goal.triggerType == .time,
                                onSelect: {
                                    selectTriggerType(.time)
                                }
                            ) {
                                DatePicker(
                                    "",
                                    selection: $triggerTime,
                                    displayedComponents: .hourAndMinute
                                )
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                                .environment(\.colorScheme, .light)
                                .frame(height: 120)
                                .onChange(of: triggerTime) { _, newValue in
                                    guard goal.triggerType == .time else { return }
                                    goal.triggerValue = Self.timeFormatter.string(from: newValue)
                                }
                            }

                            TriggerOptionCard(
                                title: TriggerType.after.displayTitle,
                                icon: "arrow.right.circle.fill",
                                isSelected: goal.triggerType == .after,
                                onSelect: {
                                    selectTriggerType(.after)
                                }
                            ) {
                                TextField(TriggerType.after.placeholder, text: triggerValueBinding)
                                    .font(AppTypography.body)
                                    .focused($isTriggerInputFocused, equals: goal.triggerType == .after)
                                    .padding(AppSpacing.sm)
                                    .background(AppColors.inputBackground)
                                    .cornerRadius(AppCornerRadius.small)
                            }

                            TriggerOptionCard(
                                title: TriggerType.location.displayTitle,
                                icon: "mappin.circle.fill",
                                isSelected: goal.triggerType == .location,
                                onSelect: {
                                    selectTriggerType(.location)
                                }
                            ) {
                                TextField(TriggerType.location.placeholder, text: triggerValueBinding)
                                    .font(AppTypography.body)
                                    .focused($isTriggerInputFocused, equals: goal.triggerType == .location)
                                    .padding(AppSpacing.sm)
                                    .background(AppColors.inputBackground)
                                    .cornerRadius(AppCornerRadius.small)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Proof methods")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textMuted)

                        VStack(spacing: AppSpacing.sm) {
                            ForEach(proofOptions) { method in
                                ProofOptionCard(
                                    method: method,
                                    isSelected: selectedProofMethods.contains(method),
                                    isEnabled: true,
                                    onToggle: {
                                        toggleProofMethod(method)
                                    }
                                )
                            }
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.lg)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    isTriggerInputFocused = false
                }
            }
            .navigationTitle("Edit goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        onClose()
                        dismiss()
                    }
                    .foregroundColor(AppColors.textSecondary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        modelContext.safeSave()
                        NotificationManager.shared.scheduleGoalReminder(for: goal)
                        AnalyticsService.shared.capture(Constants.AnalyticsEvents.goalEdited, properties: [
                            Constants.AnalyticsProperties.goalId: goal.id.uuidString
                        ])
                        onClose()
                        dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
        }
    }

    private var triggerValueBinding: Binding<String> {
        Binding(
            get: { triggerValueInput },
            set: { newValue in
                triggerValueInput = newValue
                goal.triggerValue = newValue
            }
        )
    }

    private func selectTriggerType(_ type: TriggerType) {
        withAnimation {
            goal.triggerType = type
            switch type {
            case .time:
                goal.triggerValue = Self.timeFormatter.string(from: triggerTime)
            case .after, .location:
                if triggerValueInput.isEmpty {
                    triggerValueInput = goal.triggerValue
                }
                goal.triggerValue = triggerValueInput
                isTriggerInputFocused = true
            }
        }
    }

    private func toggleProofMethod(_ method: ProofMethod) {
        if selectedProofMethods.contains(method) {
            selectedProofMethods.remove(method)
        } else {
            selectedProofMethods.insert(method)
        }
        goal.proofMethods = Array(selectedProofMethods)
    }

    private var proofOptions: [ProofMethod] {
        if Constants.Features.friendVouchEnabled {
            return ProofMethod.allCases
        }
        return ProofMethod.allCases.filter { $0 != .friendVouch }
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    WeeklyReviewView()
        .environment(ScreenTimeManager.shared)
        .modelContainer(for: [Goal.self, CompletionRecord.self, ProofItem.self], inMemory: true)
}
