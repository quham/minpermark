import SwiftUI

struct WeeklyDigestView: View {
    @Environment(StatsStore.self) private var stats
    private let service = WeeklyDigestService()

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.padLarge) {
                Text("Top 3 to focus on this week").font(.mathTitle)
                ForEach(service.topWeak(stats: stats.weaknessRanking(limit: 50), limit: 3), id: \.compositeKey) { s in
                    GlassCard {
                        VStack(alignment: .leading) {
                            Text(s.tag.replacingOccurrences(of: "_", with: " ").capitalized).font(.mathBody.weight(.semibold))
                            Text("\(Int(s.recencyWeightedPct))% recent accuracy").font(.caption).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }.padding()
        }
        .navigationTitle("Weekly digest")
    }
}
