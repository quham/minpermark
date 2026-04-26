import Foundation
import SwiftData

// MARK: - Goal Model

/// Represents a user's goal with associated micro-habit and tracking configuration
@Model
final class Goal {

    // MARK: - Properties

    var id: UUID
    var title: String
    var microHabit: String
    var triggerType: TriggerType
    var triggerValue: String
    var proofMethods: [ProofMethod]
    var importance: Int
    var why: String?
    var createdAt: Date
    var isArchived: Bool
    var dailyMinutesReward: Int
    var lastCompletedAt: Date?

    // MARK: - Relationships

    @Relationship(deleteRule: .cascade, inverse: \CompletionRecord.goal)
    var completions: [CompletionRecord]?

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        title: String,
        microHabit: String = "",
        triggerType: TriggerType = .time,
        triggerValue: String = "",
        proofMethods: [ProofMethod] = [],
        importance: Int = Constants.Defaults.importanceDefault,
        why: String? = nil,
        createdAt: Date = Date(),
        isArchived: Bool = false,
        dailyMinutesReward: Int = Constants.Defaults.minutesPerGoal,
        lastCompletedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.microHabit = microHabit
        self.triggerType = triggerType
        self.triggerValue = triggerValue
        self.proofMethods = proofMethods
        self.importance = importance
        self.why = why
        self.createdAt = createdAt
        self.isArchived = isArchived
        self.dailyMinutesReward = dailyMinutesReward
        self.lastCompletedAt = lastCompletedAt
    }

    // MARK: - Computed Properties

    var isCompletedToday: Bool {
        guard let lastCompleted = lastCompletedAt else { return false }
        return Calendar.current.isDateInToday(lastCompleted)
    }

    var triggerDisplayText: String {
        switch triggerType {
        case .time:
            return "At \(triggerValue)"
        case .after:
            return "After \(triggerValue)"
        case .location:
            return "When I get to \(triggerValue)"
        }
    }

    var latestCompletionToday: CompletionRecord? {
        completions?
            .filter { Calendar.current.isDateInToday($0.completedAt) }
            .max(by: { $0.completedAt < $1.completedAt })
    }

    var todaysCompletionStatus: VerificationStatus? {
        latestCompletionToday?.verificationStatus
    }
}

// MARK: - Trigger Type

/// Defines when a habit should be triggered
enum TriggerType: String, Codable, CaseIterable {
    case time = "time"
    case after = "after"
    case location = "location"

    // MARK: - Display Properties

    var displayTitle: String {
        switch self {
        case .time: return "At a specific time"
        case .after: return "After I..."
        case .location: return "When I get to..."
        }
    }

    var placeholder: String {
        switch self {
        case .time: return "Select time"
        case .after: return "e.g., wake up, eat breakfast"
        case .location: return "e.g., the gym, work, home"
        }
    }
}

// MARK: - Proof Method

/// Methods available for proving habit completion
enum ProofMethod: String, Codable, CaseIterable, Identifiable {
    case camera = "camera"
    case screenshot = "screenshot"
    case reflection = "reflection"
    case friendVouch = "friendVouch"

    var id: String { rawValue }

    // MARK: - Display Properties

    var displayTitle: String {
        switch self {
        case .camera: return "Camera check-in"
        case .screenshot: return "Upload screenshot"
        case .reflection: return "Short reflection"
        case .friendVouch: return "Friend vouch"
        }
    }

    var icon: String {
        switch self {
        case .camera: return "camera.fill"
        case .screenshot: return "photo.fill"
        case .reflection: return "pencil.line"
        case .friendVouch: return "person.2.fill"
        }
    }

    var description: String {
        switch self {
        case .camera: return "Do it on Camera"
        case .screenshot: return "From an app related to your goal"
        case .reflection: return "Write a brief note"
        case .friendVouch: return "Get a friend to confirm"
        }
    }
}
