import Foundation
import SwiftData

// MARK: - Completion Record Model

/// Represents a completed habit check-in with verification status
@Model
final class CompletionRecord {

    // MARK: - Properties

    var id: UUID
    var date: Date
    var completedAt: Date
    var minutesEarned: Int
    var notes: String?
    var verificationStatus: VerificationStatus
    var verificationConfidence: Double?
    var verificationReason: String?
    var verifiedAt: Date?

    // MARK: - Relationships

    var goal: Goal?

    @Relationship(deleteRule: .cascade)
    var proofs: [ProofItem]?

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        date: Date = Calendar.current.startOfDay(for: Date()),
        completedAt: Date = Date(),
        minutesEarned: Int = 10,
        notes: String? = nil,
        verificationStatus: VerificationStatus = .pending,
        verificationConfidence: Double? = nil,
        verificationReason: String? = nil,
        verifiedAt: Date? = nil,
        goal: Goal? = nil
    ) {
        self.id = id
        self.date = date
        self.completedAt = completedAt
        self.minutesEarned = minutesEarned
        self.notes = notes
        self.verificationStatus = verificationStatus
        self.verificationConfidence = verificationConfidence
        self.verificationReason = verificationReason
        self.verifiedAt = verifiedAt
        self.goal = goal
    }
}

// MARK: - Verification Status

/// Status of proof verification for a completion record
enum VerificationStatus: String, Codable {
    case pending = "pending"
    case passed = "passed"
    case failed = "failed"
    case uncertain = "uncertain"

    // MARK: - Display Properties

    var displayText: String {
        switch self {
        case .pending: return LocalizedStrings.verifying
        case .passed: return LocalizedStrings.verified
        case .failed: return LocalizedStrings.tryAgain
        case .uncertain: return LocalizedStrings.underReview
        }
    }

    var color: String {
        switch self {
        case .pending: return "orange"
        case .passed: return "green"
        case .failed: return "red"
        case .uncertain: return "yellow"
        }
    }
}
