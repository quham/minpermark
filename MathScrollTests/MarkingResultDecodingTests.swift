import XCTest
@testable import MathScroll

final class MarkingResultDecodingTests: XCTestCase {
    func testDecodesValidJSON() throws {
        let json = """
        {
          "totalAwarded": 4,
          "totalPossible": 6,
          "criteria": [
            {"criterionId":"M1","awarded":1,"max":1,"rationale":"ok"}
          ],
          "skillsCorrect": ["a"],
          "skillsIncorrect": ["b"],
          "improvementTip": "tip"
        }
        """.data(using: .utf8)!
        let r = try JSONDecoder().decode(MarkingResult.self, from: json)
        XCTAssertEqual(r.totalAwarded, 4)
        XCTAssertEqual(r.criteria.count, 1)
    }

    func testRejectsMissingFields() {
        let json = "{}".data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(MarkingResult.self, from: json))
    }
}
