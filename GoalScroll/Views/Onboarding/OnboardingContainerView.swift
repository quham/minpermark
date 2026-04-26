import SwiftUI
import SwiftData

struct OnboardingContainerView: View {
    enum FlowMode {
        case onboarding
        case addGoal
    }

    let mode: FlowMode

    @Environment(AppState.self) var appState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var currentStep: OnboardingStep
    @State private var hasResetForAddGoal = false
    @State private var showingAddGoal = false
    @State private var showingFirstRunSetup = false
    @State private var showingMissingInfoAlert = false
    @State private var missingInfoMessage = ""
    @State private var lastValidStep: OnboardingStep
    @State private var didSaveGoal = false

    enum OnboardingStep: Int, CaseIterable {
        case namePrompt = 0
        case enterGoal = 1
        case goalTransition = 2
        case defineMicrohabit = 3
        case chooseTrigger = 4
        case proofSelection = 5
        case whyImportance = 6
        case summary = 7
        case gotIt = 8
    }

    init(mode: FlowMode = .onboarding) {
        self.mode = mode
        let initialStep: OnboardingStep = mode == .onboarding ? .namePrompt : .enterGoal
        _currentStep = State(initialValue: initialStep)
        _lastValidStep = State(initialValue: initialStep)
    }

    var body: some View {
        content
    }

