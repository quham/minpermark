import Foundation
import SwiftData

@MainActor
@Observable
final class StatsStore {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }

    func apply(attempt: QuestionAttempt, totalMarks: Int) {
        let pct = totalMarks == 0 ? 0 : Double(attempt.marksAwarded) / Double(totalMarks)
        for tag in attempt.skillsCorrect {
            updateStat(tag: tag, kind: .skill, scored: totalMarks, possible: totalMarks, sessionPct: pct)
        }
        for tag in attempt.skillsIncorrect {
            updateStat(tag: tag, kind: .skill, scored: 0, possible: totalMarks, sessionPct: pct)
        }
        try? context.save()
    }

    private func updateStat(tag: String, kind: SkillStatKind, scored: Int, possible: Int, sessionPct: Double) {
        let key = "\(kind.rawValue):\(tag)"
        let existing = try? context.fetch(FetchDescriptor<SkillStat>(
            predicate: #Predicate<SkillStat> { $0.compositeKey == key }
        )).first
        let stat = existing ?? {
            let s = SkillStat(tag: tag, kind: kind)
            context.insert(s)
            return s
        }()
        stat.attemptsCount += 1
        stat.marksScored += scored
        stat.marksPossible += possible
        let alpha = 0.4
        stat.recencyWeightedPct = stat.attemptsCount == 1
            ? sessionPct * 100
            : (1 - alpha) * stat.recencyWeightedPct + alpha * sessionPct * 100
        stat.lastAttemptedAt = .now
    }

    func weaknessRanking(limit: Int) -> [SkillStat] {
        let descriptor = FetchDescriptor<SkillStat>(
            predicate: #Predicate<SkillStat> { $0.attemptsCount >= 1 },
            sortBy: [SortDescriptor(\.recencyWeightedPct, order: .forward)]
        )
        let all = (try? context.fetch(descriptor)) ?? []
        return Array(all.prefix(limit))
    }
}
