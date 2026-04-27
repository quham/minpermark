import Foundation
import StoreKit

@MainActor
final class EntitlementsService {
    private let loader: @Sendable () async -> Entitlement?
    init(loader: @escaping @Sendable () async -> Entitlement?) { self.loader = loader }

    convenience init() {
        self.init(loader: {
            for await result in Transaction.currentEntitlements {
                if case .verified(let t) = result, t.expirationDate.map({ $0 > .now }) ?? false {
                    return Entitlement(productId: t.productID,
                                       expiresAt: t.expirationDate ?? .distantFuture,
                                       isActive: true)
                }
            }
            return nil
        })
    }

    func current() async -> Entitlement? { await loader() }
}
