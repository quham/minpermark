import XCTest
@testable import MathScroll

final class MarkingServiceTests: XCTestCase {
    func testParsesValidResponse() async throws {
        let stub = StubMarkingTransport(rawResponses: [Data("""
        {"totalAwarded":3,"totalPossible":4,"criteria":[
          {"criterionId":"M1","awarded":1,"max":1,"rationale":"ok"}
        ],"skillsCorrect":["a"],"skillsIncorrect":["b"],"improvementTip":"x"}
        """.utf8)])
        let svc = MarkingService(transport: stub)
        let result = try await svc.mark(question: .fixture(id: "q", level: .gcse, board: .edexcel),
                                        studentImage: Data([0x01]))
        XCTAssertEqual(result.totalAwarded, 3)
    }

    func testRetriesOnceOnInvalidJSONThenSucceeds() async throws {
        let stub = StubMarkingTransport(rawResponses: [
            Data("not json".utf8),
            Data("""
            {"totalAwarded":2,"totalPossible":2,"criteria":[],"skillsCorrect":[],"skillsIncorrect":[],"improvementTip":""}
            """.utf8)
        ])
        let svc = MarkingService(transport: stub)
        let r = try await svc.mark(question: .fixture(id: "q", level: .gcse, board: .edexcel),
                                   studentImage: Data([0x01]))
        XCTAssertEqual(r.totalAwarded, 2)
        XCTAssertEqual(stub.callCount, 2)
    }

    func testThrowsAfterTwoInvalidResponses() async {
        let stub = StubMarkingTransport(rawResponses: [Data("a".utf8), Data("b".utf8)])
        let svc = MarkingService(transport: stub)
        do {
            _ = try await svc.mark(question: .fixture(id: "q", level: .gcse, board: .edexcel),
                                   studentImage: Data([0x01]))
            XCTFail("should throw")
        } catch is MarkingError {}
        catch { XCTFail("wrong error type") }
    }
}

final class StubMarkingTransport: MarkingTransport, @unchecked Sendable {
    var rawResponses: [Data]
    var callCount = 0
    init(rawResponses: [Data]) { self.rawResponses = rawResponses }
    func invoke(question: Question, studentImage: Data, strict: Bool) async throws -> Data {
        defer { callCount += 1 }
        return rawResponses[min(callCount, rawResponses.count - 1)]
    }
}
