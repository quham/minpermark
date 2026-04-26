import XCTest
import SwiftData
@testable import MathScroll

final class MinutesLedgerTests: XCTestCase {
    func testEntryStoresDeltaAndSource() {
        let e = MinutesLedger(deltaMinutes: 4, source: .earned)
        XCTAssertEqual(e.deltaMinutes, 4)
        XCTAssertEqual(e.source, .earned)
        XCTAssertNotNil(e.entryId)
    }
}
