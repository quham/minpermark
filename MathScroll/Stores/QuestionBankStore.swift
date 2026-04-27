import Foundation

@MainActor
@Observable
final class QuestionBankStore {
    private let service: QuestionBankService
    private var recommender: QuestionRecommender
    private var cache: [String: [Question]] = [:]

    init(service: QuestionBankService, recommender: QuestionRecommender) {
        self.service = service
        self.recommender = recommender
    }

    func nextQuestion(
        level: ExamLevel,
        board: ExamBoard,
        tier: Tier?,
        stats: [SkillStat],
        recentAttempts: [RecentAttempt],
        lastSubtopics: [String]
    ) async throws -> Question? {
        let key = "\(level.rawValue)-\(board.rawValue)-\(tier?.rawValue ?? "any")"
        let pool: [Question]
        if let cached = cache[key] { pool = cached }
        else {
            pool = try await service.fetchAvailable(level: level, board: board, tier: tier)
            cache[key] = pool
        }
        return recommender.pick(from: pool, stats: stats, recentAttempts: recentAttempts, lastSubtopics: lastSubtopics)
    }

    func clearCache() { cache.removeAll() }
}
