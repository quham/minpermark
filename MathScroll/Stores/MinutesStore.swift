import Foundation
import SwiftData

@MainActor
@Observable
final class MinutesStore {
    private let context: ModelContext
    var dailyCapMinutes: Int

    init(context: ModelContext, dailyCapMinutes: Int) {
        self.context = context
        self.dailyCapMinutes = dailyCapMinutes
    }

    var balance: Int {
        let entries = (try? context.fetch(FetchDescriptor<MinutesLedger>())) ?? []
        return entries.map(\.deltaMinutes).reduce(0, +)
    }

    func earn(minutes: Int) {
        let allowed = min(minutes, remainingTodayCap())
        guard allowed > 0 else { return }
        context.insert(MinutesLedger(deltaMinutes: allowed, source: .earned))
        if allowed < minutes {
            context.insert(MinutesLedger(deltaMinutes: 0, source: .dailyCapAdjustment))
        }
        try? context.save()
    }

    func spend(minutes: Int) {
        guard balance >= minutes, minutes > 0 else { return }
        context.insert(MinutesLedger(deltaMinutes: -minutes, source: .spent))
        try? context.save()
    }

    private func remainingTodayCap() -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: .now)
        let earnedRaw = LedgerSource.earned.rawValue
        let descriptor = FetchDescriptor<MinutesLedger>(
            predicate: #Predicate<MinutesLedger> { $0.date >= startOfDay && $0.sourceRaw == earnedRaw }
        )
        let earnedToday = ((try? context.fetch(descriptor)) ?? []).map(\.deltaMinutes).reduce(0, +)
        return max(0, dailyCapMinutes - earnedToday)
    }
}
