import XCTest
@testable import MathScroll

final class QuestionBankServiceTests: XCTestCase {
    func testFetchByFiltersReturnsDecodedQuestions() async throws {
        let stub = StubBankTransport(rows: [
            Question.fixture(id: "q-1", level: .gcse, board: .edexcel)
        ])
        let svc = QuestionBankService(transport: stub)
        let result = try await svc.fetchAvailable(level: .gcse, board: .edexcel, tier: .higher)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, "q-1")
    }
}

struct StubBankTransport: QuestionBankTransport {
    let rows: [Question]
    func fetch(level: ExamLevel, board: ExamBoard, tier: Tier?) async throws -> [Question] { rows }
}

extension Question {
    static func fixture(id: String, level: ExamLevel, board: ExamBoard) -> Question {
        Question(
            id: id, board: board, level: level, tier: .higher,
            paperYear: 2023, paperCode: "1H", questionNumber: "5",
            questionImageURL: URL(string: "https://example.com/q.png")!,
            markSchemeImageURL: URL(string: "https://example.com/ms.png")!,
            totalMarks: 4, subtopicTags: ["quadratics"], skillTags: ["complete_the_square"],
            difficulty: 3
        )
    }
}
