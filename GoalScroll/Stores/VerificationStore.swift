import SwiftUI
import SwiftData

// MARK: - Verification Store

@MainActor
@Observable
final class VerificationStore {
    private(set) var statusByGoalID: [UUID: VerificationStatus] = [:]

    private let geminiService: any GeminiServiceProtocol

    init(geminiService: (any GeminiServiceProtocol)? = nil) {
        self.geminiService = geminiService ?? GeminiService()
    }

    // MARK: - Public Methods

    func status(for goal: Goal) -> VerificationStatus? {
        statusByGoalID[goal.id]
    }

    func verify(record: CompletionRecord, goal: Goal, modelContext: ModelContext, stats: UserStats?) {
        guard let proofs = record.proofs, !proofs.isEmpty else {
            applyLocalFailure(
                reason: LocalizedStrings.proofRequired,
                record: record,
                goal: goal,
                modelContext: modelContext
            )
            return
        }

        if let rejectionReason = proofRejectionReason(for: proofs) {
            applyLocalFailure(
                reason: rejectionReason,
                record: record,
                goal: goal,
                modelContext: modelContext
            )
            return
        }

        statusByGoalID[goal.id] = .pending
        AnalyticsService.shared.capture(Constants.AnalyticsEvents.verificationStarted, properties: [
            Constants.AnalyticsProperties.goalId: goal.id.uuidString
        ])

        Task {
            let result: VerificationResult
            do {
                result = try await geminiService.verifyProof(goal: goal, proofItems: proofs)
            } catch {
                result = VerificationResult(status: .passed, reason: LocalizedStrings.networkError)
            }

            if result.status == .passed {
                stats?.addMinutes(record.minutesEarned)
            }

            record.verificationStatus = result.status
            record.verificationConfidence = result.confidence
            record.verificationReason = result.reason
            record.verifiedAt = result.verifiedAt
            statusByGoalID[goal.id] = result.status

            AnalyticsService.shared.capture(Constants.AnalyticsEvents.verificationStatus, properties: [
                Constants.AnalyticsProperties.goalId: goal.id.uuidString,
                Constants.AnalyticsProperties.verificationResult: result.status.rawValue,
                Constants.AnalyticsProperties.confidence: result.confidence ?? 0.0,
                "is_network_error": result.reason == LocalizedStrings.networkError
            ])

            try? modelContext.save()
        }
    }

    // MARK: - Private Methods

    private func applyLocalFailure(
        reason: String,
        record: CompletionRecord,
        goal: Goal,
        modelContext: ModelContext
    ) {
        record.verificationStatus = .failed
        record.verificationReason = reason
        record.verifiedAt = Date()
        statusByGoalID[goal.id] = .failed
        try? modelContext.save()
    }

    private func proofRejectionReason(for proofs: [ProofItem]) -> String? {
        // Screenshot timestamp validation is handled at the UI layer in ProofCaptureView
        return nil
    }
}
