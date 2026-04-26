import Foundation

enum CalendarUtils {
    /// Determines if weekly review is due based on scheduled day/time and last review date.
    ///
    /// The weekly review appears once the scheduled time has passed for the current week,
    /// and remains visible until the user completes it (indicated by lastReviewDate).
    ///
    /// - Parameters:
    ///   - weeklyReviewDay: Weekday for review (1=Sunday, 2=Monday, ..., 7=Saturday).
    ///                     A value of 0 defaults to Sunday (1).
    ///   - weeklyReviewTime: Seconds since midnight for the review time.
    ///   - lastReviewDate: Date of last completed review, or nil if never reviewed.
    /// - Returns: `true` if the review should be shown to the user.
    static func isWeeklyReviewDue(
        weeklyReviewDay: Int,
        weeklyReviewTime: Double,
        lastReviewDate: Date?
    ) -> Bool {
        let calendar = Calendar.current
        let now = Date()

        // Build the scheduled date for this week's review
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        components.weekday = weeklyReviewDay == 0
            ? Constants.CalendarConstants.sundayWeekday
            : weeklyReviewDay
        components.hour = Int(weeklyReviewTime) / Constants.TimeIntervals.secondsPerHour
        components.minute = (Int(weeklyReviewTime) % Constants.TimeIntervals.secondsPerHour)
            / Constants.TimeIntervals.secondsPerMinute
        components.second = 0

        guard let scheduledDate = calendar.date(from: components) else {
            Log.data.error("Failed to create scheduled date for weekly review")
            return false
        }

        // If scheduled date is in the future, review time hasn't arrived yet
        if scheduledDate > now {
            return false
        }

        // If past scheduled date, check if review was completed after the scheduled time
        if let lastReview = lastReviewDate {
            return lastReview < scheduledDate
        }

        // Never reviewed, and we're past the scheduled time
        return true
    }
}
