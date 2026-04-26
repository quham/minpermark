import SwiftUI
import SwiftData

// MARK: - Goals Store

/// Manages goal persistence and CRUD operations
@MainActor
@Observable
class GoalsStore {
    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - CRUD Operations

    func addGoal(_ goal: Goal) {
        modelContext.insert(goal)
        modelContext.safeSave()
        ShieldSharedStore.shared.updateFromGoal(goal)
    }

    func deleteGoal(_ goal: Goal) {
        modelContext.delete(goal)
        modelContext.safeSave()
    }

    func archiveGoal(_ goal: Goal) {
        goal.isArchived = true
        modelContext.safeSave()
        AnalyticsService.shared.capture(Constants.AnalyticsEvents.goalArchived, properties: [
            Constants.AnalyticsProperties.goalId: goal.id.uuidString
        ])
    }

    func updateGoal(_ goal: Goal) {
        modelContext.safeSave()
        ShieldSharedStore.shared.updateFromGoal(goal)
    }

    // MARK: - Goal Completion

    func completeGoal(_ goal: Goal, minutesEarned: Int = 10, proofs: [ProofItem] = []) -> CompletionRecord {
        let record = CompletionRecord(
            minutesEarned: minutesEarned,
            verificationStatus: .pending,
            goal: goal
        )

        record.proofs = proofs
        goal.lastCompletedAt = Date()

        modelContext.insert(record)
        modelContext.safeSave()

        return record
    }

    // MARK: - Fetch Operations

    func fetchActiveGoals() -> [Goal] {
        let descriptor = FetchDescriptor<Goal>(
            predicate: #Predicate { !$0.isArchived },
            sortBy: [SortDescriptor(\.importance, order: .reverse), SortDescriptor(\.createdAt)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            Log.data.error("Failed to fetch goals: \(error.localizedDescription)")
            return []
        }
    }

    func fetchTodayCompletions() -> [CompletionRecord] {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<CompletionRecord>(
            predicate: #Predicate { $0.date >= startOfDay },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            Log.data.error("Failed to fetch completions: \(error.localizedDescription)")
            return []
        }
    }

    func getAnchorGoal() -> Goal? {
        let goals = fetchActiveGoals()
        return goals.max(by: { $0.importance < $1.importance })
    }
}

// Note: VerificationStore has been moved to Stores/VerificationStore.swift
