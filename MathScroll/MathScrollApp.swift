import SwiftUI
import SwiftData

@main
struct MathScrollApp: App {
    let container: ModelContainer
    let appState = AppState()
    let bank: QuestionBankStore
    let session = SessionStore()
    let marking: MarkingStore
    let minutes: MinutesStore
    let stats: StatsStore
    let paywall: PaywallStore

    init() {
        do {
            container = try ModelContainer(
                for: UserProfile.self, QuestionAttempt.self, SkillStat.self, MinutesLedger.self
            )
        } catch { fatalError("ModelContainer: \(error)") }

        let supabase = SupabaseManager.shared.client
        let bankSvc = QuestionBankService(transport: SupabaseBankTransport(client: supabase))
        bank = QuestionBankStore(service: bankSvc, recommender: QuestionRecommender(rng: SystemRandomNumberGenerator()))
        marking = MarkingStore(service: MarkingService(transport: EdgeFunctionMarkingTransport(client: supabase)))
        let context = ModelContext(container)
        stats = StatsStore(context: context)
        minutes = MinutesStore(context: context, dailyCapMinutes: 120)
        paywall = PaywallStore(entitlements: EntitlementsService())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(bank)
                .environment(session)
                .environment(marking)
                .environment(minutes)
                .environment(stats)
                .environment(paywall)
        }
        .modelContainer(container)
    }
}
