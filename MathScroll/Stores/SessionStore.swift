import Foundation

@MainActor
@Observable
final class SessionStore {
    enum Phase: String { case idle, loaded, photographed, submitted, completed }

    private(set) var question: Question?
    private(set) var workingImage: Data?
    private(set) var phase: Phase = .idle
    private(set) var startedAt: Date?

    func load(question: Question) {
        self.question = question
        self.workingImage = nil
        self.phase = .loaded
        self.startedAt = .now
    }

    func attachWorking(image: Data) {
        self.workingImage = image
        self.phase = .photographed
    }

    func markSubmitted() { phase = .submitted }
    func markCompleted() { phase = .completed }

    var secondsSpent: Int {
        guard let startedAt else { return 0 }
        return Int(Date.now.timeIntervalSince(startedAt))
    }
}
