import Foundation

enum Constants {
    // MARK: - App Configuration
    enum App {
        static let name = "GoalScroll"
        static let version = "1.0.0"
        static let bundleIdentifier = "com.goalscroll.app"
        static let groupIdentifier = "group.com.goalscroll.settings"
        static let shareMessage = "I'm using GoalScroll to stay on track."
    }

    // MARK: - Validation
    enum Validation {
        static let minGoalLength = 3
        static let maxGoalLength = 80
        static let minMicroHabitLength = 3
        static let maxMicroHabitLength = 80
        static let minTriggerLength = 3
        static let characterCountThreshold = 70
    }

    // MARK: - Default Values
    enum Defaults {
        static let dailyMinutesTarget = 60
        static let minutesPerGoal = 10
        static let importanceDefault = 5
        static let importanceMin = 1
        static let importanceMax = 10
    }

    // MARK: - Time Intervals
    enum TimeIntervals {
        static let animationDuration: Double = 0.3
        static let debounceDelay: Double = 0.5
        static let networkTimeout: TimeInterval = 60
        static let snoozeDuration: TimeInterval = 30 * 60 // 30 minutes
        static let inputFocusDelay: Double = 0.6  // Delay for keyboard focus after view appears
        static let secondsPerHour: Int = 3600
        static let secondsPerMinute: Int = 60
    }

    // MARK: - Calendar
    enum CalendarConstants {
        static let sundayWeekday = 1  // Calendar.current uses 1 for Sunday
    }

    // MARK: - User Defaults Keys
    enum UserDefaultsKeys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let hasCompletedFirstRunSetup = "hasCompletedFirstRunSetup"
        static let displayName = "displayName"
        static let proofStrictness = "proofStrictness"
        static let requireProofForMinutes = "requireProofForMinutes"
        static let notificationsEnabled = "notificationsEnabled"
        static let lastDailyResetDate = "lastDailyResetDate"
        static let notificationSoundEnabled = "notificationSoundEnabled"
        static let saveHabitLogs = "saveHabitLogs"
        static let removeBlockAfterAllGoals = "removeBlockAfterAllGoals"
        static let weeklyReviewDay = "weeklyReviewDay"
        static let weeklyReviewTime = "weeklyReviewTime"
        static let unlockExpiryDate = "unlockExpiryDate"
        static let unlockStartDate = "unlockStartDate"
        static let pendingMinuteDeduction = "pendingMinuteDeduction"
        static let screenTimeSelection = "ScreenTimeAppSelection"

