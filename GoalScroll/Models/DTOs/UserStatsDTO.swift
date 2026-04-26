import Foundation

// MARK: - User Stats DTO

/// Data Transfer Object for syncing UserStats with Supabase
struct UserStatsDTO: Codable {
    let id: UUID?
    let userId: UUID
    var todayMinutesEarned: Int
    var lifetimeMinutesEarned: Int
    var currentStreakDays: Int
    var longestStreakDays: Int
    var lastStreakDate: Date?
    var dailyMinutesTarget: Int
    var anchorGoalId: UUID?
    var lastResetDate: Date
    var lastWeeklyReviewDate: Date?
    var createdAt: Date?
    var updatedAt: Date?

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case todayMinutesEarned = "today_minutes_earned"
        case lifetimeMinutesEarned = "lifetime_minutes_earned"
        case currentStreakDays = "current_streak_days"
        case longestStreakDays = "longest_streak_days"
        case lastStreakDate = "last_streak_date"
        case dailyMinutesTarget = "daily_minutes_target"
        case anchorGoalId = "anchor_goal_id"
        case lastResetDate = "last_reset_date"
        case lastWeeklyReviewDate = "last_weekly_review_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Conversion from SwiftData Model

    init(from stats: UserStats, userId: UUID) {
        self.id = nil // Let server assign
        self.userId = userId
        self.todayMinutesEarned = stats.todayMinutesEarned
        self.lifetimeMinutesEarned = stats.lifetimeMinutesEarned
        self.currentStreakDays = stats.currentStreakDays
        self.longestStreakDays = stats.longestStreakDays
        self.lastStreakDate = stats.lastStreakDate
        self.dailyMinutesTarget = stats.dailyMinutesTarget
        self.anchorGoalId = stats.anchorGoalID
        self.lastResetDate = stats.lastResetDate
        self.lastWeeklyReviewDate = stats.lastWeeklyReviewDate
        self.createdAt = nil
        self.updatedAt = nil
    }

    // MARK: - Conversion to SwiftData Model

    func toUserStats() -> UserStats {
        UserStats(
            todayMinutesEarned: todayMinutesEarned,
            lifetimeMinutesEarned: lifetimeMinutesEarned,
            currentStreakDays: currentStreakDays,
            longestStreakDays: longestStreakDays,
            lastStreakDate: lastStreakDate,
            dailyMinutesTarget: dailyMinutesTarget,
            anchorGoalID: anchorGoalId,
            lastResetDate: lastResetDate,
            lastWeeklyReviewDate: lastWeeklyReviewDate
        )
    }

    // MARK: - Update Local Stats from DTO

    func updateStats(_ stats: UserStats) {
        // Only update fields where server value is "better" or newer
        // Lifetime stats should take the max
        stats.lifetimeMinutesEarned = max(stats.lifetimeMinutesEarned, lifetimeMinutesEarned)
        stats.longestStreakDays = max(stats.longestStreakDays, longestStreakDays)

        // Current day stats - prefer server if same day reset
        if Calendar.current.isDate(stats.lastResetDate, inSameDayAs: lastResetDate) {
            stats.todayMinutesEarned = max(stats.todayMinutesEarned, todayMinutesEarned)
            stats.currentStreakDays = max(stats.currentStreakDays, currentStreakDays)
        }

        // Target can be updated
        stats.dailyMinutesTarget = dailyMinutesTarget

        // Streak date - take most recent
        if let serverDate = lastStreakDate {
            if let localDate = stats.lastStreakDate {
                stats.lastStreakDate = max(serverDate, localDate)
            } else {
                stats.lastStreakDate = serverDate
            }
        }

        // Weekly review date - take most recent
        if let serverDate = lastWeeklyReviewDate {
            if let localDate = stats.lastWeeklyReviewDate {
                stats.lastWeeklyReviewDate = max(serverDate, localDate)
            } else {
                stats.lastWeeklyReviewDate = serverDate
            }
        }
    }
}

// MARK: - User Stats Upsert DTO

struct UserStatsUpsertDTO: Encodable {
    let userId: UUID
    let todayMinutesEarned: Int
    let lifetimeMinutesEarned: Int
    let currentStreakDays: Int
    let longestStreakDays: Int
    let lastStreakDate: Date?
    let dailyMinutesTarget: Int
    let anchorGoalId: UUID?
    let lastResetDate: Date
    let lastWeeklyReviewDate: Date?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case todayMinutesEarned = "today_minutes_earned"
        case lifetimeMinutesEarned = "lifetime_minutes_earned"
        case currentStreakDays = "current_streak_days"
        case longestStreakDays = "longest_streak_days"
        case lastStreakDate = "last_streak_date"
        case dailyMinutesTarget = "daily_minutes_target"
        case anchorGoalId = "anchor_goal_id"
        case lastResetDate = "last_reset_date"
        case lastWeeklyReviewDate = "last_weekly_review_date"
    }

    init(from stats: UserStats, userId: UUID) {
        self.userId = userId
        self.todayMinutesEarned = stats.todayMinutesEarned
        self.lifetimeMinutesEarned = stats.lifetimeMinutesEarned
        self.currentStreakDays = stats.currentStreakDays
        self.longestStreakDays = stats.longestStreakDays
        self.lastStreakDate = stats.lastStreakDate
        self.dailyMinutesTarget = stats.dailyMinutesTarget
        self.anchorGoalId = stats.anchorGoalID
        self.lastResetDate = stats.lastResetDate
        self.lastWeeklyReviewDate = stats.lastWeeklyReviewDate
    }
}
