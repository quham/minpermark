import Foundation

struct WeeklyDigestService {
    func topWeak(stats: [SkillStat], limit: Int) -> [SkillStat] {
        Array(stats.sorted { $0.recencyWeightedPct < $1.recencyWeightedPct }.prefix(limit))
    }
}
