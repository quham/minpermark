import XCTest
@testable import MathScroll

@MainActor
final class AppStateTests: XCTestCase {
    func testRouteIsOnboardingWhenNotDone() {
        let s = AppState()
        s.profile = UserProfile()
        XCTAssertEqual(s.route, .onboarding)
    }

    func testRouteIsPaywallWhenFreeUsedAndNoEntitlement() {
        let s = AppState()
        let p = UserProfile(); p.onboardingDone = true; p.freeQuestionUsed = true
        s.profile = p
        XCTAssertEqual(s.route, .paywall)
    }

    func testRouteIsHomeWhenEntitled() {
        let s = AppState()
        let p = UserProfile()
        p.onboardingDone = true
        p.freeQuestionUsed = true
        p.entitlement = Entitlement(productId: "x", expiresAt: .distantFuture, isActive: true)
        s.profile = p
        XCTAssertEqual(s.route, .home)
    }
}
