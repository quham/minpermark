import XCTest
import SwiftData
@testable import MathScroll

final class UserProfileTests: XCTestCase {
    func testNewProfileHasDefaultDailyCap120() throws {
        let container = try ModelContainer(
            for: UserProfile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let profile = UserProfile()
        context.insert(profile)
        try context.save()
        XCTAssertEqual(profile.dailyCapMinutes, 120)
        XCTAssertFalse(profile.onboardingDone)
        XCTAssertFalse(profile.freeQuestionUsed)
        XCTAssertNil(profile.entitlement)
    }
}
