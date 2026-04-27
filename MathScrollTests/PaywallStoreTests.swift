import XCTest
@testable import MathScroll

@MainActor
final class PaywallStoreTests: XCTestCase {
    func testActiveEntitlementGrantsAccess() async {
        let svc = EntitlementsService(loader: { @Sendable in
            Entitlement(productId: "mathscroll.weekly", expiresAt: .distantFuture, isActive: true)
        })
        let store = PaywallStore(entitlements: svc)
        await store.refresh()
        XCTAssertTrue(store.hasAccess)
    }

    func testNoEntitlementBlocks() async {
        let svc = EntitlementsService(loader: { @Sendable in nil as Entitlement? })
        let store = PaywallStore(entitlements: svc)
        await store.refresh()
        XCTAssertFalse(store.hasAccess)
    }
}
