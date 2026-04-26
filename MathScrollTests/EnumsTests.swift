import XCTest
@testable import MathScroll

final class EnumsTests: XCTestCase {
    func testExamLevelHasGCSEASAndALevel() {
        XCTAssertEqual(ExamLevel.allCases, [.gcse, .asLevel, .aLevel])
    }

    func testExamBoardHasThreeUKBoards() {
        XCTAssertEqual(ExamBoard.allCases, [.edexcel, .aqa, .ocr])
    }

    func testTierAppliesOnlyToGCSE() {
        XCTAssertEqual(Tier.allCases, [.foundation, .higher])
    }

    func testMarkingModeDistinguishesAIFromSelfMark() {
        XCTAssertNotEqual(MarkingMode.ai, MarkingMode.selfMark)
    }
}
