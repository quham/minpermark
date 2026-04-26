import Foundation
import SwiftData

struct CriterionResult: Codable, Hashable {
    var criterionId: String
    var awarded: Int
    var max: Int
    var rationale: String
}

@Model
final class QuestionAttempt {
    @Attribute(.unique) var id: UUID = UUID()
    var questionId: String = ""
    var submittedAt: Date = Date()
    var imageData: Data = Data()
    var marksAwarded: Int = 0
    var totalMarks: Int = 0
    private var criterionResultsJSON: Data = Data()
    var skillsCorrect: [String] = []
    var skillsIncorrect: [String] = []
    var improvementTip: String = ""
    var secondsSpent: Int = 0
    var markingModeRaw: String = MarkingMode.ai.rawValue

    init(
        questionId: String,
        imageData: Data,
        marksAwarded: Int,
        totalMarks: Int,
        criterionResults: [CriterionResult],
        skillsCorrect: [String],
        skillsIncorrect: [String],
        improvementTip: String,
        secondsSpent: Int,
        markingMode: MarkingMode
    ) {
        self.questionId = questionId
        self.imageData = imageData
        self.marksAwarded = marksAwarded
        self.totalMarks = totalMarks
        self.skillsCorrect = skillsCorrect
        self.skillsIncorrect = skillsIncorrect
        self.improvementTip = improvementTip
        self.secondsSpent = secondsSpent
        self.markingModeRaw = markingMode.rawValue
        self.criterionResultsJSON = (try? JSONEncoder().encode(criterionResults)) ?? Data()
    }

    var criterionResults: [CriterionResult] {
        get { (try? JSONDecoder().decode([CriterionResult].self, from: criterionResultsJSON)) ?? [] }
        set { criterionResultsJSON = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    var markingMode: MarkingMode {
        get { MarkingMode(rawValue: markingModeRaw) ?? .ai }
        set { markingModeRaw = newValue.rawValue }
    }
}
