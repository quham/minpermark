import Foundation
import SwiftData
import Network
import Auth

// MARK: - Sync Status

enum SyncStatus: Equatable {
    case idle
    case syncing
    case completed
    case failed(String)
    case offline
}

// MARK: - Sync Manager

/// Manages local-first sync between SwiftData and Supabase
@MainActor
@Observable
final class SyncManager {
    static let shared = SyncManager()

    // MARK: - State

    private(set) var isSyncing = false
    private(set) var lastSyncDate: Date?
    private(set) var syncStatus: SyncStatus = .idle

    // MARK: - Network Monitoring

    private let networkMonitor = NWPathMonitor()
    private var isOnline = false

    // MARK: - Initialization

    private init() {
        lastSyncDate = UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.lastSyncDate) as? Date
        setupNetworkMonitoring()
    }

    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                let wasOffline = self?.isOnline == false
                self?.isOnline = path.status == .satisfied

                // Trigger sync when coming back online
                if wasOffline && self?.isOnline == true {
                    Log.network.info("Network restored, triggering sync")
                }
            }
        }
        networkMonitor.start(queue: DispatchQueue.global(qos: .utility))
    }

    // MARK: - Full Sync

    /// Performs a full sync: push local changes, then pull server changes
    func performFullSync(modelContext: ModelContext) async {
        guard SupabaseManager.shared.isAuthenticated else {
            Log.network.debug("Not authenticated, skipping sync")
            return
        }

        guard isOnline else {
            syncStatus = .offline
            Log.network.debug("Offline, skipping sync")
            return
        }

        guard !isSyncing else {
            Log.network.debug("Sync already in progress")
            return
        }

        isSyncing = true
        syncStatus = .syncing

        do {
            // 1. Push local goals to server
            try await pushGoals(modelContext: modelContext)

            // 2. Push local stats to server
            try await pushStats(modelContext: modelContext)

            // 3. Pull goals from server
            try await pullGoals(modelContext: modelContext)

            // 4. Pull stats from server
            try await pullStats(modelContext: modelContext)

            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate, forKey: Constants.UserDefaultsKeys.lastSyncDate)
            syncStatus = .completed

            Log.network.info("Sync completed successfully")

        } catch {
            Log.network.error("Sync failed: \(error.localizedDescription)")
            syncStatus = .failed(error.localizedDescription)
        }

        isSyncing = false
    }

    // MARK: - Push Goals

    private func pushGoals(modelContext: ModelContext) async throws {
        guard let userId = SupabaseManager.shared.userId else { return }

        // Fetch all non-deleted local goals
        let descriptor = FetchDescriptor<Goal>(
            predicate: #Predicate { !$0.isArchived }
        )
        let localGoals = try modelContext.fetch(descriptor)

        for goal in localGoals {
            let dto = GoalUpsertDTO(from: goal, userId: userId)

            // Upsert using local_id for conflict detection
            try await SupabaseManager.shared.client
                .from("goals")
                .upsert(dto, onConflict: "local_id,user_id")
                .execute()
        }

        // Also push archived goals (soft delete)
        let archivedDescriptor = FetchDescriptor<Goal>(
            predicate: #Predicate { $0.isArchived }
        )
        let archivedGoals = try modelContext.fetch(archivedDescriptor)

        for goal in archivedGoals {
            let dto = GoalUpsertDTO(from: goal, userId: userId)

            try await SupabaseManager.shared.client
                .from("goals")
                .upsert(dto, onConflict: "local_id,user_id")
                .execute()
        }

        Log.network.debug("Pushed \(localGoals.count + archivedGoals.count) goals")
    }

    // MARK: - Push Stats

    private func pushStats(modelContext: ModelContext) async throws {
        guard let userId = SupabaseManager.shared.userId else { return }

        let descriptor = FetchDescriptor<UserStats>()
        guard let stats = try modelContext.fetch(descriptor).first else { return }

        let dto = UserStatsUpsertDTO(from: stats, userId: userId)

        try await SupabaseManager.shared.client
            .from("user_stats")
            .upsert(dto, onConflict: "user_id")
            .execute()

        Log.network.debug("Pushed user stats")
    }

    // MARK: - Pull Goals

    private func pullGoals(modelContext: ModelContext) async throws {
        guard let userId = SupabaseManager.shared.userId else { return }

        // Fetch goals from server
        let remoteGoals: [GoalDTO] = try await SupabaseManager.shared.client
            .from("goals")
            .select()
            .eq("user_id", value: userId.uuidString)
            .is("deleted_at", value: nil)
            .execute()
            .value

        for remoteGoal in remoteGoals {
            // Check if exists locally by local_id
            if let localId = remoteGoal.localId {
                let descriptor = FetchDescriptor<Goal>(
                    predicate: #Predicate { $0.id == localId }
                )

                let results = try modelContext.fetch(descriptor)
                if let existingGoal = results.first {
                    // Update existing goal from server
                    // Last-write-wins: server wins if updated more recently
                    if let serverUpdated = remoteGoal.updatedAt,
                       serverUpdated > existingGoal.createdAt {
                        remoteGoal.updateGoal(existingGoal)
                    }
                } else {
                    // Goal exists on server but not locally - create it
                    let newGoal = remoteGoal.toGoal()
                    modelContext.insert(newGoal)
                }
            } else {
                // No local_id means this was created on another device
                // Check by server ID
                let descriptor = FetchDescriptor<Goal>(
                    predicate: #Predicate { $0.id == remoteGoal.id }
                )

                if try modelContext.fetch(descriptor).first == nil {
                    let newGoal = remoteGoal.toGoal()
                    modelContext.insert(newGoal)
                }
            }
        }

        modelContext.safeSave()
        Log.network.debug("Pulled \(remoteGoals.count) goals from server")
    }

    // MARK: - Pull Stats

    private func pullStats(modelContext: ModelContext) async throws {
        guard let userId = SupabaseManager.shared.userId else { return }

        // Fetch stats from server
        let remoteStats: [UserStatsDTO] = try await SupabaseManager.shared.client
            .from("user_stats")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        guard let remoteDTO = remoteStats.first else {
            Log.network.debug("No remote stats found")
            return
        }

        // Get or create local stats
        let descriptor = FetchDescriptor<UserStats>()
        if let localStats = try modelContext.fetch(descriptor).first {
            // Merge with conflict resolution
            remoteDTO.updateStats(localStats)
        } else {
            // Create new local stats from server
            let newStats = remoteDTO.toUserStats()
            modelContext.insert(newStats)
        }

        modelContext.safeSave()
        Log.network.debug("Pulled and merged user stats")
    }

    // MARK: - Single Goal Sync

    /// Sync a single goal immediately (after creation or update)
    func syncGoal(_ goal: Goal) async {
        guard SupabaseManager.shared.isAuthenticated,
              let userId = SupabaseManager.shared.userId,
              isOnline else { return }

        do {
            let dto = GoalUpsertDTO(from: goal, userId: userId)

            try await SupabaseManager.shared.client
                .from("goals")
                .upsert(dto, onConflict: "local_id,user_id")
                .execute()

            Log.network.debug("Synced goal: \(goal.title)")
        } catch {
            Log.network.error("Failed to sync goal: \(error.localizedDescription)")
        }
    }

    // MARK: - Delete Goal Sync

    /// Mark a goal as deleted on server (soft delete)
    func syncGoalDeletion(_ goalId: UUID) async {
        guard SupabaseManager.shared.isAuthenticated,
              let userId = SupabaseManager.shared.userId,
              isOnline else { return }

        do {
            try await SupabaseManager.shared.client
                .from("goals")
                .update(["deleted_at": Date().ISO8601Format()])
                .eq("local_id", value: goalId.uuidString)
                .eq("user_id", value: userId.uuidString)
                .execute()

            Log.network.debug("Synced goal deletion")
        } catch {
            Log.network.error("Failed to sync goal deletion: \(error.localizedDescription)")
        }
    }

    // MARK: - Stats Sync

    /// Sync stats immediately (after minutes earned, etc.)
    // MARK: - Local Data Management

    /// Clears all local data from SwiftData
    func clearLocalData(modelContext: ModelContext) {
        do {
            // Delete all goals (cascades to completions)
            try modelContext.delete(model: Goal.self)
            
            // Delete all stats
            try modelContext.delete(model: UserStats.self)
            
            // Delete all proof items
            try modelContext.delete(model: ProofItem.self)
            
            // Delete all completion records (should be handled by cascade but just in case)
            try modelContext.delete(model: CompletionRecord.self)
            
            try modelContext.save()
            
            // Reset last sync date
            lastSyncDate = nil
            UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.lastSyncDate)
            
            Log.network.info("Local data cleared successfully")
        } catch {
            Log.network.error("Failed to clear local data: \(error.localizedDescription)")
        }
    }
}
