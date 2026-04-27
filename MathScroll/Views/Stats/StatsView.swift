import SwiftUI
import Charts

struct StatsView: View {
    @Environment(StatsStore.self) private var stats

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.padLarge) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Top weaknesses").font(.mathBody.weight(.semibold))
                        ForEach(stats.weaknessRanking(limit: 5), id: \.compositeKey) { s in
                            HStack {
                                Text(s.tag.replacingOccurrences(of: "_", with: " ").capitalized)
                                Spacer()
                                Text("\(Int(s.recencyWeightedPct))%").foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }.padding()
        }
        .navigationTitle("Stats")
    }
}
