import Foundation

@MainActor
@Observable
final class MarkingStore {
    enum State {
        case idle
        case loading
        case result(MarkingResult)
        case selfMarkPrompt(reason: String)
    }

    private let service: MarkingService
    private(set) var state: State = .idle

    init(service: MarkingService) { self.service = service }

    func mark(question: Question, studentImage: Data) async {
        state = .loading
        do {
            let r = try await service.mark(question: question, studentImage: studentImage)
            state = .result(r)
        } catch {
            state = .selfMarkPrompt(reason: "AI marking failed. Self-mark this attempt?")
        }
    }

    /// Build a synthetic MarkingResult from the student's full/zero per-criterion choice.
    func acceptSelfMark(_ awards: [CriterionResult], totalPossible: Int) {
        state = .result(MarkingResult(
            totalAwarded: awards.map(\.awarded).reduce(0, +),
            totalPossible: totalPossible,
            criteria: awards,
            skillsCorrect: [],
            skillsIncorrect: [],
            improvementTip: ""
        ))
    }
}
