import SwiftUI

struct DiagnosticView: View {
    @Environment(QuestionBankStore.self) private var bank
    @Environment(MarkingStore.self) private var marking
    @Environment(StatsStore.self) private var stats
    @Environment(\.modelContext) private var context
    @Bindable var profile: UserProfile
    var onComplete: () -> Void

    @State private var current: Question?
    @State private var capturedImage: Data?
    @State private var showingCamera = false
    @State private var index = 0
    @State private var isMarking = false

    var body: some View {
        VStack(spacing: Theme.padLarge) {
            Text("Quick diagnostic").font(.mathTitle)
            Text("Answer 5 quick questions so we can target your weaknesses.")
                .font(.caption).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            ProgressView(value: Double(index), total: 5).tint(Theme.accent)

            if let q = current {
                GlassCard {
                    AsyncImage(url: q.questionImageURL) { phase in
                        switch phase {
                        case .success(let img): img.resizable().scaledToFit()
                        case .failure: Image(systemName: "exclamationmark.triangle")
                        default: ProgressView()
                        }
                    }
                    .frame(maxHeight: 280)
                }
                if isMarking {
                    ProgressView("Marking…")
                } else if let img = capturedImage, let ui = UIImage(data: img) {
                    Image(uiImage: ui).resizable().scaledToFit().frame(maxHeight: 160)
                    Button("Submit") { Task { await submit(image: img) } }
                        .buttonStyle(.borderedProminent)
                } else {
                    Button { showingCamera = true } label: {
                        GlassCard { Label("Take photo", systemImage: "camera.fill").frame(maxWidth: .infinity, minHeight: 60) }
                    }.buttonStyle(.plain)
                }
            } else {
                ProgressView().task { await loadNext() }
            }

            Spacer()
            Button("Skip diagnostic", action: onComplete).font(.caption)
        }
        .padding()
        .sheet(isPresented: $showingCamera) {
            CameraView { data in capturedImage = data; showingCamera = false }
        }
    }

    private func loadNext() async {
        guard index < 5 else { onComplete(); return }
        capturedImage = nil
        let q = try? await bank.nextQuestion(
            level: profile.level, board: profile.board, tier: profile.tier,
            stats: stats.weaknessRanking(limit: 200), recentAttempts: [], lastSubtopics: []
        )
        current = q
    }

    private func submit(image: Data) async {
        guard let q = current else { return }
        isMarking = true
        defer { isMarking = false }
        await marking.mark(question: q, studentImage: image)
        if case .result(let r) = marking.state {
            let attempt = QuestionAttempt(
                questionId: q.id, imageData: image,
                marksAwarded: r.totalAwarded, totalMarks: r.totalPossible,
                criterionResults: r.criteria, skillsCorrect: r.skillsCorrect,
                skillsIncorrect: r.skillsIncorrect, improvementTip: r.improvementTip,
                secondsSpent: 0, markingMode: .ai
            )
            context.insert(attempt); try? context.save()
            stats.apply(attempt: attempt, totalMarks: r.totalPossible)
        }
        index += 1
        await loadNext()
    }
}
