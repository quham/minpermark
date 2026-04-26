import Foundation

struct MarkingResult: Codable, Hashable {
    let totalAwarded: Int
    let totalPossible: Int
    let criteria: [CriterionResult]
    let skillsCorrect: [String]
    let skillsIncorrect: [String]
    let improvementTip: String
}
