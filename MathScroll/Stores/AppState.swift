import SwiftUI
import SwiftData

// MARK: - App State

/// Central app state management for global UI state and user preferences
@MainActor
@Observable
class AppState {

    // MARK: - Onboarding State

    var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(
                hasCompletedOnboarding,
                forKey: Constants.UserDefaultsKeys.hasCompletedOnboarding
            )
        }
    }

    var displayName: String {
        didSet {
            UserDefaults.standard.set(displayName, forKey: Constants.UserDefaultsKeys.displayName)
        }
    }

    var hasCompletedFirstRunSetup: Bool {
        didSet {
            UserDefaults.standard.set(
                hasCompletedFirstRunSetup,
                forKey: Constants.UserDefaultsKeys.hasCompletedFirstRunSetup
            )
        }
    }

    // MARK: - Goal Creation State

    /// Current goal being created in onboarding
    var onboardingGoal: OnboardingGoalDraft = OnboardingGoalDraft()

    /// Cached microhabit suggestions from transition screen
    var cachedMicrohabitSuggestions: [String] = []
    var lastSubmittedGoalTitle: String = ""

    // MARK: - Unlock State

    var isUnlocked: Bool = false
    var unlockTimeRemaining: TimeInterval = 0

    // MARK: - Screen Time

    var isScreenTimeAvailable: Bool = false

    // MARK: - UI State

    var activeSheet: ActiveSheet?
    var shouldShowStartNowPrompt: Bool = false

    // MARK: - Initialization

    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(
            forKey: Constants.UserDefaultsKeys.hasCompletedOnboarding
        )
        self.displayName = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.displayName) ?? ""
        self.hasCompletedFirstRunSetup = UserDefaults.standard.bool(
            forKey: Constants.UserDefaultsKeys.hasCompletedFirstRunSetup
        )
    }

    // MARK: - User State (Computed from SupabaseManager)

    var isAuthenticated: Bool {
        SupabaseManager.shared.isAuthenticated
    }

    var userId: UUID? {
        SupabaseManager.shared.userId
    }

    var userEmail: String? {
        SupabaseManager.shared.userEmail
    }

    // MARK: - Sync State (Computed from SyncManager)

    var lastSyncDate: Date? {
        SyncManager.shared.lastSyncDate
    }

    var syncStatus: SyncStatus {
        SyncManager.shared.syncStatus
    }

    var isSyncing: Bool {
        SyncManager.shared.isSyncing
    }

    // MARK: - Public Methods

    func resetOnboardingGoal() {
        onboardingGoal = OnboardingGoalDraft()
        cachedMicrohabitSuggestions = []
        lastSubmittedGoalTitle = ""
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
    }

    /// Sign out the current user and reset app state
    func signOut(modelContext: ModelContext) async {
        do {
            // 1. Clear local data first while still authenticated (if needed, though here we just wipe)
            SyncManager.shared.clearLocalData(modelContext: modelContext)

            // 2. Sign out from Supabase
            try await SupabaseManager.shared.signOut()

            // 3. Reset local state
            hasCompletedOnboarding = false
            hasCompletedFirstRunSetup = false
            displayName = ""
            resetOnboardingGoal()

            Log.ui.info("User signed out, app state reset and data cleared")
        } catch {
            Log.network.error("Sign out failed: \(error.localizedDescription)")
        }
    }

    func deleteAccount(modelContext: ModelContext) async throws {
        try await SupabaseManager.shared.deleteAccount()
        SyncManager.shared.clearLocalData(modelContext: modelContext)
        hasCompletedOnboarding = false
        hasCompletedFirstRunSetup = false
        displayName = ""
        resetOnboardingGoal()
    }
}

// Note: OnboardingGoalDraft has been moved to Models/OnboardingGoalDraft.swift
// Note: ActiveSheet has been moved to Models/ActiveSheet.swift
