import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(QuestionBankStore.self) private var bank
    @Environment(SessionStore.self) private var session
    @Environment(MarkingStore.self) private var marking
    @Environment(MinutesStore.self) private var minutes
    @Environment(StatsStore.self) private var stats
    @Environment(\.modelContext) private var modelContext
    @Bindable var profile: UserProfile

    @State private var showingResult = false
    @State private var lastEarnedMinutes: Int = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.padLarge) {
                HStack {
                    Spacer()
                    MinutesBalancePill(minutes: minutes.balance)
                }

                if let q = session.question {
                    GlassCard {
                        AsyncImage(url: q.questionImageURL) { phase in
                            switch phase {
                            case .success(let img): img.resizable().scaledToFit()
                            case .failure: Image(systemName: "exclamationmark.triangle")
                            default: ProgressView()
                            }
                        }
                        .frame(maxHeight: 320)
                    }
                } else {
                    GlassCard { Text("Loading next question…").frame(maxWidth: .infinity) }
                        .task { await loadNext() }
                }

                NavigationLink {
                    SubmitAnswerView { data in
                        Task { await submit(data: data) }
                        showingResult = true
                    }
                } label: { Text("Submit answer") }
                    .buttonStyle(.borderedProminent)
                    .disabled(session.question == nil)
            }
            .padding()
        }
        .navigationDestination(isPresented: $showingResult) {
            switch marking.state {
            case .result(let r):
                ResultView(result: r, earnedMinutes: lastEarnedMinutes) {
                    Task { await loadNext() }
                    showingResult = false
                }
            case .loading:
                ProgressView("Marking…")
            case .selfMarkPrompt(let reason):
                VStack(spacing: Theme.pad) {
                    Text("Marking failed").font(.mathTitle)
                    Text(reason).font(.mathBody).multilineTextAlignment(.center)
                    Button("Back") { showingResult = false }
                }
                .padding()
            case .idle:
                EmptyView()
            }
        }
    }

    private func loadNext() async {
        let next = try? await bank.nextQuestion(
            level: profile.level, board: profile.board, tier: profile.tier,
            stats: stats.weaknessRanking(limit: 200), recentAttempts: [], lastSubtopics: []
        )
        if let next { session.load(question: next) }
    }

    private func submit(data: Data) async {
        guard let q = session.question else { return }
        session.attachWorking(image: data)
        session.markSubmitted()
        await marking.mark(question: q, studentImage: data)
        if case .result(let r) = marking.state {
            let attempt = QuestionAttempt(
                questionId: q.id, imageData: data,
                marksAwarded: r.totalAwarded, totalMarks: r.totalPossible,
                criterionResults: r.criteria, skillsCorrect: r.skillsCorrect,
                skillsIncorrect: r.skillsIncorrect, improvementTip: r.improvementTip,
                secondsSpent: session.secondsSpent, markingMode: .ai
            )
            modelContext.insert(attempt)
            try? modelContext.save()
            stats.apply(attempt: attempt, totalMarks: r.totalPossible)
            minutes.earn(minutes: r.totalAwarded)
            lastEarnedMinutes = r.totalAwarded
            profile.freeQuestionUsed = true
            try? modelContext.save()
            session.markCompleted()
        }
    }
}
