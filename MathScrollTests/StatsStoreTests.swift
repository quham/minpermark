import XCTest
import SwiftData
@testable import MathScroll

@MainActor
final class StatsStoreTests: XCTestCase {
    func testApplyAttemptUpdatesSkillStats() throws {
        let container = try ModelContainer(
            for: SkillStat.self, QuestionAttempt.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let store = StatsStore(context: context)

        let attempt = QuestionAttempt(
            questionId: "q-1", imageData: Data(), marksAwarded: 1, totalMarks: 2,
            criterionResults: [], skillsCorrect: ["substitute"], skillsIncorrect: ["simplify_surd"],
            improvementTip: "", secondsSpent: 60, markingMode: .ai
        )
        context.insert(attempt)
        try context.save()
        store.apply(attempt: attempt, totalMarks: 2)

        let stats = try context.fetch(FetchDescriptor<SkillStat>())
        XCTAssertEqual(stats.count, 2)
        let simplify = stats.first(where: { $0.tag == "simplify_surd" })!
        XCTAssertEqual(simplify.attemptsCount, 1)
        XCTAssertEqual(simplify.marksScored, 0)
        XCTAssertEqual(simplify.marksPossible, 2)
    }

    func testWeaknessRankingOrdersByLowestPercentageFirst() throws {
        let container = try ModelContainer(
            for: SkillStat.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let s1 = SkillStat(tag: "a", kind: .skill); s1.attemptsCount = 5; s1.recencyWeightedPct = 30
        let s2 = SkillStat(tag: "b", kind: .skill); s2.attemptsCount = 5; s2.recencyWeightedPct = 80
        context.insert(s1); context.insert(s2); try context.save()
        let store = StatsStore(context: context)
        let weakest = store.weaknessRanking(limit: 5)
        XCTAssertEqual(weakest.first?.tag, "a")
    }
}
