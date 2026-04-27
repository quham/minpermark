import Foundation
import StoreKit

@MainActor
@Observable
final class PaywallStore {
    private let entitlements: EntitlementsService
    private(set) var entitlement: Entitlement?
    private(set) var products: [Product] = []

    init(entitlements: EntitlementsService) { self.entitlements = entitlements }

    var hasAccess: Bool { entitlement?.isActive == true }

    func refresh() async {
        entitlement = await entitlements.current()
    }

    func loadProducts() async {
        do {
            products = try await Product.products(for: ["mathscroll.weekly", "mathscroll.monthly", "mathscroll.annual"])
        } catch { products = [] }
    }

    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        if case .success(.verified(let tx)) = result {
            await tx.finish()
            entitlement = await entitlements.current()
            return true
        }
        return false
    }

    func restore() async {
        try? await AppStore.sync()
        entitlement = await entitlements.current()
    }
}