        // Supabase / Sync
        static let lastSyncDate = "lastSyncDate"
        static let pendingSyncOperations = "pendingSyncOperations"
    }

    // MARK: - DeviceActivity
    enum DeviceActivity {
        static let unlockSessionIdentifier = "com.goalscroll.unlockSession"
    }

    // MARK: - Shield Configuration
    enum Shield {
        static let goalTitleKey = "shield_goal_title"
        static let whyKey = "shield_why"
        static let iconFilename = "shield-icon.png"
    }

    // MARK: - Notification Identifiers
    enum NotificationIdentifiers {
        static let goalReminder = "GOAL_REMINDER"
        static let goalCheckin = "GOAL_CHECKIN"
        static let streakReminder = "STREAK_REMINDER"
        static let weeklyReview = "WEEKLY_REVIEW"
        static let unlockWarning = "UNLOCK_WARNING"
        static let unlockEnded = "UNLOCK_ENDED"
    }

    // MARK: - Analytics Events
    enum AnalyticsEvents {
        // Auth
        static let userSignedUp = "user_signed_up"
        static let userSignedIn = "user_signed_in"
        static let userSignedOut = "user_signed_out"
        static let accountDeleted = "account_deleted"
        // Onboarding
        static let onboardingStepCompleted = "onboarding_step_completed"
        static let onboardingCompleted = "onboarding_completed"
        // Goals
        static let goalCreated = "goal_created"
        static let goalEdited = "goal_edited"
        static let goalArchived = "goal_archived"
        static let goalCompleted = "goal_completed"
        // Proof & Verification
        static let proofSubmitted = "proof_submitted"
        static let verificationStarted = "verification_started"
        static let verificationStatus = "verification_status"
        // Microhabits
        static let microHabitSuggestionFetched = "microhabit_suggestion_fetched"
        static let microHabitSuggestionUsed = "microhabit_suggestion_used"
        // Unlock
        static let unlockStarted = "unlock_started"
        static let unlockEnded = "unlock_ended"
        // Review
        static let weeklyReviewOpened = "weekly_review_opened"
        static let weeklyReviewCompleted = "weekly_review_completed"
        // Engagement
        static let appBlockingEnabled = "app_blocking_enabled"
        static let dailyOpen = "daily_open"
    }

    // MARK: - Analytics Property Keys
    enum AnalyticsProperties {
        static let goalId = "goal_id"
        static let triggerType = "trigger_type"
        static let proofMethods = "proof_methods"
        static let stepName = "step_name"
        static let stepIndex = "step_index"
        static let verificationResult = "verification_result"
        static let confidence = "confidence"
        static let minutesRequested = "minutes_requested"
        static let minutesUsed = "minutes_used"
        static let endedEarly = "ended_early"
        static let importance = "importance"
        static let minutesReward = "minutes_reward"
    }

    // MARK: - Image Configuration
    enum Image {
        static let maxDimension: CGFloat = 1280
        static let compressionQuality: CGFloat = 0.8
    }

    // MARK: - API Configuration (Legacy - kept for reference)
    enum API {
        static let backendBaseURL = "https://goalscroll1.onrender.com"
    }

    // MARK: - Supabase Configuration
    enum Supabase {
        // Read from Info.plist (set via xcconfig)
        static let url: String = {
            guard let value = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String,
                  !value.isEmpty,
                  !value.contains("YOUR_PROJECT") else {
                fatalError("SUPABASE_URL not configured. See Config/Secrets.xcconfig.example")
            }
            return value
        }()

        static let anonKey: String = {
            guard let value = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String,
                  !value.isEmpty,
                  !value.contains("YOUR_ANON_KEY") else {
                fatalError("SUPABASE_ANON_KEY not configured. See Config/Secrets.xcconfig.example")
            }
            return value
        }()

        // Edge Function names
        static let suggestionsFunction = "suggestions"
        static let verifyFunction = "verify"
        static let deleteAccountFunction = "delete-account"
    }

    // MARK: - Feature Flags
    enum Features {
        static let friendVouchEnabled = false
        static let screenTimeBlockingEnabled = true
        static let geminiVerificationEnabled = true
    }
}

// MARK: - Localized Strings

enum LocalizedStrings {
    // Onboarding
    static let namePromptTitle = "What should we call you?"
    static let namePromptSubtitle = "We will use this in your greeting."
    static let enterGoalTitle = "What do you want to work toward?"
    static let enterGoalSubtitle = "Big goals are welcome. We'll make it doable."
    static let microHabitTitle = "What's one small action you can do consistently?"
    static let microHabitSubtitle = "It should feel almost too easy."
    static let triggerTitle = "When should this happen?"
    static let triggerSubtitle = "Clear triggers make habits stick."
    static let proofTitle = "How do you want to track your progress?"
    static let proofSubtitle = "Choose a method that confirms you showed up (the more the better)."
    static let whyTitle = "Why is this important to you?"
    static let summaryTitle = "Your Commitment"
    static let summarySubtitle = "Small steps make big changes"

    // Home
    static let goodMorning = "Good Morning"
    static let goodAfternoon = "Good Afternoon"
    static let goodEvening = "Good Evening"
    static let todaysGoals = "Today's Goals"
    static let unlockApps = "Unlock apps now"

    // Actions
    static let continueButton = "Continue"
    static let lockThisIn = "Lock this in"
    static let soundsRight = "Sounds right"
    static let saveThis = "Save this"
    static let startDayOne = "Start Day One"
    static let iDidThis = "I did this"
    static let done = "Done"

    // Verification Status
    static let verifying = "Verifying..."
    static let verified = "Verified"
    static let tryAgain = "Try again"
    static let underReview = "Under review"

    // Errors
    static let makeSmallerNudge = "Make it smaller. You should be able to do it on your worst day."
    static let verificationFailed = "That doesn't look like the proof you chose. Want to try again?"
    static let networkError = "Couldn't verify right now. You're still good."
    static let proofRequired = "Proof is required"
    static let screenshotMustBeFromToday = "Screenshot must be from today."

    // Privacy
    static let privacyNote = "Everything is saved locally on your device."
}
