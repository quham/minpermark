import XCTest
import SwiftData
@testable import MathScroll

final class SkillStatTests: XCTestCase {
    func testNewStatHasZeroPercentages() {
        let s = SkillStat(tag: "differentiate_chain_rule", kind: .skill)
        XCTAssertEqual(s.recencyWeightedPct, 0)
        XCTAssertEqual(s.attemptsCount, 0)
    }
}
