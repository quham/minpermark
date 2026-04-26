import Foundation

struct RecentAttempt {
    let questionId: String
    let at: Date
}

struct QuestionRecommender {
    var rng: any RandomNumberGenerator

    /// Picks the next question from `pool`, applying:
    ///   - filter: questions attempted within 30 days are excluded
    ///   - filter: if the last 5 picks were all the same subtopic, must switch
    ///   - weighting: 60% weak, 30% improving, 10% coverage
    mutating func pick(
        from pool: [Question],
        stats: [SkillStat],
        recentAttempts: [RecentAttempt],
        lastSubtopics: [String]
    ) -> Question? {
        let cutoff = Date().addingTimeInterval(-30 * 24 * 3600)
        let recentIds = Set(recentAttempts.filter { $0.at >= cutoff }.map(\.questionId))
        var candidates = pool.filter { !recentIds.contains($0.id) }

        if lastSubtopics.count >= 5,
           Set(lastSubtopics.suffix(5)).count == 1,
           let stuckSubtopic = lastSubtopics.last {
            candidates = candidates.filter { !$0.subtopicTags.contains(stuckSubtopic) }
        }

        guard !candidates.isEmpty else { return nil }

        let weakSkills = Set(
            stats
                .filter { $0.kind == .skill && $0.attemptsCount >= 2 && $0.recencyWeightedPct < 60 }
                .map(\.tag)
        )
        let improvingSkills = improvingSkillTags(from: stats)

        let weakBucket = candidates.filter { !weakSkills.intersection($0.skillTags).isEmpty }
        let improvingBucket = candidates.filter { !improvingSkills.intersection($0.skillTags).isEmpty }
        let coverageBucket = candidates.filter {
            $0.skillTags.allSatisfy { tag in
                !stats.contains(where: { $0.tag == tag && $0.attemptsCount > 0 })
            }
        }

        let r = Double.random(in: 0..<1, using: &rng)
        if r < 0.60, let q = weakBucket.randomElement(using: &rng) { return q }
        if r < 0.90, let q = improvingBucket.randomElement(using: &rng) { return q }
        if let q = coverageBucket.randomElement(using: &rng) { return q }
        return candidates.randomElement(using: &rng)
    }

    private func improvingSkillTags(from stats: [SkillStat]) -> Set<String> {
        Set(
            stats
                .filter { $0.kind == .skill && $0.attemptsCount >= 3 && (60..<85).contains($0.recencyWeightedPct) }
                .map(\.tag)
        )
    }
}
