import XCTest
import SwiftData
@testable import MathScroll

@MainActor
final class MinutesStoreTests: XCTestCase {
    func testEarnAddsToBalance() throws {
        let store = try makeStore()
        store.earn(minutes: 5)
        XCTAssertEqual(store.balance, 5)
    }

    func testDailyCapClampsEarnings() throws {
        let store = try makeStore(dailyCap: 10)
        store.earn(minutes: 7)
        store.earn(minutes: 7)
        XCTAssertEqual(store.balance, 10)
    }

    private func makeStore(dailyCap: Int = 120) throws -> MinutesStore {
        let container = try ModelContainer(
            for: MinutesLedger.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return MinutesStore(context: ModelContext(container), dailyCapMinutes: dailyCap)
    }
}
