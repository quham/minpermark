import XCTest
@testable import MathScroll

@MainActor
final class QuestionBankStoreTests: XCTestCase {
    func testNextQuestionReturnsRecommendedFromBank() async throws {
        let svc = QuestionBankService(transport: StubBankTransport(rows: [
            Question.fixture(id: "q-1", level: .gcse, board: .edexcel)
        ]))
        let store = QuestionBankStore(service: svc, recommender: QuestionRecommender(rng: DeterministicRNG(seed: 1)))
        let q = try await store.nextQuestion(level: .gcse, board: .edexcel, tier: .higher,
                                             stats: [], recentAttempts: [], lastSubtopics: [])
        XCTAssertEqual(q?.id, "q-1")
    }
}
