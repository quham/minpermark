import XCTest
@testable import MathScroll

@MainActor
final class MarkingStoreTests: XCTestCase {
    func testSuccessTransitionsToResult() async {
        let svc = MarkingService(transport: StubMarkingTransport(rawResponses: [Data("""
            {"totalAwarded":2,"totalPossible":2,"criteria":[],"skillsCorrect":[],"skillsIncorrect":[],"improvementTip":""}
        """.utf8)]))
        let store = MarkingStore(service: svc)
        await store.mark(question: .fixture(id: "q", level: .gcse, board: .edexcel),
                         studentImage: Data([0x01]))
        if case .result(let r) = store.state { XCTAssertEqual(r.totalAwarded, 2) }
        else { XCTFail("expected .result, got \(store.state)") }
    }

    func testFailureTransitionsToSelfMarkPrompt() async {
        let svc = MarkingService(transport: StubMarkingTransport(rawResponses: [Data("a".utf8), Data("b".utf8)]))
        let store = MarkingStore(service: svc)
        await store.mark(question: .fixture(id: "q", level: .gcse, board: .edexcel),
                         studentImage: Data([0x01]))
        if case .selfMarkPrompt = store.state {} else { XCTFail("expected .selfMarkPrompt") }
    }
}