    private var content: some View {
        ZStack {
            GradientBackgroundView()

            VStack(spacing: 0) {
                // Top navigation + progress
                VStack(spacing: AppSpacing.sm) {
                    HStack {
                        if mode == .addGoal {
                            SecondaryButton(title: "Back") {
                                dismiss()
                            }
                        } else if !isFirstStep {
                            SecondaryButton(title: "Back") {
                                previousStep()
                            }
                        }

                        Spacer()
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.md)

                    if currentStep != .summary {
                        OnboardingProgressBar(progress: progressValue)
                            .padding(.horizontal, AppSpacing.lg)
                    }
                }

                // Content
                TabView(selection: $currentStep) {
                    NamePromptView(onContinue: { nextStep() })
                        .tag(OnboardingStep.namePrompt)

                    EnterGoalView(onContinue: { nextStep() })
                        .tag(OnboardingStep.enterGoal)

                    GoalTransitionView(onContinue: { nextStep() })
                        .tag(OnboardingStep.goalTransition)

                    DefineMicrohabitView(onContinue: { nextStep() })
                        .tag(OnboardingStep.defineMicrohabit)

                    ChooseTriggerView(onContinue: { nextStep() })
                        .tag(OnboardingStep.chooseTrigger)

                    ProofSelectionView(onContinue: { nextStep() })
                        .tag(OnboardingStep.proofSelection)

                    WhyImportanceView(onContinue: { nextStep() })
                        .tag(OnboardingStep.whyImportance)

                    SummaryView(
                        onStart: { handleSummaryAction() },
                        actionStyle: .holdToStart,
                        actionTitle: "Hold to add",
                        actionNote: "Hold for a second to commit"
                    )
                        .tag(OnboardingStep.summary)

                    if mode == .onboarding {
                        GotItView(
                            onStart: { finishOnboarding() },
                            onAddGoal: { showingAddGoal = true }
                        )
                        .tag(OnboardingStep.gotIt)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .scrollDisabled(true)
                .onChange(of: currentStep) { oldValue, newValue in
                    hideKeyboard()
                    handleStepChange(from: oldValue, to: newValue)
                }
            }
        }
        .onAppear {
            if mode == .addGoal && !hasResetForAddGoal {
                appState.resetOnboardingGoal()
                currentStep = .enterGoal
                hasResetForAddGoal = true
            }
        }
        .sheet(isPresented: $showingAddGoal) {
            AddGoalView()
        }
        .fullScreenCover(isPresented: $showingFirstRunSetup) {
            FirstRunSetupView()
        }
        .alert("Missing info", isPresented: $showingMissingInfoAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(missingInfoMessage)
        }
    }

    private func nextStep() {
        let completedStep = currentStep
        withAnimation {
            if let nextIndex = OnboardingStep(rawValue: currentStep.rawValue + 1) {
                currentStep = nextIndex
            }
        }
        AnalyticsService.shared.capture(Constants.AnalyticsEvents.onboardingStepCompleted, properties: [
            Constants.AnalyticsProperties.stepName: stepName(for: completedStep),
            Constants.AnalyticsProperties.stepIndex: completedStep.rawValue,
            "flow_mode": mode == .onboarding ? "onboarding" : "add_goal"
        ])
    }

    private func stepName(for step: OnboardingStep) -> String {
        switch step {
        case .namePrompt: return "name_prompt"
        case .enterGoal: return "enter_goal"
        case .goalTransition: return "goal_transition"
        case .defineMicrohabit: return "define_microhabit"
        case .chooseTrigger: return "choose_trigger"
        case .proofSelection: return "proof_selection"
        case .whyImportance: return "why_importance"
        case .summary: return "summary"
        case .gotIt: return "got_it"
        }
    }

    private func previousStep() {
        withAnimation {
            if let prevIndex = OnboardingStep(rawValue: currentStep.rawValue - 1) {
                currentStep = prevIndex
            }
        }
    }

    private var isFirstStep: Bool {
        switch mode {
        case .onboarding:
            return currentStep == .namePrompt
        case .addGoal:
            return currentStep == .enterGoal
        }
    }

    private var progressValue: Double {
        let totalSteps = mode == .onboarding ? OnboardingStep.allCases.count : OnboardingStep.allCases.count - 2
        let stepIndex = mode == .onboarding ? currentStep.rawValue : max(currentStep.rawValue - 1, 0)
        guard totalSteps > 0 else { return 0 }
        return Double(stepIndex + 1) / Double(totalSteps)
    }

    private func handleSummaryAction() {
        guard validateGoalBeforeSaving() else { return }
        guard !didSaveGoal else { return }
        didSaveGoal = true

        switch mode {
        case .onboarding:
            saveGoalForOnboarding()
            nextStep()
        case .addGoal:
            saveGoalAndDismiss()
        }
    }

    private func finishOnboarding() {
        if appState.hasCompletedFirstRunSetup {
            appState.completeOnboarding()
            AnalyticsService.shared.capture(Constants.AnalyticsEvents.onboardingCompleted, properties: [
                Constants.AnalyticsProperties.triggerType: appState.onboardingGoal.triggerType.rawValue,
                Constants.AnalyticsProperties.proofMethods: Array(appState.onboardingGoal.proofMethods).map(\.rawValue),
                Constants.AnalyticsProperties.importance: appState.onboardingGoal.importance
            ])
            AnalyticsService.shared.setUserProperties(["onboarding_completed_at": ISO8601DateFormatter().string(from: Date())])
        } else {
            showingFirstRunSetup = true
        }
    }

    private func saveGoalForOnboarding() {
        let goal = appState.onboardingGoal.toGoal()
        modelContext.insert(goal)

        // Create or update stats with anchor goal
        let statsDescriptor = FetchDescriptor<UserStats>()
        if let existingStats = try? modelContext.fetch(statsDescriptor).first {
            existingStats.anchorGoalID = goal.id
        } else {
            let newStats = UserStats(anchorGoalID: goal.id)
            modelContext.insert(newStats)
        }

        modelContext.safeSave()
        NotificationManager.shared.scheduleGoalReminder(for: goal)
        ShieldSharedStore.shared.updateFromGoal(goal)
        appState.shouldShowStartNowPrompt = false

        AnalyticsService.shared.capture(Constants.AnalyticsEvents.goalCreated, properties: [
            Constants.AnalyticsProperties.goalId: goal.id.uuidString,
            Constants.AnalyticsProperties.triggerType: goal.triggerType.rawValue,
            Constants.AnalyticsProperties.proofMethods: goal.proofMethods.map(\.rawValue),
            Constants.AnalyticsProperties.importance: goal.importance,
            "flow_mode": "onboarding"
        ])
    }

    private func saveGoalAndDismiss() {
        let goal = appState.onboardingGoal.toGoal()
        modelContext.insert(goal)
        modelContext.safeSave()
        NotificationManager.shared.scheduleGoalReminder(for: goal)
        appState.shouldShowStartNowPrompt = true

        AnalyticsService.shared.capture(Constants.AnalyticsEvents.goalCreated, properties: [
            Constants.AnalyticsProperties.goalId: goal.id.uuidString,
            Constants.AnalyticsProperties.triggerType: goal.triggerType.rawValue,
            Constants.AnalyticsProperties.proofMethods: goal.proofMethods.map(\.rawValue),
            Constants.AnalyticsProperties.importance: goal.importance,
            "flow_mode": "add_goal"
        ])

        appState.resetOnboardingGoal()
        dismiss()
    }

    private func validateGoalBeforeSaving() -> Bool {
        let missingParts = appState.onboardingGoal.missingParts
        guard missingParts.isEmpty else {
            missingInfoMessage = "Please complete: \(missingParts.joined(separator: ", "))."
            showingMissingInfoAlert = true
            return false
        }

        return true
    }

    private func isStepValid(_ step: OnboardingStep) -> Bool {
        switch step {
        case .namePrompt:
            return !appState.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .enterGoal:
            return appState.onboardingGoal.isGoalValid
        case .goalTransition:
            return true
        case .defineMicrohabit:
            return appState.onboardingGoal.isMicroHabitValid
        case .chooseTrigger:
            return appState.onboardingGoal.isTriggerValid
        case .proofSelection:
            return !appState.onboardingGoal.proofMethods.isEmpty
        case .whyImportance:
            return appState.onboardingGoal.why.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3
        case .summary, .gotIt:
            return true
        }
    }

    private func handleStepChange(from oldStep: OnboardingStep, to newStep: OnboardingStep) {
        // Allow backward navigation always
        if newStep.rawValue < oldStep.rawValue {
            return
        }

        // Check if all previous steps are valid
        let startIndex = mode == .onboarding ? OnboardingStep.namePrompt.rawValue : OnboardingStep.enterGoal.rawValue
        
        for stepIndex in startIndex..<newStep.rawValue {
            if let step = OnboardingStep(rawValue: stepIndex), !isStepValid(step) {
                // Bounce back to the FIRST invalid step found in the flow
                if currentStep != step {
                    DispatchQueue.main.async {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            currentStep = step
                        }
                    }
                }
                return
            }
        }
        
        // If we got here, all previous steps are valid. 
        // Update lastValidStep if it's further than before.
        if newStep.rawValue > lastValidStep.rawValue {
            lastValidStep = newStep
        }
    }
}

// MARK: - Helpers
struct OnboardingProgressBar: View {
    let progress: Double
    
    private var clampedProgress: Double {
        guard progress.isFinite else { return 0 }
        return min(max(progress, 0), 1)
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width.isFinite ? geometry.size.width : 0
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppColors.inputBackground)
                    .frame(height: 4)

                Capsule()
                    .fill(AppColors.primary)
                    .frame(width: width * clampedProgress, height: 4)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: clampedProgress)
            }
        }
        .frame(height: 4)
    }
}

#Preview {
    OnboardingContainerView()
        .environment(AppState())
        .modelContainer(for: [Goal.self, UserStats.self], inMemory: true)
}
