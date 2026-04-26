import Foundation

struct Entitlement: Codable, Hashable {
    var productId: String
    var expiresAt: Date
    var isActive: Bool
}
