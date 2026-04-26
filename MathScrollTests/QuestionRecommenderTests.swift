import XCTest
@testable import MathScroll

final class QuestionRecommenderTests: XCTestCase {
    func testFiltersOutAttemptedWithin30Days() {
        let pool = [Question.fixture(id: "q-1", level: .gcse, board: .edexcel)]
        let recent = [RecentAttempt(questionId: "q-1", at: Date().addingTimeInterval(-3600))]
        var rec = QuestionRecommender(rng: DeterministicRNG(seed: 1))
        let pick = rec.pick(from: pool, stats: [], recentAttempts: recent, lastSubtopics: [])
        XCTAssertNil(pick, "must exclude questions attempted in last 30 days")
    }

    func testForcesSubtopicChangeAfter5StreakOnSameSubtopic() {
        let q1 = Question.fixture(id: "q-quad", level: .gcse, board: .edexcel)
        let q2 = Question(
            id: "q-other", board: .edexcel, level: .gcse, tier: .higher,
            paperYear: 2023, paperCode: "1H", questionNumber: "6",
            questionImageURL: q1.questionImageURL, markSchemeImageURL: q1.markSchemeImageURL,
            totalMarks: 4, subtopicTags: ["calculus"], skillTags: ["differentiate_polynomial"],
            difficulty: 3
        )
        var rec = QuestionRecommender(rng: DeterministicRNG(seed: 1))
        let pick = rec.pick(
            from: [q1, q2],
            stats: [],
            recentAttempts: [],
            lastSubtopics: Array(repeating: "quadratics", count: 5)
        )
        XCTAssertEqual(pick?.id, "q-other", "after 5 quadratics, must switch subtopic")
    }
}

struct DeterministicRNG: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { self.state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
