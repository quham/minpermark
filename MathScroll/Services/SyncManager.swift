import Foundation
import Network

// MARK: - Sync Manager

@MainActor
@Observable
final class SyncManager {
    static let shared = SyncManager()
    private init() {}
}

extension SyncManager {
    func push(attempt: QuestionAttempt, userId: UUID) async throws {
        struct Row: Encodable {
            let id: String; let user_id: String; let question_id: String; let submitted_at: String
            let marks_awarded: Int; let total_marks: Int; let criterion_results: [CriterionResult]
            let skills_correct: [String]; let skills_incorrect: [String]
            let improvement_tip: String; let seconds_spent: Int; let marking_mode: String
        }
        let iso = ISO8601DateFormatter().string(from: attempt.submittedAt)
        let row = Row(
            id: attempt.id.uuidString, user_id: userId.uuidString, question_id: attempt.questionId,
            submitted_at: iso, marks_awarded: attempt.marksAwarded, total_marks: attempt.totalMarks,
            criterion_results: attempt.criterionResults, skills_correct: attempt.skillsCorrect,
            skills_incorrect: attempt.skillsIncorrect, improvement_tip: attempt.improvementTip,
            seconds_spent: attempt.secondsSpent, marking_mode: attempt.markingMode.rawValue
        )
        try await SupabaseManager.shared.client.from("attempts").insert(row).execute()
    }

    func push(skillStat: SkillStat, userId: UUID) async throws {
        struct Row: Encodable {
            let user_id: String; let tag: String; let kind: String
            let attempts_count: Int; let marks_scored: Int; let marks_possible: Int
            let recency_weighted_pct: Double; let last_attempted_at: String
        }
        let row = Row(
            user_id: userId.uuidString, tag: skillStat.tag, kind: skillStat.kindRaw,
            attempts_count: skillStat.attemptsCount, marks_scored: skillStat.marksScored,
            marks_possible: skillStat.marksPossible,
            recency_weighted_pct: skillStat.recencyWeightedPct,
            last_attempted_at: ISO8601DateFormatter().string(from: skillStat.lastAttemptedAt)
        )
        try await SupabaseManager.shared.client.from("skill_stats").upsert(row).execute()
    }
}
