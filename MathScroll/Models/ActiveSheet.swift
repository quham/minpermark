import Foundation

// MARK: - Active Sheet

/// Represents the currently active sheet/modal in the app
enum ActiveSheet: Identifiable {
    case proofCapture(Goal)
    case settings
    case addGoal
    case editGoal(Goal)

    var id: String {
        switch self {
        case .proofCapture(let goal): return "proof-\(goal.id)"
        case .settings: return "settings"
        case .addGoal: return "addGoal"
        case .editGoal(let goal): return "edit-\(goal.id)"
        }
    }
}
