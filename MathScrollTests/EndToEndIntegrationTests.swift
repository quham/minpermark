import XCTest
import SwiftData
@testable import MathScroll

@MainActor
final class EndToEndIntegrationTests: XCTestCase {
    func testFullAttemptUpdatesStatsAndMinutes() async throws {
        let container = try ModelContainer(
            for: UserProfile.self, QuestionAttempt.self, SkillStat.self, MinutesLedger.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let profile = UserProfile()
        context.insert(profile); try context.save()

        let q = Question.fixture(id: "q-1", level: .gcse, board: .edexcel)
        let imageData = Data([0x01])
        let stubResult = MarkingResult(
            totalAwarded: 3, totalPossible: 4,
            criteria: [CriterionResult(criterionId: "M1", awarded: 1, max: 1, rationale: "ok")],
            skillsCorrect: ["substitute"], skillsIncorrect: ["simplify"],
            improvementTip: "rationalise"
        )
        let stub = StubMarkingTransport(rawResponses: [(try? JSONEncoder().encode(stubResult)) ?? Data()])
        let svc = MarkingService(transport: stub)
        let store = MarkingStore(service: svc)
        await store.mark(question: q, studentImage: imageData)
        guard case .result(let r) = store.state else { return XCTFail("expected .result") }

        let attempt = QuestionAttempt(
            questionId: q.id, imageData: imageData,
            marksAwarded: r.totalAwarded, totalMarks: r.totalPossible,
            criterionResults: r.criteria, skillsCorrect: r.skillsCorrect,
            skillsIncorrect: r.skillsIncorrect, improvementTip: r.improvementTip,
            secondsSpent: 60, markingMode: .ai
        )
        context.insert(attempt); try context.save()

        let stats = StatsStore(context: context)
        stats.apply(attempt: attempt, totalMarks: r.totalPossible)
        XCTAssertGreaterThan(stats.weaknessRanking(limit: 5).count, 0)

        let minutes = MinutesStore(context: context, dailyCapMinutes: 120)
        minutes.earn(minutes: r.totalAwarded)
        XCTAssertEqual(minutes.balance, 3)
    }
}
