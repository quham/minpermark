import Foundation
import SwiftData

@Model
final class UserProfile {
    var level: ExamLevel = ExamLevel.gcse
    var board: ExamBoard = ExamBoard.edexcel
    var tier: Tier? = Tier.higher
    var dailyCapMinutes: Int = 120
    var blockedAppTokens: Data?
    private var entitlementJSON: Data?
    var onboardingDone: Bool = false
    var paywallSeen: Bool = false
    var freeQuestionUsed: Bool = false

    init() {}

    var entitlement: Entitlement? {
        get {
            guard let data = entitlementJSON else { return nil }
            return try? JSONDecoder().decode(Entitlement.self, from: data)
        }
        set {
            entitlementJSON = newValue.flatMap { try? JSONEncoder().encode($0) }
        }
    }
}
