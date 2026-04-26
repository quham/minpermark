import XCTest
import SwiftData
@testable import MathScroll

final class QuestionAttemptTests: XCTestCase {
    func testAttemptStoresMarksAndCriteria() throws {
        let container = try ModelContainer(
            for: QuestionAttempt.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let crit = [
            CriterionResult(criterionId: "M1", awarded: 1, max: 1, rationale: "ok"),
            CriterionResult(criterionId: "A1", awarded: 0, max: 1, rationale: "missed simplification")
        ]
        let a = QuestionAttempt(
            questionId: "q-001",
            imageData: Data([0x01]),
            marksAwarded: 1,
            totalMarks: 2,
            criterionResults: crit,
            skillsCorrect: ["substitute_into_quadratic"],
            skillsIncorrect: ["simplify_surd"],
            improvementTip: "rationalise the denominator",
            secondsSpent: 120,
            markingMode: .ai
        )
        context.insert(a)
        try context.save()
        XCTAssertEqual(a.criterionResults.count, 2)
        XCTAssertEqual(a.criterionResults.first?.criterionId, "M1")
        XCTAssertEqual(a.markingMode, .ai)
    }
}
