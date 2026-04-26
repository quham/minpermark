import SwiftUI
import SwiftData

@MainActor
@Observable
class StatsStore {
    private var modelContext: ModelContext
    private(set) var stats: UserStats?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadOrCreateStats()
    }

    private func loadOrCreateStats() {
        let descriptor = FetchDescriptor<UserStats>()

        do {
            let existingStats = try modelContext.fetch(descriptor)
            if let existing = existingStats.first {
                existing.resetForNewDay()
                stats = existing
            } else {
                let newStats = UserStats()
                modelContext.insert(newStats)
                modelContext.safeSave()
                stats = newStats
            }
        } catch {
            Log.data.error("Failed to load stats: \(error.localizedDescription)")
            let newStats = UserStats()
            modelContext.insert(newStats)
            modelContext.safeSave()
            stats = newStats
        }
    }

    func addMinutes(_ minutes: Int) {
        stats?.addMinutes(minutes)
        modelContext.safeSave()
    }

    func deductMinutes(_ minutes: Int) {
        stats?.deductMinutes(minutes)
        modelContext.safeSave()
    }

    func setAnchorGoal(_ goalID: UUID?) {
        stats?.anchorGoalID = goalID
        modelContext.safeSave()
    }

    var todayMinutes: Int {
        stats?.todayMinutesEarned ?? 0
    }

    var lifetimeMinutes: Int {
        stats?.lifetimeMinutesEarned ?? 0
    }

    var currentStreak: Int {
        stats?.currentStreakDays ?? 0
    }

    var dailyTarget: Int {
        stats?.dailyMinutesTarget ?? Constants.Defaults.dailyMinutesTarget
    }

    func setDailyTarget(_ target: Int) {
        stats?.dailyMinutesTarget = target
        try? modelContext.save()
    }

    var progress: Double {
        stats?.progressPercentage ?? 0
    }
}
