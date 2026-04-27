import XCTest
@testable import MathScroll

final class WeeklyDigestServiceTests: XCTestCase {
    func testTopThreeWeakSkillsFromAttempts() {
        let s1 = SkillStat(tag: "a", kind: .skill); s1.attemptsCount = 5; s1.recencyWeightedPct = 30
        let s2 = SkillStat(tag: "b", kind: .skill); s2.attemptsCount = 5; s2.recencyWeightedPct = 40
        let s3 = SkillStat(tag: "c", kind: .skill); s3.attemptsCount = 5; s3.recencyWeightedPct = 50
        let s4 = SkillStat(tag: "d", kind: .skill); s4.attemptsCount = 5; s4.recencyWeightedPct = 80
        let svc = WeeklyDigestService()
        let top = svc.topWeak(stats: [s4, s3, s2, s1], limit: 3)
        XCTAssertEqual(top.map(\.tag), ["a", "b", "c"])
    }
}
