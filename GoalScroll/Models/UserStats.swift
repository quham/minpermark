import Foundation
import SwiftData

// MARK: - User Stats Model

/// Tracks user progress including earned minutes, streaks, and daily targets
@Model
final class UserStats {

    // MARK: - Properties

    var id: UUID
    var todayMinutesEarned: Int
    var lifetimeMinutesEarned: Int
    var currentStreakDays: Int
    var longestStreakDays: Int
    var lastStreakDate: Date?
    var dailyMinutesTarget: Int
    var anchorGoalID: UUID?
    var lastResetDate: Date
    var lastWeeklyReviewDate: Date?

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        todayMinutesEarned: Int = 0,
        lifetimeMinutesEarned: Int = 0,
        currentStreakDays: Int = 0,
        longestStreakDays: Int = 0,
        lastStreakDate: Date? = nil,
        dailyMinutesTarget: Int = Constants.Defaults.dailyMinutesTarget,
        anchorGoalID: UUID? = nil,
        lastResetDate: Date = Calendar.current.startOfDay(for: Date()),
        lastWeeklyReviewDate: Date? = nil
    ) {
        self.id = id
        self.todayMinutesEarned = todayMinutesEarned
        self.lifetimeMinutesEarned = lifetimeMinutesEarned
        self.currentStreakDays = currentStreakDays
        self.longestStreakDays = longestStreakDays
        self.lastStreakDate = lastStreakDate
        self.dailyMinutesTarget = dailyMinutesTarget
        self.anchorGoalID = anchorGoalID
        self.lastResetDate = lastResetDate
        self.lastWeeklyReviewDate = lastWeeklyReviewDate
    }

    // MARK: - Daily Reset

    func resetForNewDay() {
        let today = Calendar.current.startOfDay(for: Date())
        guard lastResetDate < today else { return }

        // Update streak
        if let lastStreak = lastStreakDate {
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
            if !Calendar.current.isDate(lastStreak, inSameDayAs: yesterday) {
                // Broken streak
                currentStreakDays = 0
            }
        } else {
            currentStreakDays = 0
        }

        todayMinutesEarned = 0
        lastResetDate = today
    }

    // MARK: - Minutes Management

    func addMinutes(_ minutes: Int) {
        // Calculate how much can still be earned today
        let remainingCapacity = max(0, dailyMinutesTarget - todayMinutesEarned)
        // Only add the minimum of requested minutes and remaining capacity
        let actualMinutesToAdd = min(minutes, remainingCapacity)
        
        todayMinutesEarned += actualMinutesToAdd
        lifetimeMinutesEarned += actualMinutesToAdd
    }

    func deductMinutes(_ minutes: Int) {
        todayMinutesEarned = max(todayMinutesEarned - minutes, 0)
    }

    // MARK: - Streak Management

    func markAllHabitsCompletedForToday() {
        let today = Calendar.current.startOfDay(for: Date())
        if let lastStreak = lastStreakDate, Calendar.current.isDate(lastStreak, inSameDayAs: today) {
            return
        }

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        if let lastStreak = lastStreakDate, Calendar.current.isDate(lastStreak, inSameDayAs: yesterday) {
            currentStreakDays += 1
        } else {
            currentStreakDays = 1
        }

        longestStreakDays = max(longestStreakDays, currentStreakDays)
        lastStreakDate = today
    }

    // MARK: - Computed Properties

    var progressPercentage: Double {
        guard dailyMinutesTarget > 0 else { return 0 }
        return min(Double(todayMinutesEarned) / Double(dailyMinutesTarget), 1.0)
    }
}
