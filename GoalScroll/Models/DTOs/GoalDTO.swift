import Foundation

// MARK: - Goal DTO

/// Data Transfer Object for syncing Goal with Supabase
struct GoalDTO: Codable {
    let id: UUID
    let userId: UUID
    let title: String
    let microHabit: String
    let triggerType: String
    let triggerValue: String
    let proofMethods: [String]
    let importance: Int
    let why: String?
    let isArchived: Bool
    let dailyMinutesReward: Int
    let lastCompletedAt: Date?
    let createdAt: Date
    var updatedAt: Date?
    var deletedAt: Date?
    var localId: UUID?
    var syncVersion: Int

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case microHabit = "micro_habit"
        case triggerType = "trigger_type"
        case triggerValue = "trigger_value"
        case proofMethods = "proof_methods"
        case importance
        case why
        case isArchived = "is_archived"
        case dailyMinutesReward = "daily_minutes_reward"
        case lastCompletedAt = "last_completed_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case localId = "local_id"
        case syncVersion = "sync_version"
    }

    // MARK: - Conversion from SwiftData Model

    init(from goal: Goal, userId: UUID) {
        self.id = UUID() // Server will assign new ID
        self.userId = userId
        self.title = goal.title
        self.microHabit = goal.microHabit
        self.triggerType = goal.triggerType.rawValue
        self.triggerValue = goal.triggerValue
        self.proofMethods = goal.proofMethods.map { $0.rawValue }
        self.importance = goal.importance
        self.why = goal.why
        self.isArchived = goal.isArchived
        self.dailyMinutesReward = goal.dailyMinutesReward
        self.lastCompletedAt = goal.lastCompletedAt
        self.createdAt = goal.createdAt
        self.updatedAt = nil
        self.deletedAt = nil
        self.localId = goal.id // Store local SwiftData ID for deduplication
        self.syncVersion = 1
    }

    // MARK: - Conversion to SwiftData Model

    func toGoal() -> Goal {
        Goal(
            id: localId ?? id,
            title: title,
            microHabit: microHabit,
            triggerType: TriggerType(rawValue: triggerType) ?? .time,
            triggerValue: triggerValue,
            proofMethods: proofMethods.compactMap { ProofMethod(rawValue: $0) },
            importance: importance,
            why: why,
            createdAt: createdAt,
            isArchived: isArchived,
            dailyMinutesReward: dailyMinutesReward,
            lastCompletedAt: lastCompletedAt
        )
    }

    // MARK: - Update Local Goal from DTO

    func updateGoal(_ goal: Goal) {
        goal.title = title
        goal.microHabit = microHabit
        goal.triggerType = TriggerType(rawValue: triggerType) ?? .time
        goal.triggerValue = triggerValue
        goal.proofMethods = proofMethods.compactMap { ProofMethod(rawValue: $0) }
        goal.importance = importance
        goal.why = why
        goal.isArchived = isArchived
        goal.dailyMinutesReward = dailyMinutesReward
        goal.lastCompletedAt = lastCompletedAt
    }
}

// MARK: - Goal DTO for Upsert (without server-generated fields)

struct GoalUpsertDTO: Encodable {
    let userId: UUID
    let title: String
    let microHabit: String
    let triggerType: String
    let triggerValue: String
    let proofMethods: [String]
    let importance: Int
    let why: String?
    let isArchived: Bool
    let dailyMinutesReward: Int
    let lastCompletedAt: Date?
    let createdAt: Date
    let localId: UUID

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case title
        case microHabit = "micro_habit"
        case triggerType = "trigger_type"
        case triggerValue = "trigger_value"
        case proofMethods = "proof_methods"
        case importance
        case why
        case isArchived = "is_archived"
        case dailyMinutesReward = "daily_minutes_reward"
        case lastCompletedAt = "last_completed_at"
        case createdAt = "created_at"
        case localId = "local_id"
    }

    init(from goal: Goal, userId: UUID) {
        self.userId = userId
        self.title = goal.title
        self.microHabit = goal.microHabit
        self.triggerType = goal.triggerType.rawValue
        self.triggerValue = goal.triggerValue
        self.proofMethods = goal.proofMethods.map { $0.rawValue }
        self.importance = goal.importance
        self.why = goal.why
        self.isArchived = goal.isArchived
        self.dailyMinutesReward = goal.dailyMinutesReward
        self.lastCompletedAt = goal.lastCompletedAt
        self.createdAt = goal.createdAt
        self.localId = goal.id
    }
}
