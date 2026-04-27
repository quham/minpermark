import XCTest
@testable import MathScroll

@MainActor
final class SessionStoreTests: XCTestCase {
    func testLifecycle() {
        let s = SessionStore()
        XCTAssertEqual(s.phase, .idle)
        s.load(question: .fixture(id: "q", level: .gcse, board: .edexcel))
        XCTAssertEqual(s.phase, .loaded)
        s.attachWorking(image: Data([0x01]))
        XCTAssertEqual(s.phase, .photographed)
        s.markSubmitted()
        XCTAssertEqual(s.phase, .submitted)
        s.markCompleted()
        XCTAssertEqual(s.phase, .completed)
    }
}
