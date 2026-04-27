import SwiftUI

struct ResultView: View {
    let result: MarkingResult
    let earnedMinutes: Int
    var onNext: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.padLarge) {
                GlassCard {
                    VStack(spacing: 4) {
                        Text("\(result.totalAwarded)/\(result.totalPossible)").font(.mathDisplay)
                        Text("marks awarded").font(.caption).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }

                MinutesBalancePill(minutes: earnedMinutes)

                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Per criterion").font(.mathBody.weight(.semibold))
                        ForEach(result.criteria, id: \.criterionId) { c in
                            HStack(alignment: .top) {
                                Text(c.criterionId).bold().frame(width: 40, alignment: .leading)
                                Text("\(c.awarded)/\(c.max)").frame(width: 50, alignment: .leading)
                                Text(c.rationale).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                if !result.improvementTip.isEmpty {
                    GlassCard {
                        Label(result.improvementTip, systemImage: "lightbulb.fill")
                            .font(.mathBody)
                    }
                }

                Button("Next question", action: onNext)
                    .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}
