import Foundation
import SwiftData

@Model
final class MinutesLedger {
    @Attribute(.unique) var entryId: UUID = UUID()
    var date: Date = Date()
    var deltaMinutes: Int = 0
    var sourceRaw: String = LedgerSource.earned.rawValue

    init(deltaMinutes: Int, source: LedgerSource, date: Date = .now) {
        self.deltaMinutes = deltaMinutes
        self.sourceRaw = source.rawValue
        self.date = date
    }

    var source: LedgerSource {
        get { LedgerSource(rawValue: sourceRaw) ?? .earned }
        set { sourceRaw = newValue.rawValue }
    }
}
